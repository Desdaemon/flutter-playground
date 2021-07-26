use flutter_playground::impls::{ast::AstParser, json::JsonParser};
use pulldown_cmark::{Options, Parser};

static SOURCE: &'static str = include_str!("../assets/markdown_reference.md");

/// Binary for profiling.
fn main() {
    let parser = Parser::new_ext(SOURCE, Options::all());
    let _ast = AstParser::parse(parser);
    let parser = Parser::new_ext(SOURCE, Options::all());
    let _json = JsonParser::parse(parser, Some(SOURCE.len()));
}
