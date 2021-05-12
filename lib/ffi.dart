import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef ParseMarkdown = Pointer<Utf8> Function(Pointer<Utf8>);
typedef free_string = Void Function(Pointer<Utf8>);
typedef FreeString = void Function(Pointer<Utf8>);

/// Sometimes "armeabi-v7a" for 32-bit machines.
const androidArch = String.fromEnvironment('ANDROID_ARCH', defaultValue: 'arm64-v8a');
final libPath = Platform.isWindows
    ? 'target/release/flutter_playground.dll'
    : Platform.isAndroid
        ? 'libflutter_playground.so'
        : Platform.isLinux
            ? 'target/release/libflutter_playground.so'
            : const String.fromEnvironment('LIBRARY');
final lib = DynamicLibrary.open(libPath);
final parseMarkdown = lib.lookupFunction<ParseMarkdown, ParseMarkdown>('parse_markdown');
final freeString = lib.lookupFunction<free_string, FreeString>('free_string');

/// Wrapper around [parseMarkdown] + [freeString]
List<dynamic> parseNodes(String markdown) {
  final ptr = parseMarkdown(markdown.toNativeUtf8());
  final output = jsonDecode(ptr.toDartString()) as List<dynamic>;
  freeString(ptr);
  return output;
}
