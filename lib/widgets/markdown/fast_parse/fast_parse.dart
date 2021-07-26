import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;

mixin FastParse<T extends StatefulWidget> on State<T> {
  List<md.Node> fastParse(String input) {
    throw UnimplementedError();
  }
}
