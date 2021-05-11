import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/gestures/recognizer.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_fork/tex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:yata_flutter/ffi.dart';

md.Node handleNode(dynamic json, [int alignment = 0]) {
  if (json is String) return md.Text(json);
  final type = json['t'] as String;
  if (type == 'table') {
    final aligns = json['align'] as List<int?>;
    final _children = json['c'] as List<dynamic>;
    final outChildren = <md.Node>[];
    for (var i = 0; i < _children.length; i++) {
      outChildren.add(handleNode(_children[i], aligns[i] ?? 0));
    }
    return md.Element('table', outChildren);
  }
  final children = (json['c'] as List<dynamic>?)?.map((e) => handleNode(e, alignment)).toList() ?? const [];
  switch (type) {
    case 'ol':
      return md.Element('ol', children)..attributes['start'] = json['start'] as String;
    case 'a':
      return md.Element('a', [md.Text(json['title'] as String)])..attributes['href'] = json['href'] as String;
    case 'checkbox':
      return md.Element.empty('checkbox')
        ..attributes['type'] = 'checkbox'
        ..attributes['checked'] = json['value'] as String;
    case 'img':
      return md.Element.empty('img')
        ..attributes['src'] = json['href'] as String
        ..attributes['title'] = json['title'] as String;
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
      final output = md.Element(type, children);
      if (style != null) {
        output.attributes['style'] = style;
      }
      return output;
    default:
      return md.Element(type, children);
  }
}

class CustomMarkdownBody extends HookWidget implements MarkdownBuilderDelegate {
  final String data;
  final double scale;
  final MarkdownStyleSheet style;
  final void Function(String, String?, String)? onTapLink;
  const CustomMarkdownBody(this.data, {Key? key, this.scale = 1, this.onTapLink, required this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mdBuilder = useMemoized(
      () => MarkdownBuilder(
        delegate: this,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        selectable: false,
        imageDirectory: null,
        imageBuilder: null,
        checkboxBuilder: (val) =>
            val ? const Icon(Icons.check_box, size: 12) : const Icon(Icons.check_box_outline_blank, size: 12),
        bulletBuilder: null,
        // builders: {'math': MathBuilder(scale: scale)},
        builders: const {},
        listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      ),
      [],
    );
    return useMemoized(() {
      final nodes = parseNodes(data).map(handleNode).toList();
      final children = mdBuilder.build(nodes);
      return Column(children: children);
    }, [data, scale]);
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final output = TapGestureRecognizer();
    if (onTapLink != null) output.onTap = () => onTapLink!.call(text, href, title);
    return output;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet _, String code) {
    return TextSpan(text: code);
  }
}

class MarkdownPreview extends HookWidget {
  const MarkdownPreview(
      {Key? key, ScrollController? scrollController, required this.expr, this.scale = 1, this.selectable = false})
      : sc = scrollController,
        super(key: key);

  final ScrollController? sc;
  final String expr;
  final double scale;

  /// Disabled by default due to high performance impact
  final bool selectable;

  /// [Markdown] is buggy so we manually insert a scroll view here and use [MarkdownBody] instead.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return useMemoized(() {
      return CustomMarkdownBody(
        expr,
        // shrinkWrap: false,
        // extensionSet: md.ExtensionSet.gitHubWeb,
        // inlineSyntaxes: [MathSyntax.instance],
        // builders: {'math': MathBuilder(scale: scale)},
        // checkboxBuilder: (val) =>
        //     val ? const Icon(Icons.check_box, size: 12) : const Icon(Icons.check_box_outline_blank, size: 12),
        // selectable: selectable,
        style: MarkdownStyleSheet.fromTheme(theme).copyWith(
          blockquoteDecoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(left: BorderSide(color: theme.accentColor, width: 4)),
          ),
          textScaleFactor: scale,
          blockSpacing: 12 * scale,
          listBullet: TextStyle(fontSize: theme.textTheme.bodyText2!.fontSize! * scale),
          code: const TextStyle(fontFamily: 'JetBrains Mono', backgroundColor: Colors.transparent),
        ),
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
      );
    }, [expr, scale, theme.hashCode]);
  }
}

class MathBuilder extends MarkdownElementBuilder {
  MathBuilder({this.scale = 1});
  final double scale;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    final textMode = element.attributes.containsKey('text');
    final child = MathBlock(tex, style: textMode ? MathStyle.text : MathStyle.display);
    return textMode ? child : Align(key: ValueKey(tex), child: child);
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

class MathBlock extends StatefulWidget {
  const MathBlock(this.data, {Key? key, required this.style}) : super(key: key);
  final String data;
  final MathStyle style;

  @override
  _MathBlockState createState() => _MathBlockState();
}

class _MathBlockState extends State<MathBlock> {
  final lexer = Lexer();
  late Future<SyntaxTree> ast;
  @override
  void initState() {
    super.initState();
    ast = lexer.start(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SyntaxTree>(
      future: ast,
      builder: (bc, fut) {
        if (fut.hasData) {
          return SingleChildScrollView(child: Math(ast: fut.data, mathStyle: widget.style));
        } else if (fut.hasError) {
          return Text(fut.error.toString(), style: const TextStyle(color: Colors.red));
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

typedef Worker = void Function(SendPort send);

class Lexer {
  Isolate? isolate;
  Future<SyntaxTree> start(String data) async {
    final rec = ReceivePort();
    isolate = await Isolate.spawn(spawnTask(data), rec.sendPort);
    final comp = Completer<SyntaxTree>();
    rec.listen((message) {
      if (message is SyntaxTree) {
        comp.complete(message);
      } else {
        comp.completeError(message.toString());
      }
    });
    return comp.future;
  }

  Worker spawnTask(String data) {
    return (SendPort send) {
      dynamic output;
      try {
        output = SyntaxTree(greenRoot: TexParser(data, const TexParserSettings()).parse());
      } on ParseException catch (e) {
        output = e;
      } catch (e) {
        output = 'Unknown error: $e';
      }
      send.send(output);
      return stop();
    };
  }

  void stop() {
    if (isolate != null) {
      isolate!.kill(priority: Isolate.immediate);
      isolate = null;
    }
  }
}
