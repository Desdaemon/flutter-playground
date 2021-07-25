import 'dart:convert';
import 'dart:ffi';

import 'package:yata_flutter/ffi.dart';
import 'pkg/flutter_playground.dart';

List parseMarkdown(String input) {
  final json = wasm_parse_markdown(input);
  return jsonDecode(json) as List;
}

Pointer<CElement> parseMarkdownAst(Pointer<Int8> ptr) => throw UnimplementedError('Not implemented on wasm-32');

void freeElements(Pointer<Slice_CElement> ptr) {
  assert(false, 'No-op on wasm-32');
}

dynamic wasmParseMarkdownAst(String input) => wasm_parse_markdown_ast(input);

Pointer<CHtmlTag> asTag(Pointer<CElement> ptr) => throw UnimplementedError();
Pointer<Int8> asText(Pointer<CElement> ptr) => throw UnimplementedError();
