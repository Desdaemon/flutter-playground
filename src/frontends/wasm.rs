use pulldown_cmark::{Options, Parser};
use wasm_bindgen::prelude::*;

use crate::impls::{ast::AstParser, json::JsonParser};

#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

#[wasm_bindgen]
pub fn wasm_parse_markdown(input: &str) -> String {
    let parser = Parser::new_ext(input, Options::all());
    JsonParser::parse(parser, Some(input.len()))
}

#[wasm_bindgen]
pub fn wasm_parse_markdown_ast(input: &str) -> Result<JsValue, JsValue> {
    let parser = Parser::new_ext(input, Options::all());
    let ast = AstParser::parse(parser);
    Ok(serde_wasm_bindgen::to_value(&ast)?)
}
