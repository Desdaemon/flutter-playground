import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_fork/tex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:yata_flutter/ffi.dart';
import 'package:yata_flutter/state/markdown.dart';
// import 'package:yata_flutter/types/node.dart';

/// Allows a Map to pretend to be an [md.Element] without having
/// to deserialize into a proper element type.
class JSONElement extends md.Element {
  final Map<String, dynamic> json;
  final int alignment;
  List<md.Node>? _children;
  static final mathre = RegExp(r'\$\$?([^$]+)(\$?)\$');
  // static final cache = HashMap<int, List<md.Node>?>();
  static void clearCache() {
    // cache.clear();
  }

  // @override
  // int get hashCode => runtimeType.hashCode ^ alignment.hashCode ^ const DeepCollectionEquality().hash(json);

  // @override
  // bool operator ==(Object other) => other is JSONElement && other.hashCode == hashCode;

  JSONElement(this.json, {this.alignment = 1}) : super.empty(json['t'] as String) {
    // final _hash = hashCode;
    if (tag == 'table') {
      final c = json['c'] as List<dynamic>;
      final aligns = json['align'] as List<dynamic>;
      _children = <md.Node>[];
      for (var i = 0; i < c.length; ++i) {
        _children!.add(JSONElement(
          c[i] as Map<String, dynamic>,
          alignment: aligns.length - 1 < i ? 0 : aligns[i] as int,
        ));
      }
      // cache[_hash] = _children;
      return;
    }
    switch (tag) {
      case 'ol':
        attributes['start'] = json['start'].toString();
        break;
      case 'a':
        attributes['href'] = json['href'] as String;
        if (isEmpty) _children = [md.Text(json['href'] as String)];
        break;
      case 'checkbox':
        attributes['type'] = 'checkbox';
        attributes['checked'] = json['value'] as String;
        break;
      case 'img':
        attributes['src'] = json['href'] as String;
        break;
      case 'td':
      case 'th':
        String style = 'text-align: left';
        switch (alignment) {
          case 2:
            style = 'text-align: center';
            break;
          case 3:
            style = 'text-align: right';
            break;
          default:
            break;
        }
        attributes['style'] = style;
        break;
      case 'pre':
        _children = [md.Text((json['c'] as List<dynamic>).join())];
        break;
      case 'code':
        _children = [md.Text(json['value'] as String)];
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
    return JSONElement(json as Map<String, dynamic>);
  }

  @override
  List<md.Node>? get children => _children ??= (json['c'] as List<dynamic>?)?.map(JSONElement.fromStrOrMap).toList();

  @override
  bool get isEmpty => (children ?? json['c'] as List<dynamic>?)?.isEmpty ?? true;
}

class CustomMarkdownBody extends StatelessWidget implements MarkdownBuilderDelegate {
  final String data;
  final double scale;
  final MarkdownStyleSheet style;
  final bool nativeParse;
  // final bool cache;
  final void Function(String, String?, String)? onTapLink;
  const CustomMarkdownBody(
    this.data, {
    Key? key,
    // this.cache = true,
    this.scale = 1,
    this.onTapLink,
    required this.style,
    this.nativeParse = true,
  }) : super(key: key);

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
    final List<md.Node> nodes;
    final st = Stopwatch()..start();
    if (nativeParse) {
      final document = md.Document(
        inlineSyntaxes: [MathSyntax.instance],
        extensionSet: md.ExtensionSet.gitHubWeb,
        encodeHtml: false,
      );
      final lines = const LineSplitter().convert(data);
      nodes = document.parseLines(lines);
    } else {
      nodes = parseNodes(data).map(/** cache ? Node.fromJson : */ JSONElement.fromStrOrMap).toList(growable: false);
    }
    final t0 = st.elapsed;
    final children = mdBuilder.build(nodes);
    final t1 = st.elapsed - t0;
    print('${nativeParse ? 'n' : ' '} $t0 $t1 ${st.elapsed} ${MathBuilder.cache.length} items');
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

class MarkdownPreview extends StatelessWidget {
  final String expr;

  // final ScrollController? sc;
  final double scale;

  /// Disabled by default due to high performance impact
  final bool selectable;
  const MarkdownPreview({Key? key, required this.expr, this.scale = 1, this.selectable = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = MarkdownStyleSheet.fromTheme(theme).copyWith(
      blockquoteDecoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(left: BorderSide(color: theme.colorScheme.secondary, width: 4)),
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
        // cache: watch(pCache).state,
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
  final double scale;
  MathBuilder({this.scale = 1});
  static final cache = HashMap<String, List<GreenNode>>();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    final textMode = element.attributes.containsKey('text');
    List<GreenNode>? ast;
    ParseException? exception;

    try {
      ast = cache[tex] ??= TexParser(
        tex,
        textMode ? const TexParserSettings() : const TexParserSettings(displayMode: true),
      ).parseExpression();
    } on ParseException catch (e) {
      ast = null;
      cache.remove(tex);
      exception = e;
    } catch (e) {
      rethrow;
    }

    final child = SingleChildScrollView(
      child: Math(
        ast: ast != null ? SyntaxTree(greenRoot: EquationRowNode(children: ast)) : null,
        parseError: exception,
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
  static final instance = MathSyntax();
  MathSyntax() : super(r'\$\$?([^$]+)(\$?)\$');
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
