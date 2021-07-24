use nom::{bytes::complete::*, character::complete::*, combinator::opt, sequence::pair, IResult};
#[derive(Debug, PartialEq)]
pub enum MathBlock<'a> {
    Text(&'a str),
    Display(&'a str),
}

impl<'a> MathBlock<'a> {
    pub fn parse(input: &'a str) -> IResult<&'a str, MathBlock<'a>> {
        let (input, (_, second)) = pair(char('$'), opt(char('$')))(input)?; // $$?
        let (input, text) = take_while(|c| c != '$')(input)?; // ([^$]*)
        if let Some(_) = second {
            let (input, _) = tag("$$")(input)?;
            Ok((input, MathBlock::Display(text)))
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
        let input = "$1 + 1 = 2$";
        match MathBlock::parse(input) {
            Ok((_, MathBlock::Text(text))) => {
                println!("text_mode: {}", text);
            }
            _ => panic!(),
        }
    }
    #[test]
    fn display_mode() {
        let input = r#"$$\int_0^1 f(x) = F(x)\Big|_0^1$$"#;
        match MathBlock::parse(input) {
            Ok((_, MathBlock::Display(text))) => {
                println!("display_mode: {}", text);
            }
            _ => panic!(),
        }
    }
}
