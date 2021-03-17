import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MarkdownPreview extends HookWidget {
  const MarkdownPreview({Key? key, this.sc, required this.expr, this.scale = 1, this.padding}) : super(key: key);

  final ScrollController? sc;
  final String expr;
  final double scale;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: sc,
      padding: padding,
      child: useMemoized(() {
        return MarkdownBody(
          shrinkWrap: false,
          data: expr,
          extensionSet: md.ExtensionSet.gitHubWeb,
          inlineSyntaxes: [MathSyntax()],
          builders: {
            'math': MathBuilder(scale: scale),
            'code': CodeBuilder(scale: scale),
          },
          checkboxBuilder: (val) => val ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            blockquoteDecoration: BoxDecoration(color: Theme.of(context).focusColor),
            textScaleFactor: scale,
            blockSpacing: 12 * scale,
            listBullet: TextStyle(fontSize: Theme.of(context).textTheme.bodyText2!.fontSize! * scale),
            code: const TextStyle(fontFamily: 'JetBrains Mono'),
          ),
          onTapLink: (text, href, title) async {
            if (href == null) return;
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
                    )
                  ],
                ),
              );
              if (answer ?? false) launch(href);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$text could not be opened'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).errorColor,
              ));
            }
          },
        );
      }, [expr, scale]),
    );
  }
}

class MathBuilder extends MarkdownElementBuilder {
  MathBuilder({this.style = MathStyle.display, this.scale = 1});
  final MathStyle style;
  final double scale;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    return MemoizedMath(tex: tex, scale: scale);
  }
}

class MathSyntax extends md.InlineSyntax {
  MathSyntax() : super(r'\$\$?([^$]+)(\$?)\$');
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final elem = md.Element.text('math', match[1]!);
    if (match[2]?.isEmpty ?? true) {
      parser.addNode(elem);
    } else {
      parser.addNode(md.Element('p', [elem]));
    }
    return true;
  }
}

class MemoizedMath extends HookWidget {
  final String tex;
  final double scale;
  const MemoizedMath({Key? key, required this.tex, this.scale = 1}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return useMemoized(() {
      return Math.tex(
        tex,
        textScaleFactor: scale,
        onErrorFallback: (_) => Text(
          tex,
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      );
    }, [tex, scale]);
  }
}

class CodeBuilder extends MarkdownElementBuilder {
  CodeBuilder({this.scale = 1});
  final double scale;

  @override
  Widget? visitElementAfter(md.Element el, TextStyle? ts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.white12,
        child: Text(
          el.textContent,
          style: ts!.copyWith(
            fontSize: ts.fontSize! * scale,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
