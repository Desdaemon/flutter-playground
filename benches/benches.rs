use criterion::{black_box, criterion_group, criterion_main, Criterion};
use flutter_playground::{
    impls::{ast::AstParser, json::JsonParser},
    math::MathBlock,
};
use pulldown_cmark::{Options, Parser};
use regex::Regex;
// use tree_sitter::Tree;

static SOURCE: &'static str = include_str!("../assets/markdown_reference.md");

fn get_parser() -> Parser<'static> {
    Parser::new_ext(SOURCE, Options::all())
}

// fn get_tree() -> (TreeSitterParser, Option<Tree>) {
//     let mut parser = TreeSitterParser::new();
//     let tree = parser.parse(SOURCE, None, None);
//     (parser, tree)
// }

fn benchmark_parsers(bench: &mut Criterion) {
    {
        let mut parsers = bench.benchmark_group("parsers");
        parsers.bench_function("parse_json", |c| {
            c.iter_batched(
                get_parser,
                |parser| JsonParser::parse(parser, Some(SOURCE.len())),
                criterion::BatchSize::SmallInput,
            );
        });
        parsers.bench_function("parse_json_no_size_hint", |c| {
            c.iter_batched(
                get_parser,
                |parser| JsonParser::parse(parser, None),
                criterion::BatchSize::SmallInput,
            );
        });
        parsers.bench_function("parse_elements", |c| {
            c.iter_batched(
                get_parser,
                |parser| AstParser::parse(parser),
                criterion::BatchSize::SmallInput,
            );
        });
    }
    // bench.bench_function("tree_parser", |c| {
    //     c.iter_batched(
    //         get_tree,
    //         |(mut parser, tree)| parser.parse(SOURCE, tree, None),
    //         criterion::BatchSize::SmallInput,
    //     )
    // });
}

/// The Regex implementation on Rust is limited due to being unable to use backreferences,
/// so there is room for improvement on other platforms.
fn benchmark_math(bench: &mut Criterion) {
    let mut math = bench.benchmark_group("math");
    let display_source = black_box(r#"$$\int_0^1 f(x)dx = F(x)\Big|_0^1$$"#);
    math.bench_function("nom", |c| {
        c.iter(|| {
            MathBlock::parse(display_source).unwrap();
        })
    });
    let pat = Regex::new(r#"(?:\$\$([^$]*)\$\$|\$([^$]*)\$|)"#).unwrap();
    math.bench_function("regex", |c| {
        c.iter(|| {
            if let Some(cap) = pat.captures(display_source) {
                let _is_display = cap.get(1).is_some();
                let _is_text = cap.get(2).is_some();
            }
        })
    });
}

criterion_group!(benches, benchmark_parsers, benchmark_math);
criterion_main!(benches);
