use criterion::{criterion_group, criterion_main, Criterion};
use flutter_playground::impls::*;
use pulldown_cmark::{Options, Parser};

static SOURCE: &'static str = include_str!("../assets/markdown_reference.md");

fn get_parser() -> Parser<'static> {
    Parser::new_ext(SOURCE, Options::all())
}

fn benchmark_parsers(bench: &mut Criterion) {
    let mut parsers = bench.benchmark_group("parsers");
    parsers.bench_function("parse_json", |c| {
        c.iter_batched(
            get_parser,
            |parser| json::parse_json(parser, Some(SOURCE.len())),
            criterion::BatchSize::SmallInput,
        );
    });
    parsers.bench_function("parse_json (no size_hint)", |c| {
        c.iter_batched(
            get_parser,
            |parser| json::parse_json(parser, None),
            criterion::BatchSize::SmallInput,
        );
    });
    parsers.bench_function("parse_elements", |c| {
        c.iter_batched(
            get_parser,
            |parser| ast::parse_elements(parser),
            criterion::BatchSize::SmallInput,
        );
    });
}

criterion_group!(benches, benchmark_parsers);
criterion_main!(benches);
