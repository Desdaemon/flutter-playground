use crate::impls::{
    ast::{AstParser, Element, HtmlTag, Tags, TextAlign},
    json::JsonParser,
};
use crate::slice::free_slice;
use crate::slice::rust_slice_to_c;
use crate::slice::Slice;
use pulldown_cmark::{html::push_html, Options, Parser};
use std::ffi::{c_void, NulError};
use std::ptr::null_mut;
use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
};

use super::types::CTag;

/// Dart does not support enum strcts (20210721),
/// so we have to create an adapter struct like this.
#[repr(C)]
pub struct CElement(CTag, *mut c_void);
impl Drop for CElement {
    fn drop(&mut self) {
        match self.0 {
            CTag::Text => free_string(self.1.cast::<c_char>()),
            CTag::Tag => unsafe {
                Box::from_raw(self.1.cast::<CHtmlTag>());
            },
        }
    }
}

/// FFI-compatible adapter for [HtmlTag].
#[repr(C)]
pub struct CHtmlTag {
    /// HTML tag.
    pub t: Tags,
    /// List of children.
    pub c: *mut Slice<CElement>,
    /// empty or 'text-align: left|center|right'
    pub style: TextAlign,
    /// image src
    pub src: *mut c_char,
    /// anchor href
    pub href: *mut c_char,
    /// for checkbox only
    pub checked: bool,
    /// for math blocks
    pub display: bool,
}
impl Drop for CHtmlTag {
    /// TODO: This is very error prone and will break when
    /// fields are added. The compiler will check for most
    /// of these, but it cannot check if you have added new fields
    /// that might need customized destructors.
    fn drop(&mut self) {
        free_elements(self.c);
        free_string(self.src);
        free_string(self.href);
    }
}

fn mut_ptr_from<'a>(string: Option<String>) -> Result<*mut c_char, NulError> {
    let ret = match string {
        Some(string) => CString::new(string)?.into_raw(),
        None => null_mut(),
    };
    Ok(ret)
}

impl From<HtmlTag> for CHtmlTag {
    /// This function comprises of a lot of forgets.
    /// For each call to [rust_slice_to_c] or [mut_ptr_from],
    /// we need to add a respective destructor of [free_slice] and [free_string],
    /// which has been done for CHtmlTag.
    fn from(item: HtmlTag) -> Self {
        CHtmlTag {
            t: item.t,
            c: match item.c {
                Some(item) => {
                    rust_slice_to_c(item.into_iter().map(From::from).collect::<Box<[_]>>())
                }
                None => null_mut(),
            },
            style: item.style.unwrap_or(TextAlign::None),
            href: mut_ptr_from(item.href).unwrap(),
            // typ: mut_ptr_from(item.typ.map(String::from)).unwrap(),
            // checked: mut_ptr_from(item.checked.map(String::from)).unwrap(),
            checked: item.checked.unwrap_or(false),
            src: mut_ptr_from(item.src).unwrap(),
            display: item.display.unwrap_or(false),
        }
    }
}

/// Parses a Markdown string and returns a JSON string of the AST.
/// The returned pointer should be freed by [free_string].
#[no_mangle]
pub extern "C" fn parse_markdown(ptr: *const c_char) -> *mut c_char {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let string = cstr.to_str().unwrap();
    let parser = Parser::new_ext(string, Options::all());
    let buf = JsonParser::parse(parser, Some(string.len()));
    match CString::new(buf) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => null_mut(),
    }
}

/// Parses a Markdown string and returns HTML.
/// The returned pointer should be freed by [free_string].
#[no_mangle]
pub extern "C" fn parse_markdown_xml(ptr: *const c_char) -> *mut c_char {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let parser = Parser::new_ext(cstr.to_str().unwrap(), Options::all());
    let mut buf = String::new();
    push_html(&mut buf, parser);
    match CString::new(buf) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => null_mut(),
    }
}

/// Parses a Markdown string and returns a list of [CElement]s.
/// The returned pointer should be freed by [free_elements].
#[no_mangle]
pub extern "C" fn parse_markdown_ast(ptr: *const c_char) -> *mut Slice<CElement> {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let parser = Parser::new_ext(cstr.to_str().unwrap(), Options::all());
    let ast = AstParser::parse(parser);
    let slice = ast.into_iter().map(From::from).collect::<Box<_>>();
    rust_slice_to_c(slice)
}

/// Frees the [Slice] created by [parse_markdown_ast].
#[no_mangle]
pub extern "C" fn free_elements(ptr: *mut Slice<CElement>) {
    free_slice(ptr);
}

/// Similar to [parse_markdown], but uses the algorithm from [parse_markdown_ast].
/// The returned pointer should be freed by [free_string].
#[no_mangle]
pub extern "C" fn parse_markdown_ast_json(ptr: *const c_char) -> *mut c_char {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let parser = Parser::new_ext(cstr.to_str().unwrap(), Options::all());
    let ast = AstParser::parse(parser);
    let json = serde_json::to_string(&ast).unwrap();
    match CString::new(json) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => null_mut(),
    }
}

/// Common string destructor intended to be called by the Dart side.
#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        CString::from_raw(ptr);
    }
}

/// Exposes the [CElement] as a text node if it is one, or null otherwise.
#[no_mangle]
pub extern "C" fn as_text(el: *mut CElement) -> *mut c_char {
    unsafe {
        match el.as_mut() {
            Some(CElement(CTag::Text, text)) => (*text) as *mut c_char,
            _ => null_mut(),
        }
    }
}

/// Exposes the [CElement] as a [CHtmlTag] if it is one, or null otherwise.
#[no_mangle]
pub extern "C" fn as_tag(el: *mut CElement) -> *mut CHtmlTag {
    unsafe {
        match el.as_mut() {
            Some(CElement(CTag::Tag, tag)) => (*tag) as *mut CHtmlTag,
            _ => null_mut(),
        }
    }
}

impl From<Element> for CElement {
    fn from(item: Element) -> Self {
        match item {
            Element::Text(text) => CElement(
                CTag::Text,
                CString::new(text).unwrap().into_raw().cast::<c_void>(),
            ),
            Element::Tag(tag) => CElement(
                CTag::Tag,
                Box::into_raw(Box::new(CHtmlTag::from(tag))).cast::<c_void>(),
            ),
        }
    }
}
