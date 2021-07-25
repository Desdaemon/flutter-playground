/* Generated with cbindgen:0.19.0 */

#include <stdint.h>
#include <stdbool.h>

/**
 * Tag for [CElement].
 */
typedef enum CTag {
  /**
   * [Element::Text]
   */
  Text,
  /**
   * [Element::Tag]
   */
  Tag,
} CTag;

typedef enum Tags {
  Paragraph,
  H1,
  H2,
  H3,
  H4,
  H5,
  H6,
  Blockquote,
  Pre,
  OrderedList,
  UnorderedList,
  ListItem,
  Table,
  TableRow,
  TableCell,
  TableHeaderCell,
  Emphasis,
  Strong,
  Strikethrough,
  Anchor,
  Image,
  Code,
  HardBreak,
  Ruler,
  Checkbox,
  Math,
} Tags;

typedef enum TextAlign {
  None,
  Left,
  Center,
  Right,
} TextAlign;

/**
 * Dart does not support enum strcts (20210721),
 * so we have to create an adapter struct like this.
 */
typedef struct CElement {
  enum CTag _0;
  void *_1;
} CElement;

/**
 * Wrapper over Rust's slice type.
 *
 * The main functionality comes from [rust_slice_to_c], a function
 * that converts Rust slices into Slice pointers.
 *
 * The accompanying `impl_slice_destructor` macro, or the [free_slice]
 * function can be used to define destructors for a particular type.
 *
 * It is highly unsafe to mutate this slice before it is returned to the Rust side.
 */
typedef struct Slice_CElement {
  uintptr_t length;
  struct CElement *ptr;
} Slice_CElement;

/**
 * FFI-compatible adapter for [HtmlTag].
 */
typedef struct CHtmlTag {
  /**
   * HTML tag.
   */
  enum Tags t;
  /**
   * List of children.
   */
  struct Slice_CElement *c;
  /**
   * empty or 'text-align: left|center|right'
   */
  enum TextAlign style;
  /**
   * image src
   */
  char *src;
  /**
   * anchor href
   */
  char *href;
  /**
   * for checkbox only
   */
  bool checked;
  /**
   * for math blocks
   */
  bool display;
} CHtmlTag;

/**
 * Parses a Markdown string and returns a JSON string of the AST.
 * The returned pointer should be freed by [free_string].
 */
char *parse_markdown(const char *ptr);

/**
 * Parses a Markdown string and returns HTML.
 * The returned pointer should be freed by [free_string].
 */
char *parse_markdown_xml(const char *ptr);

/**
 * Parses a Markdown string and returns a list of [CElement]s.
 * The returned pointer should be freed by [free_elements].
 */
struct Slice_CElement *parse_markdown_ast(const char *ptr);

/**
 * Frees the [Slice] created by [parse_markdown_ast].
 */
void free_elements(struct Slice_CElement *ptr);

/**
 * Similar to [parse_markdown], but uses the algorithm from [parse_markdown_ast].
 * The returned pointer should be freed by [free_string].
 */
char *parse_markdown_ast_json(const char *ptr);

/**
 * Common string destructor intended to be called by the Dart side.
 */
void free_string(char *ptr);

/**
 * Exposes the [CElement] as a text node if it is one, or null otherwise.
 */
char *as_text(struct CElement *el);

/**
 * Exposes the [CElement] as a [CHtmlTag] if it is one, or null otherwise.
 */
struct CHtmlTag *as_tag(struct CElement *el);
