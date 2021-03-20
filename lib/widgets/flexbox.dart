import 'package:flutter/material.dart';

class Flexbox extends StatelessWidget {
  final List<Flexible> children;
  const Flexbox({
    Key? key,
    required this.children,
    this.colCross = CrossAxisAlignment.center,
    this.rowCross = CrossAxisAlignment.center,
    this.colAlign = MainAxisAlignment.start,
    this.rowAlign = MainAxisAlignment.start,
    this.colSize = MainAxisSize.max,
    this.rowSize = MainAxisSize.max,
  }) : super(key: key);

  static const xs = 576;
  static const sm = 768;
  static const md = 992;
  static const lg = 1200;

  final CrossAxisAlignment colCross;
  final CrossAxisAlignment rowCross;
  final MainAxisAlignment colAlign;
  final MainAxisAlignment rowAlign;
  final MainAxisSize colSize;
  final MainAxisSize rowSize;

  @override
  Widget build(BuildContext bc) {
    if (children.isEmpty) return Container();

    return LayoutBuilder(builder: (bc, cons) {
      final double cur;
      if (cons.maxWidth < xs) {
        cur = 2;
      } else if (cons.maxWidth < sm) {
        cur = 3;
      } else if (cons.maxWidth < md) {
        cur = 4;
      } else if (cons.maxWidth < lg) {
        cur = 6;
      } else {
        cur = 12;
      }
      final rows = <List<Flexible>>[];
      var row = <Flexible>[];
      int buffer = 0;
      for (final child in children) {
        if (buffer + child.flex > cur) {
          rows.add(row);
          row = [child];
          buffer = child.flex;
        } else {
          row.add(child);
          buffer += child.flex;
        }
      }
      if (row.isNotEmpty) {
        rows.add(row);
      }
      return Column(crossAxisAlignment: colCross, mainAxisAlignment: colAlign, mainAxisSize: colSize, children: [
        for (final row in rows)
          Row(crossAxisAlignment: rowCross, mainAxisAlignment: rowAlign, mainAxisSize: rowSize, children: row)
      ]);
    });
  }
}
