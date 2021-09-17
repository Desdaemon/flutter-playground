use pulldown_cmark::escape::escape_href;
use pulldown_cmark::Alignment;
use pulldown_cmark::{Event, Tag};
use serde::Serialize;
use std::borrow::BorrowMut;

use crate::math::MathBlock;

/// Serialized into JS as a `string` or [HtmlTag].
/// No bindings are generated for this struct, since Dart
/// does not have a concept of union types and therefore
/// can only consume this type as a `dynamic`.
#[derive(Clone, Serialize, Debug)]
#[serde(untagged)]
pub enum Element {
    Text(String),
    Tag(HtmlTag),
}
impl Element {
    fn done(self) -> Self {
        match self {
            Element::Text(_) => self,
            Element::Tag(tag) => Element::Tag(tag.done()),
        }
    }
}

#[derive(Clone, Serialize, Debug)]
pub struct HtmlTag {
    #[serde(skip)]
    done: bool,
    pub t: Tags,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub c: Option<Vec<Element>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub style: Option<TextAlign>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub src: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub href: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checked: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display: Option<bool>,
}
impl HtmlTag {
    fn new(tag: Tags) -> Self {
        HtmlTag {
            t: tag,
            done: false,
            c: Some(vec![]),
            style: None,
            src: None,
            href: None,
            // typ: None,
            checked: None,
            display: None,
        }
    }
    fn done(mut self) -> Self {
        self.done = true;
        self
    }
}

#[derive(Clone, Copy, Serialize, PartialEq, Debug)]
#[serde(rename_all = "lowercase")]
#[repr(C)]
pub enum Tags {
    #[serde(rename = "p")]
    Paragraph,
    H1,
    H2,
    H3,
    H4,
    H5,
    H6,
    Blockquote,
    Pre,
    #[serde(rename = "ol")]
    OrderedList,
    #[serde(rename = "ul")]
    UnorderedList,
    #[serde(rename = "li")]
    ListItem,
    Table,
    #[serde(rename = "tr")]
    TableRow,
    #[serde(rename = "td")]
    TableCell,
    #[serde(rename = "th")]
    TableHeaderCell,
    #[serde(rename = "em")]
    Emphasis,
    Strong,
    #[serde(rename = "s")]
    Strikethrough,
    #[serde(rename = "a")]
    Anchor,
    #[serde(rename = "img")]
    Image,
    Code,
    #[serde(rename = "br")]
    HardBreak,
    #[serde(rename = "hr")]
    Ruler,
    Checkbox,
    Math,
}

impl From<Tags> for Element {
    fn from(tag: Tags) -> Self {
        Element::Tag(HtmlTag::new(tag))
    }
}

#[derive(Clone, Copy, Serialize, Debug)]
#[repr(C)]
pub enum TextAlign {
    #[serde(rename = "")]
    None,
    #[serde(rename = "text-align: left")]
    Left,
    #[serde(rename = "text-align: center")]
    Center,
    #[serde(rename = "text-align: right")]
    Right,
}

trait Append<T> {
    /// Returns ownership of the item if it cannot append.
    fn append(&mut self, item: T) -> Option<T>;
}

impl Append<Element> for Element {
    fn append(&mut self, item: Element) -> Option<Element> {
        match (self, item) {
            (Element::Text(text), Element::Text(item)) => {
                text.push_str(&item);
                None
            }
            (Element::Tag(tag), item) if !tag.done => {
                tag.c.get_or_insert(vec![]).push(item);
                None
            }
            // Siblings so we cannot merge them directly.
            (_, tag) => Some(tag),
        }
    }
}

impl Append<Element> for Option<Element> {
    fn append(&mut self, item: Element) -> Option<Element> {
        match (self, item) {
            (Some(el), item) => el.append(item),
            (s, item) => match item {
                Element::Text(_) => {
                    let mut parent = HtmlTag::new(Tags::Paragraph);
                    parent.c = Some(vec![item]);
                    *s = Some(Element::Tag(parent));
                    None
                }
                Element::Tag(_) => {
                    s.get_or_insert(item);
                    None
                }
            },
        }
    }
}

