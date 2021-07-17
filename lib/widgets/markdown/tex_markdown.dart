import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:yata_flutter/ffi.dart';
import 'package:yata_flutter/state/markdown.dart';

final mathre = RegExp(r'\$\$?([^$]+)(\$?)\$');
md.Node handleNode(dynamic json, [int alignment = 0]) {
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
  final type = json['t'] as String;
  if (type == 'table') {
    final aligns = json['align'] as List<dynamic>;
    final _children = json['c'] as List<dynamic>;
    final outChildren = <md.Node>[];
    for (var i = 0; i < _children.length; i++) {
      outChildren.add(handleNode(_children[i], aligns.length - 1 < i ? 0 : aligns[i] as int));
    }
    return md.Element('table', outChildren);
  }
  List<md.Node> children() => (json['c'] as List<dynamic>?)?.map((e) => handleNode(e, alignment)).toList() ?? const [];
  switch (type) {
    case 'ol':
      return md.Element('ol', children())..attributes['start'] = json['start'].toString();
    case 'a':
      final _children = children();
      if (_children.isEmpty) _children.add(md.Text(json['href'] as String));
      return md.Element('a', _children)..attributes['href'] = json['href'] as String;
    case 'checkbox':
      return md.Element.empty('checkbox')
        ..attributes['type'] = 'checkbox'
        ..attributes['checked'] = json['value'] as String;
    case 'img':
      return md.Element.empty('img')..attributes['src'] = json['href'] as String;
    case 'td':
    case 'th':
      String? style;
      switch (alignment) {
        case 1:
          style = 'text-align: left';
          break;
        case 2:
          style = 'text-align: center';
          break;
        case 3:
          style = 'text-align: right';
          break;
        default:
          break;
      }
      final output = md.Element(type, children());
      if (style != null) {
        output.attributes['style'] = style;
      }
      return output;
    case 'pre':
      return md.Element.text('pre', (json['c'] as List<dynamic>).join());
    case 'code':
      return md.Element.text('code', json['value'] as String);
    default:
      return md.Element(type, children());
  }
}

class CustomMarkdownBody extends HookWidget implements MarkdownBuilderDelegate {
  final String data;
  final double scale;
  final MarkdownStyleSheet style;
  final bool nativeParse;
  final void Function(String, String?, String)? onTapLink;
  const CustomMarkdownBody(this.data,
      {Key? key, this.scale = 1, this.onTapLink, required this.style, this.nativeParse = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mdBuilder = MarkdownBuilder(
      delegate: this,
      styleSheet: style,
      selectable: false,
      imageDirectory: null,
      imageBuilder: null,
      checkboxBuilder: (val) =>
          val ? const Icon(Icons.check_box, size: 12) : const Icon(Icons.check_box_outline_blank, size: 12),
      bulletBuilder: null,
      builders: {'math': MathBuilder(scale: scale)},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
    );
    List<md.Node> nodes;
    if (nativeParse) {
      final document = md.Document(
          inlineSyntaxes: [MathSyntax.instance], extensionSet: md.ExtensionSet.gitHubWeb, encodeHtml: false);
      final lines = const LineSplitter().convert(data);
      nodes = document.parseLines(lines);
    } else {
      nodes = parseNodes(data).map(handleNode).toList();
    }
    final children = mdBuilder.build(nodes);
    return Column(children: children);
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final output = TapGestureRecognizer();
    if (onTapLink != null) output.onTap = () => onTapLink!.call(text, href, title);
    return output;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet style, String code) {
    return TextSpan(text: code, style: style.code);
  }
}

class MarkdownPreview extends HookWidget {
  const MarkdownPreview({Key? key, required this.expr, this.scale = 1, this.selectable = false}) : super(key: key);

  // final ScrollController? sc;
  final String expr;
  final double scale;

  /// Disabled by default due to high performance impact
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = MarkdownStyleSheet.fromTheme(theme).copyWith(
      blockquoteDecoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(left: BorderSide(color: theme.accentColor, width: 4)),
      ),
      textScaleFactor: scale,
      blockSpacing: 12 * scale,
      listBullet: TextStyle(fontSize: theme.textTheme.bodyText2!.fontSize! * scale),
      code: const TextStyle(fontFamily: 'JetBrains Mono', backgroundColor: Colors.transparent),
    );
    return Consumer(
      builder: (bc, watch, _) => CustomMarkdownBody(
        expr,
        scale: scale,
        style: style,
        nativeParse: watch(pNativeParsing).state,
        onTapLink: (text, href, title) async {
          if (href == null) return;
          if (href.startsWith('#')) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Header links are not supported'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orangeAccent,
            ));
            return;
          }
          if (await canLaunch(href)) {
            final answer = await showDialog<bool>(
              context: context,
              builder: (bc) => SimpleDialog(
                title: Text('Open $text?'),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(bc, true),
                    child: const Text('Yes!'),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(bc, false),
                    child: const Text('No! Take me back!'),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: href));
                      Navigator.pop(bc, false);
                    },
                    child: const Text('Copy link to clipboard'),
                  )
                ],
              ),
            );
            if (answer ?? false) launch(href);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$text could not be opened'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.errorColor,
            ));
          }
        },
      ),
    );
  }
}

class MathBuilder extends MarkdownElementBuilder {
  MathBuilder({this.scale = 1});
  final double scale;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    final textMode = element.attributes.containsKey('text');
    final child = SingleChildScrollView(
      child: Math.tex(
        tex,
        mathStyle: textMode ? MathStyle.text : MathStyle.display,
        textScaleFactor: scale,
        onErrorFallback: (e) {
          return Tooltip(message: e.message, child: Text(tex, style: const TextStyle(color: Colors.red)));
        },
      ),
    );
    return textMode ? child : Align(child: child);
  }
}

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$?([^$]+)(\$?)\$');
  static final instance = MathSyntax();
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final elem = md.Element.text('math', match[1]!);
    final textMode = match[2]?.isEmpty ?? true;
    if (textMode) {
      elem.attributes['text'] = '';
      parser.addNode(elem);
    } else {
      parser.addNode(md.Element('p', [elem]));
    }
    return true;
  }
}
