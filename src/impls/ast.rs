use pulldown_cmark::escape::escape_href;
use pulldown_cmark::Alignment;
use pulldown_cmark::CowStr;
use pulldown_cmark::{Event, Parser, Tag};
use serde::Serialize;
use std::borrow::{BorrowMut, Cow};

#[derive(Clone, Serialize)]
#[serde(untagged)]
pub enum Element {
    Text(String),
    Tag(HtmlTag),
}
impl Element {
    fn done(self) -> Element {
        match self {
            Element::Tag(tag) => Element::Tag(tag.done()),
            other => other,
        }
    }
}

#[derive(Clone, Serialize)]
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
    #[serde(rename = "type", skip_serializing_if = "Option::is_none")]
    pub typ: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checked: Option<&'static str>,
}
impl HtmlTag {
    fn new(tag: Tags) -> Self {
        HtmlTag {
            t: tag,
            c: None,
            style: None,
            src: None,
            href: None,
            typ: None,
            checked: None,
            done: false,
        }
    }
    fn done(self) -> Self {
        if self.done {
            self
        } else {
            HtmlTag { done: true, ..self }
        }
    }
}

#[derive(Clone, Copy, Serialize, PartialEq)]
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
    #[serde(rename = "thead")]
    TableHead,
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
    #[serde(rename = "hr'")]
    Ruler,
}

impl From<Tags> for Element {
    fn from(tag: Tags) -> Self {
        Element::Tag(HtmlTag::new(tag))
    }
}

#[derive(Clone, Serialize)]
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

type Cowstr<'a> = Cow<'a, str>;
trait Fold<T> {
    fn fold(&mut self, item: T);
    fn fold_str(&mut self, item: Cowstr);
}

impl Fold<Element> for Option<Element> {
    fn fold(&mut self, item: Element) {
        if let Some(Element::Tag(tag)) = self.borrow_mut() {
            tag.c.get_or_insert(vec![]).push(item);
        } else {
            self.get_or_insert(item);
        }
    }
    fn fold_str(&mut self, item: Cowstr) {
        if let Some(Element::Text(string)) = self.borrow_mut() {
            *string = format!("{}{}", string, item);
        } else {
            self.fold(Element::Text(item.to_string()));
        }
    }
}

pub fn parse_elements(parser: Parser) -> Vec<Element> {
    let mut ret = vec![];
    let mut in_header = false;
    let mut alignment: Vec<Alignment> = vec![];
    let mut cell_index = 0;
    let mut el: Option<Element> = None;
    let mut buf: Option<String> = None;
    for event in parser {
        match event {
            Event::Text(text) if !text.is_empty() => {
                let escaped = text.escape_debug().to_string();
                if buf.is_none() {
                    buf = Some(escaped);
                } else {
                    if let Some(buf) = buf.borrow_mut() {
                        buf.push_str(&escaped);
                    }
                }
            }
            other => {
                if buf.is_some() {
                    el.fold_str(Cow::from(buf.take().unwrap()));
                }
                match other {
                    Event::Start(tag) => {
                        match tag {
                            Tag::Paragraph => el.fold(Element::from(Tags::Paragraph)),
                            Tag::Heading(lvl) => el.fold(Element::from(match lvl {
                                1 => Tags::H1,
                                2 => Tags::H2,
                                3 => Tags::H3,
                                4 => Tags::H4,
                                5 => Tags::H5,
                                6 => Tags::H6,
                                _ => unreachable!(),
                            })),
                            Tag::BlockQuote => el.fold(Element::from(Tags::Paragraph)),
                            Tag::CodeBlock(_kind) => el.fold(Element::from(Tags::Pre)),
                            Tag::List(index) => el.fold(match index {
                                None => Element::from(Tags::UnorderedList),
                                _ => Element::from(Tags::OrderedList),
                            }),
                            Tag::Item => el.fold(Element::from(Tags::ListItem)),
                            Tag::Table(aligns) => {
                                alignment = aligns;
                                el.fold(Element::from(Tags::Table));
                            }
                            Tag::TableHead => {
                                in_header = true;
                                el.fold(Element::from(Tags::TableHead));
                            }
                            Tag::TableRow => el.fold(Element::from(Tags::TableRow)),
                            Tag::TableCell => {
                                let style = match alignment[cell_index] {
                                    Alignment::None => TextAlign::None,
                                    Alignment::Left => TextAlign::Left,
                                    Alignment::Center => TextAlign::Center,
                                    Alignment::Right => TextAlign::Right,
                                };
                                let mut tag = HtmlTag::new(if in_header {
                                    Tags::TableHeaderCell
                                } else {
                                    Tags::TableCell
                                });
                                tag.style = Some(style);
                                el.fold(Element::Tag(tag));
                            }
                            Tag::Emphasis => el.fold(Element::from(Tags::Emphasis)),
                            Tag::Strong => el.fold(Element::from(Tags::Strong)),
                            Tag::Strikethrough => el.fold(Element::from(Tags::Strikethrough)),
                            Tag::Link(link_t, mut href, display) => {
                                let mut escaped = String::new();
                                let mut display = String::from(display.as_ref());
                                match link_t {
                                    pulldown_cmark::LinkType::Autolink => {
                                        if display.is_empty() {
                                            display.push_str(href.as_ref());
                                        }
                                    }
                                    pulldown_cmark::LinkType::Email => {
                                        href = CowStr::from(format!("mailto:{}", href));
                                    }
                                    _ => {}
                                }
                                escape_href(&mut escaped, &href).unwrap();
                                let mut tag = HtmlTag::new(Tags::Anchor);
                                tag.href = Some(escaped);
                                if !display.is_empty() {
                                    tag.c = Some(vec![Element::Text(display.to_string())]);
                                } else {
                                    tag.c = Some(vec![]);
                                }
                                el.fold(Element::Tag(tag));
                            }
                            Tag::Image(_, href, _) => {
                                let mut escaped = String::new();
                                escape_href(&mut escaped, &href).unwrap();
                                let mut tag = HtmlTag::new(Tags::Image);
                                tag.c = Some(vec![]);
                                tag.src = Some(escaped);
                                el.fold(Element::Tag(tag));
                            }
                            // TODO: Implement FootnoteDefinition
                            //Tag::FootnoteDefinition(_) => {}
                            _ => {}
                        };
                    }
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
                        match (el.take(), ret.last_mut()) {
                            (None, Some(Element::Tag(top))) => top.done = true,
                            (Some(Element::Text(el)), Some(Element::Text(top))) => {
                                top.push_str(&el)
                            }
                            (Some(Element::Tag(el)), Some(Element::Tag(top))) if !top.done => {
                                top.c.get_or_insert(vec![]).push(Element::Tag(el.done()))
                            }
                            (Some(el), _) => ret.push(el.done()),
                            _ => {}
                        }
                    }
                    Event::Code(text) => {
                        let mut tag = HtmlTag::new(Tags::Code);
                        tag.c = Some(vec![Element::Text(text.replace("\\", "\\\\"))]);
                        el.fold(Element::Tag(tag));
                    }
                    Event::SoftBreak | Event::HardBreak => el.fold_str(Cow::from("\n")),
                    Event::Rule => el.fold(Element::from(Tags::HardBreak)),
                    Event::TaskListMarker(checked) => {
                        let mut tag = HtmlTag::new(Tags::Ruler);
                        tag.typ = Some("checkbox");
                        tag.checked = Some(if checked { "true" } else { "false" });
                        el.fold(Element::Tag(tag));
                    }
                    //Event::FootnoteReference(_) => {}
                    _ => {}
                };
            }
        }
    }
    ret
}
