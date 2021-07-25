import 'package:flutter/material.dart';
import 'package:flutter_playground/bindings/bindings.dart';
import 'package:flutter_playground/types/json_element.dart';
import 'package:markdown/markdown.dart' as md;

mixin FastParse<T extends StatefulWidget> on State<T> {
  List<md.Node> fastParse(String input) {
    return parseMarkdown(input).map(JSONElement.fromStrOrMap).toList();
  }
}
