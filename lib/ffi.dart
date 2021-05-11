import 'dart:convert';
import 'dart:ffi' as ffi;

import 'dart:io';

import 'package:ffi/ffi.dart';

final libraryExtension = Platform.isWindows
    ? 'dll'
    : Platform.isIOS
        ? 'dylib'
        : 'so';
final lib = ffi.DynamicLibrary.open('target/release/flutter_playground.$libraryExtension');
typedef ParseMarkdown = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);
typedef free_string = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeString = void Function(ffi.Pointer<Utf8>);
final parseMarkdown = lib.lookup<ffi.NativeFunction<ParseMarkdown>>('parse_markdown').asFunction<ParseMarkdown>();
final freeString = lib.lookup<ffi.NativeFunction<free_string>>('free_string').asFunction<FreeString>();
List<Map<String, dynamic>> parseNodes(String markdown) {
  final ptr = parseMarkdown(markdown.toNativeUtf8());
  final output = jsonDecode(ptr.toDartString()) as List<Map<String, dynamic>>;
  freeString(ptr);
  return output;
}
