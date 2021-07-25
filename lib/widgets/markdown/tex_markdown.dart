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
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:yata_flutter/state/markdown.dart';
import 'package:yata_flutter/widgets/markdown/impls/impls.dart';

class CustomMarkdownBody extends StatefulWidget implements MarkdownBuilderDelegate {
  final String data;
  final double scale;
  final MarkdownStyleSheet style;
  final bool nativeParse;
  final void Function(String, String?, String)? onTapLink;

  @override
  State<StatefulWidget> createState() => _CustomMarkdownBodyState();

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
  // Pointer<Slice_CElement> sliceptr = nullptr;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   freeElements(sliceptr);
  // }

  // @override
  // void dispose() {
  //   super.dispose();
  //   // freeing a nullptr is a no-op, so this is OK.
  //   freeElements(sliceptr);
  // }

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
    );
    final List<md.Node> nodes;
    final st = Stopwatch()..start();
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
      // nodes = parseMarkdown(widget.data).map(JSONElement.fromStrOrMap).toList(growable: false);
      // sliceptr = parseMarkdownAst(widget.data.toNativeUtf8().cast<Int8>());
      // nodes = [];
      // for (var i = 0; i < sliceptr.ref.length; ++i) {
      //   final el = nat.Element(sliceptr.ref.ptr.elementAt(i));
      //   nodes.add(el);
      // }
    }
    final t0 = st.elapsed;
    final children = mdBuilder.build(nodes);
    final t1 = st.elapsed - t0;
    print('${widget.nativeParse ? 'n' : ' '} $t0 $t1 ${st.elapsed} ${MathBuilder.cache.length} items');
    return Column(children: children);
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
    final displayMode = element.attributes['display'] == 'true';
    List<GreenNode>? ast;
    ParseException? exception;

    try {
      ast = cache[tex] ??= TexParser(
        tex,
        displayMode ? const TexParserSettings(displayMode: true) : const TexParserSettings(),
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
        mathStyle: displayMode ? MathStyle.text : MathStyle.display,
        textScaleFactor: scale,
        onErrorFallback: (e) {
          return Tooltip(message: e.message, child: Text(tex, style: const TextStyle(color: Colors.red)));
        },
      ),
    );
    return displayMode ? child : Align(child: child);
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