pub struct AstParser;
impl AstParser {
    pub fn parse(parser: pulldown_cmark::Parser) -> Vec<Element> {
        let mut ret = vec![];
        let mut el: Option<Element> = None;
        let mut aligns = vec![];
        let mut column = 0;
        let mut in_header = false;
        for event in parser {
            match event {
                Event::Start(tag) => {
                    // We always start a tag with an empty element.
                    // When a tag ends, we merge with the top element on the stack.
                    if let Some(el) = el.take() {
                        ret.push(el);
                    }
                    match tag {
                        Tag::Paragraph => el = Some(Element::from(Tags::Paragraph)),
                        Tag::Heading(lvl) => {
                            el = Some(Element::from(match lvl {
                                1 => Tags::H1,
                                2 => Tags::H2,
                                3 => Tags::H3,
                                4 => Tags::H4,
                                5 => Tags::H5,
                                6 => Tags::H6,
                                _ => unreachable!(),
                            }))
                        }
                        Tag::BlockQuote => el = Some(Element::from(Tags::Blockquote)),
                        Tag::CodeBlock(_) => el = Some(Element::from(Tags::Pre)),
                        Tag::List(Some(_)) => el = Some(Element::from(Tags::OrderedList)),
                        Tag::List(None) => el = Some(Element::from(Tags::UnorderedList)),
                        Tag::Item => el = Some(Element::from(Tags::ListItem)),
                        Tag::Table(alignments) => {
                            aligns = alignments;
                            el = Some(Element::from(Tags::Table));
                        }
                        Tag::TableHead => {
                            in_header = true;
                            el = Some(Element::from(Tags::TableRow));
                        }
                        Tag::TableRow => el = Some(Element::from(Tags::TableRow)),
                        Tag::TableCell => {
                            let style = match aligns[column] {
                                Alignment::None => TextAlign::None,
                                Alignment::Left => TextAlign::Left,
                                Alignment::Center => TextAlign::Center,
                                Alignment::Right => TextAlign::Right,
                            };
                            assert!(!aligns.is_empty());
                            column = (column + 1) % aligns.len();
                            let mut tag = HtmlTag::new(if in_header {
                                Tags::TableHeaderCell
                            } else {
                                Tags::TableCell
                            });
                            tag.style = Some(style);
                            el = Some(Element::Tag(tag));
                        }
                        Tag::Emphasis => el = Some(Element::from(Tags::Emphasis)),
                        Tag::Strong => el = Some(Element::from(Tags::Strong)),
                        Tag::Strikethrough => el = Some(Element::from(Tags::Strikethrough)),
                        Tag::Link(link_t, href, display) => {
                            match link_t {
                                _ => {}
                            }
                            let mut escaped = String::new();
                            escape_href(&mut escaped, &href).unwrap();
                            let mut tag = HtmlTag::new(Tags::Anchor);
                            tag.c = Some(vec![Element::Text(display.to_string())]);
                            tag.href = Some(escaped);
                            el = Some(Element::Tag(tag));
                        }
                        Tag::Image(link_t, href, display) => {
                            match link_t {
                                _ => {}
                            }
                            let mut escaped = String::new();
                            escape_href(&mut escaped, &href).unwrap();
                            let mut tag = HtmlTag::new(Tags::Image);
                            tag.src = Some(escaped);
                            tag.c = Some(vec![Element::Text(display.to_string())]);
                            el = Some(Element::Tag(tag));
                        }
                        // Tag::FootnoteDefinition(def) => todo!()
                        _ => {}
                    };
                }
                Event::End(tag) => {
                    match tag {
                        Tag::FootnoteDefinition(_) => continue,
                        Tag::TableHead => {
                            in_header = false;
                        }
                        _ => {}
                    }
                    match el.take() {
                        Some(el) => match ret.last_mut() {
                            None => ret.push(el.done()),
                            Some(top) => {
                                if let Some(sibling) = top.append(el.done()) {
                                    ret.push(sibling);
                                }
                            }
                        },
                        None => {
                            let top = ret.pop();
                            if let (Some(parent), Some(top)) = (ret.last_mut(), top) {
                                if let Some(sibling) = parent.append(top.done()) {
                                    ret.push(sibling);
                                }
                            }
                        }
                    }
                }
                Event::Text(text) => {
                    let text = match MathBlock::parse(&text) {
                        Ok((_, blk)) => {
                            let mut tag = HtmlTag::new(Tags::Math);
                            match blk {
                                MathBlock::Display(text) => {
                                    tag.display = Some(true);
                                    tag.c = Some(vec![Element::Text(text.to_string())])
                                }
                                MathBlock::Text(text) => {
                                    tag.display = Some(false);
                                    tag.c = Some(vec![Element::Text(text.to_string())])
                                }
                            }
                            Element::Tag(tag)
                        }
                        _ => Element::Text(text.to_string()),
                    };
                    if let Some(el) = el.borrow_mut() {
                        el.append(text);
                    } else if let Some(top) = ret.last_mut() {
                        top.append(text);
                    }
                }
                Event::Code(text) => {
                    let mut tag = HtmlTag::new(Tags::Code);
                    tag.c = Some(vec![Element::Text(text.to_string())]);
                    el.append(Element::Tag(tag));
                }
                Event::SoftBreak | Event::HardBreak => {
                    el.append(Element::Text(String::from("\n")));
                }
                Event::Rule => {
                    el.append(Element::from(Tags::Ruler));
                }
                Event::TaskListMarker(checked) => {
                    let mut tag = HtmlTag::new(Tags::Checkbox);
                    tag.checked = Some(checked);
                    el.append(Element::Tag(tag));
                }
                // Event::Html(_) => todo!(),
                // Event::FootnoteReference(_) => todo!(),
                _ => {}
            }
        }
        ret
    }
}
