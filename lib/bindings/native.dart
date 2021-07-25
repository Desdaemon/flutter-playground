import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:universal_io/io.dart';
import 'package:yata_flutter/ffi.dart';

/// Sometimes "armeabi-v7a" for 32-bit machines.
const androidArch = String.fromEnvironment('ANDROID_ARCH', defaultValue: 'arm64-v8a');
final libPath = Platform.isWindows
    ? 'target/release/flutter_playground.dll'
    : Platform.isAndroid
        ? 'libflutter_playground.so'
        : Platform.isLinux
            ? 'target/release/libflutter_playground.so'
            : const String.fromEnvironment('LIBRARY');
final dylib = DynamicLibrary.open(libPath);
final lib = MarkdownRust(dylib);

List<dynamic> parseMarkdown(String input) {
  final ptr = lib.parse_markdown(input.toNativeUtf8().cast<Int8>());
  final ret = jsonDecode(ptr.cast<Utf8>().toDartString()) as List<dynamic>;
  lib.free_string(ptr);
  return ret;
}

final parseMarkdownAst = lib.parse_markdown_ast;
final freeElements = lib.free_elements;
final asTag = lib.as_tag;
final asText = lib.as_text;

dynamic wasmParseMarkdownAst(String input) {
  throw UnimplementedError('Unimplemented on non-wasm32 platforms');
}
