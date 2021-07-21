import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

Widget iconOf(ThemeMode dark) {
  switch (dark) {
    case ThemeMode.system:
      return const Tooltip(message: 'System Theme', child: Icon(Icons.brightness_auto));
    case ThemeMode.light:
      return const Tooltip(message: 'Light Theme', child: Icon(Icons.brightness_medium));
    case ThemeMode.dark:
      return const Tooltip(message: 'Dark Theme', child: Icon(Icons.brightness_2));
  }
}

String shortenPath(String input, [int at = 40]) {
  if (input.length > at) {
    final segments = p.split(input);
    final end = segments.length - 1;
    if (end >= 3) {
      segments.replaceRange(3, end, List.filled(end - 3, '..', growable: false));
      return p.joinAll(segments);
    }
  }
  return input;
}

String blanks(int length) {
  if (length < 1) return '';
  final bf = StringBuffer();
  for (var i = 0; i < length; i++) {
    bf.writeCharCode(32 /* space */);
  }
  return bf.toString();
}
