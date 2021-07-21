import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:markdown/markdown.dart' as md;

part 'node.freezed.dart';

final mathre = RegExp(r'\$\$?([^$]+)(\$?)\$');

@freezed
class Node extends md.Element with _$Node {
  static HashMap<int, List<md.Node>?> cache = HashMap();
  static void clearCache() => cache.clear();

  factory Node(
    String t, {
    List? c,
    int? alignment,
    Map<String, String>? props,
  }) = _Node;
  Node._() : super.empty('span');

  static md.Node fromJson(dynamic json) {
    if (json is String) {
      final match = mathre.matchAsPrefix(json);
      if (match != null) {
        final ret = Node('math', props: {'': match[1]!, if (match[2]!.isEmpty) 'text': ''});
        cache[ret.hashCode] ??= [md.Text(match[1]!)];
        return ret;
      }
      return md.Text(json);
    }
    assert(json is Map<String, dynamic>);
    final t = json['t'] as String;

    // Precompute children and props of the following tags.
    switch (t) {
      case 'pre':
        final lang = json['lang'] as String?;
        return Node(
          'pre',
          c: json['c'] as List,
          props: {
            'indent': json['indent'].toString(),
            if (lang != null) 'lang': lang,
          },
        );
      case 'ol':
        return Node('ol', c: json['c'] as List, props: {'start': json['start'].toString()});
      case 'table':
        final c = json['c'] as List;
        final aligns = json['align'] as List;
        final _children = <md.Node>[];
        for (var i = 0; i < c.length; ++i) {
          _children
              .add((Node.fromJson(c[i]) as Node).copyWith(alignment: aligns.length - 1 < i ? 0 : aligns[i] as int));
        }
        final ret = Node('table', c: c);
        cache[ret.hashCode] ??= _children;
        return ret;
      case 'a':
      case 'img':
        final c = json['c'] as List;
        final href = json['href'] as String;
        final ret = Node(t, c: c, props: {'href': href, 'src': href});
        if (c.isEmpty) cache[ret.hashCode] ??= [md.Text(href)];
        return ret;
      case 'code':
      case 'checkbox':
        final value = json['value'].toString();
        final ret = Node(t, props: {'value': value, 'type': 'checkbox'});
        if (t == 'code') cache[ret.hashCode] ??= [md.Text(value)];
        return ret;
      default:
        // The rest will be created on demand.
        return Node(t, c: json['c'] as List?);
    }
  }

  static List<md.Node> fromList(List json) {
    return json.map(Node.fromJson).toList();
  }

  @override
  List<md.Node>? get children {
    final _hash = hashCode;
    if (cache[_hash] != null) return cache[_hash];
    if (c == null || c!.isEmpty) return null;
    final List<md.Node>? ret;
    switch (t) {
      case 'pre':
      case 'ol':
      case 'table':
      case 'a':
      case 'img':
        ret = fromList(c!);
        break;
      default:
        ret = c?.map(fromJson).toList();
    }
    return cache[_hash] = ret;
  }

  @override
  Map<String, String> get attributes => props ?? const {};

  @override
  String get tag => t;
}
