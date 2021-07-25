import 'dart:convert';

import 'pkg/flutter_playground.dart';

List parseMarkdown(String input) {
  final json = wasm_parse_markdown(input);
  return jsonDecode(json) as List;
}

void parseMarkdownAst(dynamic ptr) => throw UnimplementedError('Not implemented on wasm-32');

void freeElements(dynamic ptr) {
  assert(false, 'No-op on wasm-32');
}

const wasmParseMarkdownAst = wasm_parse_markdown_ast;

void asTag(dynamic ptr) => throw UnimplementedError();
void asText(dynamic ptr) => throw UnimplementedError();
