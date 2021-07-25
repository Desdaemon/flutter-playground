import 'dart:ffi';

import 'package:yata_flutter/ffi.dart';

List<dynamic> parseMarkdown(String input) => throw UnimplementedError();
Pointer<Slice_CElement> parseMarkdownAst(Pointer<Int8> ptr) => throw UnimplementedError();
void freeElements(Pointer<Slice_CElement> ptr) => throw UnimplementedError();
dynamic wasmParseMarkdownAst(String input) => throw UnimplementedError();
Pointer<CHtmlTag> asTag(Pointer<CElement> ptr) => throw UnimplementedError();
Pointer<Int8> asText(Pointer<CElement> ptr) => throw UnimplementedError();
