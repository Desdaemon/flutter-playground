use pulldown_cmark::{Options, Parser};
use wasm_bindgen::prelude::*;

use crate::impls::{ast::AstParser, json::JsonParser};

#[cfg(feature = "wee_alloc")]
#[global_allocator]
static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

#[wasm_bindgen(typescript_custom_section)]
const TYPESCRIPT_DEF: &'static str = r#"
export type IElement = string | IHtmlTag;

export interface IHtmlTag {
    t: string
    /** A list of strings and [IHtmlTag] */
    c?: IElement[]
    style?: string
    src?: string
    href?: string
    checked?: boolean
    display?: boolean
}

export function wasm_parse_markdown_ast(input: string): IElement[];
"#;

/// Parses Markdown input and returns a JSON string of the AST.
#[wasm_bindgen]
pub fn wasm_parse_markdown(input: &str) -> String {
    let parser = Parser::new_ext(input, Options::all());
    JsonParser::parse(parser, Some(input.len()))
}

/// Parses Markdown input and returns the AST as an object.
#[wasm_bindgen(skip_typescript)]
pub fn wasm_parse_markdown_ast(input: &str) -> Result<JsValue, JsValue> {
    let parser = Parser::new_ext(input, Options::all());
    let ast = AstParser::parse(parser);
    Ok(serde_wasm_bindgen::to_value(&ast)?)
}
