use tree_sitter::{InputEdit, Parser, Point, Tree};
use tree_sitter_markdown::language;

pub struct TreeSitterParser(Parser);
impl TreeSitterParser {
    pub fn new() -> Self {
        let mut parser = Parser::new();
        parser.set_language(language()).unwrap();
        TreeSitterParser(parser)
    }
    pub fn parse(
        &mut self,
        input: &str,
        old_tree: Option<Tree>,
        delta: Option<Delta>,
    ) -> Option<Tree> {
        self.0.parse(
            input,
            match delta {
                Some(delta) => old_tree.map(|mut e| {
                    e.edit(&From::from(delta));
                    e
                }),
                _ => old_tree,
            }
            .as_ref(),
        )
    }
}

#[cfg(test)]
mod tests {
    use crate::impls::tree_sitter::TreeSitterParser;

    #[test]
    fn it_works() {
        static SOURCE: &'static str = include_str!("../../assets/markdown_reference.md");
        let mut parser = TreeSitterParser::new();
        let tree = parser.parse(SOURCE, None, None).unwrap();
        println!("{}", tree.root_node().to_sexp());
    }
}

/// ## Deriving the delta for an input
///
/// Given the diff of this source:
/// ```diff
/// -fn test() {}
/// +fn test(a: u32) {}
///          8______
/// ```
///
/// The delta is thus comprised as:
/// - `start_byte`: 8
/// - `old_end_byte`: 8
/// - `new_end_byte`: 14
/// - `start_row`: 0
/// - `start_col`: 8
/// - `old_end_row`: 0
/// - `old_end_col`: 8
/// - `new_end_row`: 0
/// - `new_end_col`: 14
#[repr(C)]
pub struct Delta {
    start_byte: usize,
    old_end_byte: usize,
    new_end_byte: usize,
    start_row: usize,
    start_col: usize,
    old_end_row: usize,
    old_end_col: usize,
    new_end_row: usize,
    new_end_col: usize,
}

impl From<Delta> for InputEdit {
    fn from(d: Delta) -> Self {
        InputEdit {
            start_byte: d.start_byte,
            old_end_byte: d.old_end_byte,
            new_end_byte: d.new_end_byte,
            start_position: Point::new(d.start_row, d.start_col),
            old_end_position: Point::new(d.old_end_row, d.old_end_col),
            new_end_position: Point::new(d.new_end_row, d.new_end_row),
        }
    }
}
