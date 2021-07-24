import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yata_flutter/bindings.dart';
import 'package:yata_flutter/ffi.dart';

/// A custom implementation of a [Map] and [md.Element] that is immutable and only
/// supports a specific number of keys.
class HtmlTag implements Map<String, String>, md.Element {
  final CHtmlTag inner;
  HtmlTag(this.inner);

  @override
  String? operator [](Object? key) {
    if (key is! String || !containsKey(key)) return null;
    switch (key) {
      case 'src':
        return inner.src.cast<Utf8>().toDartString();
      case 'href':
        return inner.href.cast<Utf8>().toDartString();
      case 'type':
        return 'checkbox';
      case 'checked':
        return inner.checked == 0 ? 'false' : 'true';
      case 'style':
        return style;
      case 'display':
        return inner.display == 0 ? 'false' : 'true';
    }
  }

  late final String? style = computeStyle();
  String? computeStyle() {
    switch (inner.style) {
      case TextAlign.Center:
        return 'text-align: center';
      case TextAlign.Right:
        return 'text-align: right';
      default:
        return 'text-align: left';
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    switch (key) {
      case 'src':
        return inner.src.address != nullptr.address;
      case 'href':
        return inner.href.address != nullptr.address;
      case 'type':
        return inner.t == Tags.Checkbox;
      case 'checked':
      case 'style':
      case 'display':
        return true;
      default:
        return false;
    }
  }

  @override
  late final Iterable<String> keys = ['src', 'href', 'type', 'checked', 'style', 'display'].where(containsKey);

  @override
  late final Iterable<String> values = keys.map((key) => this[key]!);

  @override
  late final Iterable<MapEntry<String, String>> entries = keys.map((key) => MapEntry(key, this[key]!));

  @override
  void forEach(void Function(String key, String value) action) {
    for (final entry in entries) {
      action(entry.key, entry.value);
    }
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    throw Exception('$runtimeType cannot be cast.');
  }

  @override
  void clear() {
    assert(false, 'Clearing $runtimeType is a no-op.');
  }

  @override
  bool containsValue(Object? value) => values.contains(value);

  void throwImmutable() => throw Exception('$runtimeType is immutable.');

  @override
  void operator []=(String key, String value) {
    assert(false, 'Attempted to reassign $runtimeType.$key. $runtimeType is immutable, so this is a no-op.');
  }

  @override
  void addAll(Map<String, String> other) => throwImmutable();

  @override
  void addEntries(Iterable<MapEntry<String, String>> newEntries) => throwImmutable();

  /// Although the 'style' key is always going to be present,
  /// we still check its existence via [entries] so that in the
  /// future, if 'style' does become nullable this code would still be correct.
  @override
  late final bool isEmpty = entries.isEmpty;

  @override
  late final bool isNotEmpty = !isEmpty;

  @override
  late final int length = keys.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(String key, String value) convert) {
    final ret = <MapEntry<K2, V2>>[];
    for (final entry in entries) {
      ret.add(convert(entry.key, entry.value));
    }
    return Map.fromEntries(ret);
  }

  @override
  String putIfAbsent(String key, String Function() ifAbsent) {
    assert(false, '$runtimeType.putIfAbsent will not mutate values, consider using indexed access instead.');
    return this[key] ?? ifAbsent();
  }

  @override
  String? remove(Object? key) {
    assert(false, 'Attempted to remove $runtimeType.$key. $runtimeType is immutable, so this is a no-op.');
  }

  @override
  void removeWhere(bool Function(String key, String value) test) {
    assert(false, 'Attempted to call $runtimeType.removeWhere. $runtimeType is immutable, so this is a no-op.');
  }

  @override
  String update(String key, String Function(String value) update, {String Function()? ifAbsent}) {
    assert(false, 'Attempted to call $runtimeType.update with key "$key". $runtimeType is immutable.');
    if (containsKey(key)) return update(key);
    if (ifAbsent == null) throw StateError('ifAbsent not provided.');
    return ifAbsent();
  }

  @override
  void updateAll(String Function(String key, String value) update) {
    throwImmutable();
  }

  @override
  String? generatedId;

  @override
  void accept(md.NodeVisitor visitor) {
    if (visitor.visitElementBefore(this)) {
      if (children != null) {
        for (final child in children!) {
          child.accept(visitor);
        }
      }
    }
    visitor.visitElementAfter(this);
  }

  @override
  Map<String, String> get attributes => this;

  @override
  late final List<md.Node>? children = computeChildren();
  List<md.Node>? computeChildren() {
    final slice = inner.c;
    if (slice.address == nullptr.address) return null;
    final ret = <md.Node>[];

    for (var i = 0; i < slice.ref.length; ++i) {
      ret.add(Element(slice.ref.ptr.elementAt(i)));
    }
    return ret;
  }

  @override
  late final String tag = computeTag();
  String computeTag() {
    final tag = tagMap[inner.t];
    if (tag == null) throw Exception('Tag not found: ${inner.t}');
    return tag;
  }

  @override
  late final String textContent = children?.map((e) => e.textContent).join('\n') ?? '';

  /// Maps [Tags] to their display values.
  static const tagMap = <int, String>{
    Tags.Paragraph: 'p',
    Tags.H1: 'h1',
    Tags.H2: 'h2',
    Tags.H3: 'h3',
    Tags.H4: 'h4',
    Tags.H5: 'h5',
    Tags.H6: 'h6',
    Tags.Pre: 'pre',
    Tags.Code: 'code',
    Tags.Image: 'img',
    Tags.Ruler: 'hr',
    Tags.Table: 'table',
    Tags.TableRow: 'tr',
    Tags.OrderedList: 'ol',
    Tags.UnorderedList: 'ul',
    Tags.ListItem: 'li',
    Tags.TableCell: 'td',
    Tags.TableHeaderCell: 'th',
    Tags.Strong: 'strong',
    Tags.Strikethrough: 's',
    Tags.Blockquote: 'blockquote',
    Tags.Emphasis: 'em',
    Tags.HardBreak: 'br',
    Tags.Anchor: 'a',
    Tags.Checkbox: 'checkbox',
    Tags.Math: 'math'
  };

  Map<String, dynamic> toJson() =>
      {'tag': tag, 'children': children?.map(Element.convert).toList(growable: false), ...attributes};
}

/// Contains either a string or an [HtmlTag].
class Element implements md.Node {
  final Pointer<CElement> inner;
  late final HtmlTag? innerTag = computeTag();
  HtmlTag? computeTag() {
    final maybeTag = lib.as_tag(inner);
    if (maybeTag.address != nullptr.address) return HtmlTag(maybeTag.ref);
  }

  @override
  late final String textContent = computeText();
  String computeText() {
    if (innerTag != null) {
      return innerTag!.textContent;
    }
    final ptr = lib.as_text(inner);
    return ptr.address == nullptr.address ? '' : ptr.cast<Utf8>().toDartString();
  }

  Element(this.inner);

  @override
  void accept(md.NodeVisitor visitor) {
    if (innerTag != null) {
      innerTag!.accept(visitor);
      return;
    }
    visitor.visitText(md.Text(textContent));
  }

  dynamic toJson() => innerTag != null ? innerTag!.toJson() : textContent;

  static dynamic convert(md.Node el) => el is Element ? el.toJson() : el.toString();
}
