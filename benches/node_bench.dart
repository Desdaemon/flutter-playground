import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_playground/bindings/bindings.dart';

void main() {
  final source = File('assets/markdown_reference.md').readAsStringSync();
  // final utf8 = source.toNativeUtf8();
  final st = Stopwatch();

  var passes = 0;
  st.start();
  while (st.elapsedMilliseconds <= 5000) {
    final slice = parseMarkdownAst(source.toNativeUtf8().cast<Int8>());
    freeElements(slice);
    passes++;
  }

  var passes1 = 0;
  st.reset();
  while (st.elapsedMilliseconds <= 5000) {
    parseMarkdown(source);
    passes1++;
  }
  print('$passes $passes1');
  // final slice = lib.parse_markdown_ast(utf8.cast<Int8>());
  // for (var i = 0; i < slice.ref.length; i++) {
  //   final item = slice.ref.ptr.elementAt(i);
  //   // final tag = lib.as_tag(item);
  //   // if (tag.isNotNull()) {
  //   // print('$tag ${tag.ref.c}');
  //   // continue;
  //   // }
  //   final text = lib.as_text(item);
  //   if (text.isNotNull()) {
  //     print('$i ${text.address} ${text.castString()}');
  //   }
  // }
  // lib.free_elements(slice.cast<Slice_CElement>());
}

extension PointerX on Pointer<dynamic> {
  String format() {
    if (isNull()) return 'null';
    return toString();
  }

  /// Casts this pointer if it is a [Pointer] to [Int8],
  /// otherwise returns null.
  String? castString() {
    try {
      return cast<Utf8>().toDartString();
    } catch (_) {
      return '<non-utf8>';
    }
  }

  bool isNull() => address == nullptr.address;
  bool isNotNull() => !isNull();
}
