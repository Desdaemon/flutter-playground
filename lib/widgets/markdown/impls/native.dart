import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yata_flutter/bindings/stub.dart';
import 'package:yata_flutter/ffi.dart';
import 'package:yata_flutter/types/native_node.dart' as nat;

mixin FastParse<T extends StatefulWidget> on State<T> {
  Pointer<Slice_CElement> ptr = nullptr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    freeElements(ptr);
  }

  List<md.Node> fastParse(String input) {
    final ret = <nat.Element>[];
    ptr = parseMarkdownAst(input.toNativeUtf8().cast<Int8>());
    for (var i = 0; i < ptr.ref.length; i++) {
      ret.add(nat.Element(ptr.ref.ptr.elementAt(i)));
    }
    return ret;
  }
}
