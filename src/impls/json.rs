use pulldown_cmark::escape::escape_href;
use pulldown_cmark::Alignment;
use pulldown_cmark::{Event, Parser, Tag};

pub fn parse_json(parser: Parser<'_>, size_hint: Option<usize>) -> String {
    let mut buf = match size_hint {
        None => String::new(),
        Some(size) => String::with_capacity(size),
    };
    buf.push('[');
    let mut in_header = false;
    let mut in_text = false;
    let mut alignment: Vec<Alignment> = vec![];
    let mut cell_index = 0;
    for event in parser {
        match event {
            Event::Text(text) if !text.is_empty() => {
                if !in_text {
                    buf.push_str(",\"");
                    in_text = true;
                }
                buf.push_str(text.escape_debug().to_string().as_str());
            }
            other => {
                if in_text {
                    buf.push('"');
                    in_text = false;
                }
                match other {
                    Event::Start(tag) => match tag {
                        Tag::Paragraph => buf.push_str(r#",{"t":"p","c":["#),
                        Tag::Heading(lvl) => {
                            buf.push_str(r#",{"t":"h"#);
                            buf.push_str(lvl.to_string().as_str());
                            buf.push_str(r#"","c":["#);
                        }
                        Tag::BlockQuote => buf.push_str(r#",{"t":"blockquote","c":["#),
                        Tag::CodeBlock(_) => {
                            buf.push_str(r#",{"t":"pre","c":["#);
                        }
                        Tag::List(index) => match index {
                            Some(_num) => buf.push_str(r#",{"t":"ol","c":["#),
                            None => buf.push_str(r#",{"t":"ul","c":["#),
                        },
                        Tag::Item => buf.push_str(r#",{"t":"li","c":["#),
                        Tag::Table(aligns) => {
                            alignment = aligns;
                            buf.push_str(r#",{"t":"table","c":["#);
                        }
                        Tag::TableHead => {
                            in_header = true;
                            buf.push_str(r#",{"t":"thead","c":["#);
                        }
                        Tag::TableRow => buf.push_str(r#",{"t":"tr","c":["#),
                        Tag::TableCell => {
                            let style = match alignment[cell_index] {
                                Alignment::None => "",
                                Alignment::Left => r#""style":"text-align: left","#,
                                Alignment::Center => r#""style":"text-align: center","#,
                                Alignment::Right => r#""style":"text-align: right","#,
                            };
                            if in_header {
                                buf.push_str(r#",{"t":"th","#);
                            } else {
                                buf.push_str(r#",{"t":"td","#);
                            }
                            buf.push_str(style);
                            buf.push_str(r#""c":["#);
                        }
                        Tag::Emphasis => buf.push_str(r#",{"t":"em","c":["#),
                        Tag::Strong => buf.push_str(r#",{"t":"strong","c":["#),
                        Tag::Strikethrough => buf.push_str(r#",{"t":"s","c":["#),
                        Tag::Link(link_t, href, display) => {
                            buf.push_str(r#",{"t":"a","href":""#);
                            let mut escaped = String::new();
                            escape_href(&mut escaped, &href).unwrap();
                            if let pulldown_cmark::LinkType::Email = link_t {
                                escaped = ["mailto:", &escaped].join("");
                            }
                            buf.push_str(&escaped);
                            buf.push_str(r#"","c":["#);
                            match link_t {
                                pulldown_cmark::LinkType::Autolink if display.is_empty() => {
                                    buf.push('"');
                                    buf.push_str(&href);
                                    buf.push('"');
                                }
                                _ => {}
                            }
                        }
                        Tag::Image(_, href, _) => {
                            let mut escaped = String::new();
                            escape_href(&mut escaped, &href).unwrap();
                            buf.push_str(r#",{"t":"img","src":""#);
                            buf.push_str(&escaped);
                            buf.push_str(r#"","c":["#);
                        }
                        // TODO: Implement FootnoteDefinition
                        //Tag::FootnoteDefinition(_) => {}
                        _ => {}
                    },
                    Event::End(tag) => {
                        match tag {
                            Tag::TableHead => {
                                in_header = false;
                            }
                            Tag::TableRow => {
                                cell_index = 0;
                            }
                            _ => {}
                        }
                        buf.push_str(r#"]}"#);
                    }
                    Event::Code(text) => {
                        buf.push_str(r#",{"t":"code","c":[""#);
                        buf.push_str(text.replace("\\", "\\\\").as_str());
                        buf.push_str("\"]}");
                    }
                    Event::SoftBreak | Event::HardBreak => buf.push_str(",\"\\n\""),
                    Event::Rule => buf.push_str(r#",{"t":"hr"}"#),
                    Event::TaskListMarker(checked) => {
                        buf.push_str(r#",{"t":"checkbox","type":"checkbox","checked":""#);
                        buf.push_str(if checked { "true" } else { "false" });
                        buf.push_str("\"}");
                    }
                    //Event::FootnoteReference(_) => {}
                    _ => {}
                };
            }
        }
    }
    buf.push(']');
    buf.replace("[,", "[")
}
