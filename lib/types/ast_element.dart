import 'package:flutter_playground/bindings/pkg/flutter_playground.dart';
import 'package:markdown/markdown.dart' as md;

/// Allows a Map to pretend to be an [md.Element] without having
/// to deserialize into a proper element type.
class AstElement extends md.Element {
  final IHtmlTag inner;
  List<md.Node>? _children;
  static final mathre = RegExp(r'\$\$?([^$]+)(\$?)\$');

  AstElement(this.inner) : super.empty(inner.t) {
    attributes.addAll({
      if (inner.src != null) 'src': inner.src!,
      if (inner.href != null) 'href': inner.href!,
      if (inner.style != null && inner.style!.isNotEmpty)
        'style': inner.style!
      else if (inner.style != null)
        'style': 'text-align: left',
      if (inner.checked != null) 'checked': inner.checked.toString(),
      if (inner.display != null) 'display': inner.display.toString()
    });
    switch (tag) {
      case 'a':
        if (isEmpty) _children = [md.Text(inner.href!)];
        break;
      case 'pre':
        _children = [md.Text(inner.c!.join())];
        break;
    }
  }

  static md.Node fromStrOrMap(dynamic json) {
    if (json is String) {
      final match = mathre.matchAsPrefix(json);
      if (match != null) {
        final output = md.Element.text('math', match[1]!);
        if (match[2]!.isEmpty) {
          output.attributes['text'] = '';
        }
        return output;
      }
      return md.Text(json);
    }
    return AstElement(json as IHtmlTag);
  }

  @override
  List<md.Node>? get children => _children ??= inner.c?.map(AstElement.fromStrOrMap).toList();

  @override
  bool get isEmpty => (children ?? inner.c)?.isEmpty ?? true;

  Map<String, dynamic> toJson() => {
        't': inner.t,
        'c': inner.c,
        'src': inner.src,
        'href': inner.href,
        'style': inner.style,
        'checked': inner.checked,
        'display': inner.display
      };
}
