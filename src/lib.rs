use pulldown_cmark::{escape::escape_href, Alignment, Event, Options, Parser, Tag};
use std::{
    ffi::{CStr, CString},
    os::raw::c_char,
};

#[no_mangle]
pub extern "C" fn parse_markdown(ptr: *const c_char) -> *mut c_char {
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let parser = Parser::new_ext(cstr.to_str().unwrap(), Options::all());
    let buf = parse_json(parser);
    let cstr = unsafe { CString::from_vec_unchecked(buf.into()) };
    cstr.into_raw()
}
#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        CString::from_raw(ptr);
    }
}
fn parse_json<'a>(mut parser: Parser<'a>) -> String {
    let mut buf = String::new();
    buf.push('[');
    while let Some(event) = parser.next() {
        match event {
            Event::Start(tag) => match tag {
                Tag::Paragraph => buf.push_str(r#",{"t":"p","c":["#),
                Tag::Heading(lvl) => buf.push_str(format!(r#",{{"t":"h{}","c":["#, lvl).as_str()),
                Tag::BlockQuote => buf.push_str(r#",{"t":"blockquote","c":["#),
                Tag::CodeBlock(lang) => match lang {
                    pulldown_cmark::CodeBlockKind::Indented => {
                        buf.push_str(r#",{"t":"pre","indent":true,"c":["#)
                    }
                    pulldown_cmark::CodeBlockKind::Fenced(lang) => buf.push_str(
                        format!(r#",{{"t":"pre","indent":false,"lang":"{}","c":["#, lang).as_str(),
                    ),
                },
                Tag::List(index) => match index {
                    Some(num) => {
                        buf.push_str(format!(r#",{{"t":"ol","start":{},"c":["#, num).as_str());
                    }
                    None => {
                        buf.push_str(r#",{"t":"ul","c":["#);
                    }
                },
                Tag::Item => buf.push_str(r#",{"t":"li","c":["#),
                Tag::Table(aligns) => {
                    buf.push_str(r#",{"t":"table","align":["#);
                    for e in &aligns {
                        match e {
                            Alignment::None => buf.push_str(",0"),
                            Alignment::Left => buf.push_str(",1"),
                            Alignment::Center => buf.push_str(",2"),
                            Alignment::Right => buf.push_str(",3"),
                        }
                    }
                    buf.push_str(r#"],"c":["#);
                }
                Tag::TableHead => buf.push_str(r#",{"t":"th","c":["#),
                Tag::TableRow => buf.push_str(r#",{"t":"tr","c":["#),
                Tag::TableCell => buf.push_str(r#",{"t":"td","c":["#),
                Tag::Emphasis => buf.push_str(r#",{"t":"em","c":["#),
                Tag::Strong => buf.push_str(r#",{"t":"strong","c":["#),
                Tag::Strikethrough => buf.push_str(r#",{"t":"s","c":["#),
                Tag::Link(_, href, title) => {
                    let mut escaped = String::new();
                    escape_href(&mut escaped, &href).unwrap();
                    buf.push_str(
                        format!(
                            r#",{{"t":"a","href":"{}","title":"{}"}}"#,
                            escaped,
                            title.replace("\\", "\\\\")
                        )
                        .as_str(),
                    );
                }
                Tag::Image(_, href, title) => {
                    let mut escaped = String::new();
                    escape_href(&mut escaped, &href).unwrap();
                    buf.push_str(
                        format!(
                            r#",{{"t":"img","href":"{}","title":"{}"}}"#,
                            escaped,
                            title.replace("\\", "\\\\")
                        )
                        .as_str(),
                    );
                }
                // TODO: Implement FootnoteDefinition
                // pulldown_cmark::Tag::FootnoteDefinition(_) => {}
                _ => {}
            },
            Event::End(tag) => match tag {
                Tag::Link(..) | Tag::Image(..) => {}
                _ => buf.push_str(r#"]}"#),
            },
            Event::Text(text) => buf.push_str(format!(r#","{}""#, text.escape_debug()).as_str()),
            Event::Code(text) => {
                buf.push_str(
                    format!(r#",{{"t":"pre","value":"{}"}}"#, text.replace("\\", "\\\\")).as_str(),
                );
            }
            Event::SoftBreak | Event::HardBreak => buf.push_str(",\"\\n\""),
            Event::Rule => buf.push_str(r#",{"t":"hr"}"#),
            Event::TaskListMarker(checked) => {
                buf.push_str(format!(r#",{{"t":"checkbox","value":"{}"}}"#, checked).as_str())
            }
            // pulldown_cmark::Event::FootnoteReference(_) => {}
            _ => {}
        }
    }
    buf.push(']');
    buf.replace("[,", "[")
}
