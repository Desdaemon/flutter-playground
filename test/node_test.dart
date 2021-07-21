import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:yata_flutter/ffi.dart';
import 'package:yata_flutter/types/node.dart';

void main() {
  group('Node', () {
    test('it works', () {
      expect(Node('tag'), equals(Node('tag')));
    });
    test('works with lists of children', () {
      expect(Node('tag', c: []), equals(Node('tag', c: [])));
    });
    test('children deep equals', () {
      final lhs = Node('tag', c: [
        {'t': 'tag', 'c': []},
        {'t': 'a', 'href': 'http://localhost'}
      ]);
      final rhs = Node('tag', c: [
        {'t': 'tag', 'c': []},
        {'t': 'a', 'href': 'http://localhost'}
      ]);
      expect(lhs, equals(rhs));
    });
    test('caching works', () {
      final cache = HashMap<md.Node, List<md.Node>?>();
      final lhs = Node.fromJson({
        "t": "p",
        "c": [
          {"t": "img", 'href': 'http://localhost', 'c': []}
        ],
        'align': [1, 2, 3]
      }) as Node;
      final children = cache[lhs] = lhs.children;
      final retrieved = cache[lhs]!;
      expect(children.hashCode, equals(retrieved.hashCode));
    });
    test('no cache misses', () {
      final file = File('assets/markdown_reference.md').readAsStringSync();
      final json = parseNodes(file);
      final List<md.Node> nodes = json.map(Node.fromJson).toList();
      final cache = HashMap<int, List<md.Node>?>();
      for (final node in nodes) {
        cache[node.hashCode] = (node as Node).children;
      }
      final before = cache.length;
      final List<md.Node> nodes2 = json.map(Node.fromJson).toList();
      for (final node in nodes2) {
        cache[node.hashCode] ??= (node as Node).children;
      }
      final after = cache.length;
      expect(before, equals(after));
    });
  });
}
