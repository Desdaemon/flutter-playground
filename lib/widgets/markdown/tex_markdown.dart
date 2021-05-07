import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MarkdownPreview extends HookWidget {
  const MarkdownPreview(
      {Key? key,
      ScrollController? scrollController,
      required this.expr,
      this.scale = 1,
      this.padding,
      this.selectable = false})
      : sc = scrollController,
        super(key: key);

  final ScrollController? sc;
  final String expr;
  final double scale;
  final EdgeInsets? padding;

  /// Disabled by default due to high performance impact
  final bool selectable;

  /// [Markdown] is buggy so we manually insert a scroll view here and use [MarkdownBody] instead.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return useMemoized(() {
      return SingleChildScrollView(
        controller: sc,
        padding: padding,
        child: MarkdownBody(
          data: expr,
          shrinkWrap: false,
          extensionSet: md.ExtensionSet.gitHubWeb,
          inlineSyntaxes: [MathSyntax()],
          builders: {'math': MathBuilder(scale: scale)},
          checkboxBuilder: (val) =>
              val ? const Icon(Icons.check_box, size: 12) : const Icon(Icons.check_box_outline_blank, size: 12),
          selectable: selectable,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
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
    }, [expr, scale, theme.hashCode]);
  }
}

class MathBuilder extends MarkdownElementBuilder {
  MathBuilder({this.style = MathStyle.display, this.scale = 1});
  final MathStyle style;
  final double scale;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? ts) {
    final tex = element.children!.first.textContent;
    final textMode = element.attributes.containsKey('text');
    final child = MathBlock(tex: tex, scale: scale, style: textMode ? MathStyle.text : MathStyle.display);
    return textMode ? child : Align(child: child);
  }
}

class MathSyntax extends md.InlineSyntax {
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

class MathBlock extends HookWidget {
  final String tex;
  final double scale;
  final MathStyle style;
  const MathBlock({Key? key, required this.tex, this.scale = 1, required this.style}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return useMemoized(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          tex,
          mathStyle: style,
          textScaleFactor: scale,
          onErrorFallback: (ex) => Tooltip(
            message: ex.message,
            child: Text(
              tex,
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
          ),
        ),
      );
    }, [tex, scale, Theme.of(context)]);
  }
}
