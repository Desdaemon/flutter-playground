///
//  Generated code. Do not modify.
//  source: root.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Tag_Tags extends $pb.ProtobufEnum {
  static const Tag_Tags Paragraph = Tag_Tags._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Paragraph');
  static const Tag_Tags H1 = Tag_Tags._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H1');
  static const Tag_Tags H2 = Tag_Tags._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H2');
  static const Tag_Tags H3 = Tag_Tags._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H3');
  static const Tag_Tags H4 = Tag_Tags._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H4');
  static const Tag_Tags H5 = Tag_Tags._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H5');
  static const Tag_Tags H6 = Tag_Tags._(6, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'H6');
  static const Tag_Tags Blockquote = Tag_Tags._(7, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Blockquote');
  static const Tag_Tags Pre = Tag_Tags._(8, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Pre');
  static const Tag_Tags OrderedList = Tag_Tags._(9, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'OrderedList');
  static const Tag_Tags UnorderedList = Tag_Tags._(10, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UnorderedList');
  static const Tag_Tags ListItem = Tag_Tags._(11, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ListItem');
  static const Tag_Tags Table = Tag_Tags._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Table');
  static const Tag_Tags TableHead = Tag_Tags._(13, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TableHead');
  static const Tag_Tags TableRow = Tag_Tags._(14, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TableRow');
  static const Tag_Tags TableCell = Tag_Tags._(15, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TableCell');
  static const Tag_Tags TableHeaderCell = Tag_Tags._(16, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'TableHeaderCell');
  static const Tag_Tags Emphasis = Tag_Tags._(17, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Emphasis');
  static const Tag_Tags Strong = Tag_Tags._(18, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Strong');
  static const Tag_Tags Strikethrough = Tag_Tags._(19, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Strikethrough');
  static const Tag_Tags Anchor = Tag_Tags._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Anchor');
  static const Tag_Tags Image = Tag_Tags._(21, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Image');
  static const Tag_Tags Code = Tag_Tags._(22, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Code');
  static const Tag_Tags HardBreak = Tag_Tags._(23, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'HardBreak');
  static const Tag_Tags Ruler = Tag_Tags._(24, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Ruler');
  static const Tag_Tags Checkbox = Tag_Tags._(25, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'Checkbox');

  static const $core.List<Tag_Tags> values = <Tag_Tags> [
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
    TableHead,
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
  ];

  static final $core.Map<$core.int, Tag_Tags> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Tag_Tags? valueOf($core.int value) => _byValue[value];

  const Tag_Tags._($core.int v, $core.String n) : super(v, n);
}

