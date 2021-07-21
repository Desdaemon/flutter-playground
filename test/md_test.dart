import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_diff/json_diff.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yata_flutter/ffi.dart';
// import 'package:ffi/ffi.dart';

List<dynamic> toJson(List<md.Node> nodes) {
  if (nodes.isEmpty) return nodes;
  final ret = <dynamic>[];
  for (var i = 0; i < nodes.length; ++i) {
    final n = nodes[i] as dynamic;
    if (n is md.Element) {
      ret.add({'t': n.tag, 'c': toJson(n.children ?? const [])}..addAll(n.attributes));
    } else {
      ret.add((n as md.Node).textContent);
    }
  }
  return ret;
}

void main() {
  group('markdown', () {
    test('it matches the reference implementation', () {
      final source = File('assets/markdown_reference.md').readAsLinesSync();
      // final ret = md.markdownToHtml(source, extensionSet: md.ExtensionSet.gitHubWeb);
      final document = md.Document(encodeHtml: false, extensionSet: md.ExtensionSet.gitHubWeb);
      final ret = document.parseLines(source);
      final ret1 = parseNodes(source.join('\n'));

      // final ptr = parseMarkdownXml(source.toNativeUtf8());
      // final ret1 = ptr.toDartString();
      // freeString(ptr);

      const encoder = JsonEncoder();
      File('test/reference.json').writeAsStringSync(encoder.convert(toJson(ret)));
      File('test/rust.json').writeAsStringSync(encoder.convert(ret1));

      // File('test/reference.json').writeAsStringSync(ret);
      // File('test/rust.json').writeAsStringSync(ret1);
    });
  });
}
