import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:yata_flutter/bindings.dart';

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
typedef ParseMarkdown = Pointer<Utf8> Function(Pointer<Utf8>);

/// Wrapper around [parseMarkdown] + [freeString]
List<dynamic> parseNodes(String markdown) {
  final ptr = lib.parse_markdown(markdown.toNativeUtf8().cast<Int8>());
  final source = ptr.cast<Utf8>().toDartString();
  final output = jsonDecode(source) as List<dynamic>;
  lib.free_string(ptr);
  return output;
}
