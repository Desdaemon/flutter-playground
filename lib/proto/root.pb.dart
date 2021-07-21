///
//  Generated code. Do not modify.
//  source: root.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'root.pbenum.dart';

export 'root.pbenum.dart';

enum Element_Value {
  tag, 
  text, 
  notSet
}

class Element extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Element_Value> _Element_ValueByTag = {
    1 : Element_Value.tag,
    2 : Element_Value.text,
    0 : Element_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Element', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'flutter_playground'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Tag>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tag', subBuilder: Tag.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'text')
    ..hasRequiredFields = false
  ;

  Element._() : super();
  factory Element({
    Tag? tag,
    $core.String? text,
  }) {
    final _result = create();
    if (tag != null) {
      _result.tag = tag;
    }
    if (text != null) {
      _result.text = text;
    }
    return _result;
  }
  factory Element.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Element.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Element clone() => Element()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Element copyWith(void Function(Element) updates) => super.copyWith((message) => updates(message as Element)) as Element; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Element create() => Element._();
  Element createEmptyInstance() => create();
  static $pb.PbList<Element> createRepeated() => $pb.PbList<Element>();
  @$core.pragma('dart2js:noInline')
  static Element getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Element>(create);
  static Element? _defaultInstance;

  Element_Value whichValue() => _Element_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Tag get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag(Tag v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);
  @$pb.TagNumber(1)
  Tag ensureTag() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);
}

class Tag extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Tag', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'flutter_playground'), createEmptyInstance: create)
    ..e<Tag_Tags>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tag', $pb.PbFieldType.OE, defaultOrMaker: Tag_Tags.Paragraph, valueOf: Tag_Tags.valueOf, enumValues: Tag_Tags.values)
    ..pc<Element>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'children', $pb.PbFieldType.PM, subBuilder: Element.create)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'style')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'href')
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'checked')
    ..hasRequiredFields = false
  ;

  Tag._() : super();
  factory Tag({
    Tag_Tags? tag,
    $core.Iterable<Element>? children,
    $core.String? style,
    $core.String? href,
    $core.bool? checked,
  }) {
    final _result = create();
    if (tag != null) {
      _result.tag = tag;
    }
    if (children != null) {
      _result.children.addAll(children);
    }
    if (style != null) {
      _result.style = style;
    }
    if (href != null) {
      _result.href = href;
    }
    if (checked != null) {
      _result.checked = checked;
    }
    return _result;
  }
  factory Tag.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Tag.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Tag clone() => Tag()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Tag copyWith(void Function(Tag) updates) => super.copyWith((message) => updates(message as Tag)) as Tag; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Tag create() => Tag._();
  Tag createEmptyInstance() => create();
  static $pb.PbList<Tag> createRepeated() => $pb.PbList<Tag>();
  @$core.pragma('dart2js:noInline')
  static Tag getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Tag>(create);
  static Tag? _defaultInstance;

  @$pb.TagNumber(1)
  Tag_Tags get tag => $_getN(0);
  @$pb.TagNumber(1)
  set tag(Tag_Tags v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTag() => $_has(0);
  @$pb.TagNumber(1)
  void clearTag() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Element> get children => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get style => $_getSZ(2);
  @$pb.TagNumber(3)
  set style($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStyle() => $_has(2);
  @$pb.TagNumber(3)
  void clearStyle() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get href => $_getSZ(3);
  @$pb.TagNumber(4)
  set href($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHref() => $_has(3);
  @$pb.TagNumber(4)
  void clearHref() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get checked => $_getBF(4);
  @$pb.TagNumber(5)
  set checked($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasChecked() => $_has(4);
  @$pb.TagNumber(5)
  void clearChecked() => clearField(5);
}

