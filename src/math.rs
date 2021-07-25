use nom::{bytes::complete::*, character::complete::*, combinator::opt, sequence::pair, IResult};
#[derive(Debug, PartialEq)]
pub enum MathBlock<'a> {
    Text(&'a str),
    Display(&'a str),
}

impl<'a> MathBlock<'a> {
    /// Parses a math block that is wrapped as `$..$` or `$$..$$`.
    ///
    /// Equivalent to the regular expression `\$(\$?)([^$]*)\$\1`, or
    /// `(\$\$([^$]*)\$\$|\$([^$]*)\$)` if backreferences are not available.
    pub fn parse(input: &str) -> IResult<&str, MathBlock> {
        let (input, (_, second)) = pair(char('$'), opt(char('$')))(input)?; // \$\$?
        let (input, text) = take_while(|c| c != '$')(input)?; // ([^$]*)
        if let Some(_) = second {
            // in the case of an empty text block "$$", this will be parsed as an unmatched display block.
            let (input, matched) = opt(tag("$$"))(input)?; // (\$\$)?
            match matched {
                Some(_) => Ok((input, MathBlock::Display(text))),
                _ => Ok((text, MathBlock::Text(""))),
            }
        } else {
            let (input, _) = char('$')(input)?;
            Ok((input, MathBlock::Text(text)))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn text_mode() {
        match MathBlock::parse("$1 + 1 = 2$") {
            Ok((_, MathBlock::Text(text))) => {
                println!("text_mode: {}", text);
            }
            _ => panic!(),
        }
    }
    #[test]
    fn display_mode() {
        match MathBlock::parse(r#"$$\int_0^1 f(x) = F(x)\Big|_0^1$$"#) {
            Ok((_, MathBlock::Display(text))) => {
                println!("display_mode: {}", text);
            }
            _ => panic!(),
        }
    }
    #[test]
    fn empty_text() {
        match MathBlock::parse("$$") {
            Ok((_, MathBlock::Text(_))) => {}
            _ => panic!(),
        }
    }
    #[test]
    fn empty_display() {
        match MathBlock::parse("$$$$") {
            Ok((_, MathBlock::Display(_))) => {}
            _ => panic!(),
        }
    }
}
