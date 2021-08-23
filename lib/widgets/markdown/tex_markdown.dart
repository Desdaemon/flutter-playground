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
import 'package:flutter_playground/state/markdown.dart';
import 'package:flutter_playground/widgets/markdown/fast_parse/fast_parse.dart'
    if (dart.library.io) 'fast_parse/fast_parse.native.dart'
    if (dart.library.html) 'fast_parse/fast_parse.web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class CustomMarkdownBody extends StatefulWidget implements MarkdownBuilderDelegate {
  final String data;
  final double scale;
  final MarkdownStyleSheet style;
  final bool nativeParse;
  final bool lockstep;
  final ScrollController? scrollController;
  final void Function(String, String?, String)? onTapLink;

  @override
  State<StatefulWidget> createState() => _CustomMarkdownBodyState();

  const CustomMarkdownBody(this.data,
      {Key? key,
      this.scale = 1,
      this.onTapLink,
      required this.style,
      this.nativeParse = true,
      this.scrollController,
      this.lockstep = true})
      : super(key: key);

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

class _CustomMarkdownBodyState extends State<CustomMarkdownBody> with FastParse {
  @override
  void initState() {
    super.initState();
    print('initState');
  }

  List<md.Node> nodes = [];
  @override
  Widget build(BuildContext context) {
    final mdBuilder = MarkdownBuilder(
      delegate: widget,
      styleSheet: widget.style,
      selectable: false,
      imageDirectory: null,
      imageBuilder: null,
      checkboxBuilder: (val) =>
          val ? const Icon(Icons.check_box, size: 12) : const Icon(Icons.check_box_outline_blank, size: 12),
      bulletBuilder: null,
      builders: {'math': MathBuilder(scale: widget.scale)},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      fitContent: true,
    );
    // final st = Stopwatch()..start();
    if (widget.nativeParse) {
      final document = md.Document(
        inlineSyntaxes: [MathSyntax.instance],
        extensionSet: md.ExtensionSet.gitHubWeb,
        encodeHtml: false,
      );
      final lines = const LineSplitter().convert(widget.data);
      nodes = document.parseLines(lines);
    } else {
      nodes = fastParse(widget.data);
    }
    final children = mdBuilder.build(nodes);
    return ListView(
      controller: widget.scrollController,
      children: children,
    );
    // print('${widget.nativeParse ? 'n' : ' '} ${st.elapsed} ${MathBuilder.cache.length} items');
    // if (widget.lockstep) {
    // final children = mdBuilder.build(nodes);
    // return ListView(
    // controller: widget.scrollController,
    // children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)],
    // );
    // } else {
    // return ListView.separated(
    // controller: widget.scrollController,
    // separatorBuilder: (_, __) => const SizedBox(height: 4),
    // itemCount: nodes.length,
    // itemBuilder: (bc, idx) => Column(
    // crossAxisAlignment: CrossAxisAlignment.start,
    // children: mdBuilder.build([nodes[idx]]),
    // ),
    // );
    // }
  }
}

// class RenderMarkdown extends StatelessWidget {
// final List<md.Node> nodes;
// const RenderMarkdown(this.nodes);
// @override
// Widget build(BuildContext context) {
// TODO: implement build
// throw UnimplementedError();
// }
// }

class MarkdownPreview extends StatelessWidget {
  final String expr;

  final double scale;

  /// Disabled by default due to high performance impact
  final bool selectable;
  final bool lockstep;
  final ScrollController? controller;
  const MarkdownPreview(
      {Key? key, required this.expr, this.scale = 1, this.selectable = false, this.controller, this.lockstep = false})
      : super(key: key);

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
        lockstep: lockstep,
        scale: scale,
        style: style,
        scrollController: controller,
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
  final double scale;
  MathBuilder({this.scale = 1});
  static final cache = HashMap<String, List<GreenNode>>();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    final displayMode = element.attributes['display'] == 'true';
    return MathWidget(tex: tex, displayMode: displayMode, scale: scale);
  }
}

class MathWidget extends StatefulWidget {
  final String? tex;
  final bool displayMode;
  final double scale;
  const MathWidget({Key? key, this.tex, this.displayMode = false, this.scale = 1}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _MathWidgetState();
}

class _MathWidgetState extends State<MathWidget> {
  static final cache = HashMap<String, List<GreenNode>>();

  @override
  Widget build(BuildContext context) {
    final tex = widget.tex;
    if (tex == null || tex.isEmpty) return Container();
    List<GreenNode>? ast;
    ParseException? exception;

    try {
      ast = cache[tex] ??= TexParser(tex, TexParserSettings(displayMode: widget.displayMode)).parseExpression();
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
        mathStyle: widget.displayMode ? MathStyle.text : MathStyle.display,
        textScaleFactor: widget.scale,
        onErrorFallback: (e) {
          return Tooltip(message: e.message, child: Text(tex, style: const TextStyle(color: Colors.red)));
        },
      ),
    );
    return Container(alignment: widget.displayMode ? Alignment.center : null, child: child);
  }
}

class MathSyntax extends md.InlineSyntax {
  static final instance = MathSyntax();
  MathSyntax() : super(r'\$(\$?)([^$]+)\$\1');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final elem = md.Element.text('math', match[2]!);
    final textMode = match[1]?.isEmpty ?? true;
    elem.attributes['display'] = textMode ? 'false' : 'true';
    if (textMode) {
      parser.addNode(elem);
    } else {
      parser.addNode(md.Element('p', [elem]));
    }
    return true;
  }
}
