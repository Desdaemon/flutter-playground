import 'package:flutter/material.dart';
import 'package:yata_flutter/screens/markdown.dart';

mixin MarkdownPlatform on State<MathMarkdown> {
  RestorableTextEditingController get ctl;
  String get untitled;
  Future<void> open() async => throw UnimplementedError();

  Future<void> exportImpl(String content, [String? key]) async => throw UnimplementedError();
  Future<void> save() async => throw UnimplementedError();

  void activatePath(String path, String contents);
}
