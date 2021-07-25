import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yata_flutter/bindings/bindings.dart';

mixin FastParse<T extends StatefulWidget> on State<T> {
  List<md.Node> fastParse(String input) {
    return parseMarkdown(input).map(JSONElement.fromStrOrMap).toList(growable: false);
  }
}

/// Allows a Map to pretend to be an [md.Element] without having
/// to deserialize into a proper element type.
class JSONElement extends md.Element {
  final Map<String, dynamic> json;
  List<md.Node>? _children;
  static final mathre = RegExp(r'\$\$?([^$]+)(\$?)\$');

  JSONElement(this.json) : super.empty(json['t'] as String) {
    attributes.addAll({
      for (final entry in json.entries)
        if (entry.value is String) entry.key: entry.value as String
    });
    switch (tag) {
      case 'a':
        if (isEmpty) _children = [md.Text(json['href'] as String)];
        break;
      case 'pre':
        _children = [md.Text((json['c'] as List<dynamic>).join())];
        break;
    }
  }

  static md.Node fromStrOrMap(dynamic json) {
    if (json is String) {
      final match = mathre.matchAsPrefix(json);
      if (match != null) {
        final output = md.Element.text('math', match[1]!);
        if (match[2]!.isEmpty) {
          output.attributes['text'] = '';
        }
        return output;
      }
      return md.Text(json);
    }
    return JSONElement(json as Map<String, dynamic>);
  }

  @override
  List<md.Node>? get children => _children ??= (json['c'] as List<dynamic>?)?.map(JSONElement.fromStrOrMap).toList();

  @override
  bool get isEmpty => (children ?? json['c'] as List<dynamic>?)?.isEmpty ?? true;

  Map<String, dynamic> toJson() => json;
}
