// import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yata_flutter/helpers/markdown.dart';
import 'package:yata_flutter/widgets/markdown/markdown_bottom_sheet.dart';

import '../state/markdown.dart';
import '../widgets/markdown/editor.dart';
import '../widgets/markdown/tex_markdown.dart';

class MathMarkdown extends StatefulWidget {
  const MathMarkdown({Key? key, this.restorationId}) : super(key: key);
  final String? restorationId;

  @override
  _MathMarkdownState createState() => _MathMarkdownState();
}

class _MathMarkdownState extends IMathMarkdownState with RestorationMixin {
  static const animDur = Duration(milliseconds: 200);

  @override
  final ctl = RestorableTextEditingController();
  @override
  final sc = ScrollController();
  final editorSc = ScrollController();
  @override
  final untitled = 'Untitled';

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(ctl, 'ctl');
    final expr = context.read(activeFile);
    if (expr.isNotEmpty) ctl.value.text = expr;
  }

  @override
  void dispose() {
    ctl.dispose();
    sc.dispose();
    editorSc.dispose();
    super.dispose();
  }

  Widget get bottomSheet => MarkdownBottomSheet(
      onExport: export,
      onCreate: create,
      onOpen: open,
      onOpenCheatsheet: openCheatsheet,
      onSave: save,
      onRemove: remove,
      onUpfont: upfont,
      onDownfont: downfont,
      onActivate: (val) {
        context.read(files).focus(val);
        ctl.value.text = context.read(activeFile);
      });

  void showMenu() {
    if (MediaQuery.of(context).size.width < 1000) {
      showModalBottomSheet(
        enableDrag: true,
        context: context,
        builder: (_) => bottomSheet,
        barrierColor: Colors.transparent,
      );
    } else {
      showDialog(context: context, builder: buildRightDrawer, barrierColor: Colors.transparent);
    }
  }

  Widget buildRightDrawer(BuildContext context) {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(16),
      child: TweenAnimationBuilder(
        tween: Tween(begin: 30.0, end: 300.0),
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 200),
        builder: (bc, double width, child) => SizedBox(width: width, child: child),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          child: bottomSheet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext bc) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: Consumer(builder: (bc, watch, _) {
          final sm = watch(screenMode).state;
          return LayoutBuilder(builder: (bc, cons) {
            final vertical = cons.maxWidth < 1000;
            final bottomBar = Material(
              color: Theme.of(context).bottomAppBarColor,
              child: Row(children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      IconButton(
                        onPressed: () => bc.read(screenMode).state = sm.next,
                        tooltip: sm.description,
                        icon: AnimatedSwitcher(duration: animDur, child: sm.icon),
                      ),
                      Consumer(builder: (bc, watch, _) {
                        final state = watch(nativeParsing).state;
                        return IconButton(
                          onPressed: () {
                            bc.read(nativeParsing).state = !state;
                          },
                          icon: watch(nativeParsing).state ? const Icon(Icons.timelapse) : const Icon(Icons.speed),
                        );
                      }),
                      IconButton(icon: const Icon(Icons.format_bold), onPressed: bold, tooltip: 'Bold'),
                      IconButton(icon: const Icon(Icons.format_italic), onPressed: italic, tooltip: 'Italic'),
                      IconButton(
                          icon: const Icon(Icons.format_strikethrough),
                          onPressed: strikethrough,
                          tooltip: 'Strikethrough'),
                      IconButton(icon: const Icon(Icons.functions), onPressed: math, tooltip: 'Math'),
                      IconButton(
                          icon: const Icon(Icons.format_indent_increase), onPressed: doIndent, tooltip: 'Indent'),
                      IconButton(
                          icon: const Icon(Icons.format_indent_decrease), onPressed: doDedent, tooltip: 'Dedent'),
                      Consumer(
                        builder: (bc, watch, _) => Tooltip(
                          message: 'Spaces',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(onTap: changeIndent, child: Text('Spaces: ${watch(indents).state}')),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                IconButton(onPressed: showMenu, icon: const Icon(Icons.menu), tooltip: 'Menu'),
              ]),
            );
            final children = <Widget>[
              if (sm.editing)
                Expanded(
                  child: Scrollbar(
                    notificationPredicate: handleScroll,
                    child: Consumer(builder: (bc, watch, _) {
                      final indent = watch(indents).state;
                      return Padding(
                        padding: vertical
                            ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                            : (Platform.isAndroid
                                ? const EdgeInsets.fromLTRB(16, 32, 8, 8)
                                : const EdgeInsets.fromLTRB(16, 16, 8, 8)),
                        child: Editor(
                          scrollController: editorSc,
                          controller: ctl.value,
                          onChange: bc.read(files).updateActive,
                          fontSize: watch(fontsize(Theme.of(bc).textTheme.bodyText2!.fontSize!)),
                          fontFamily: 'JetBrains Mono',
                          indent: indent,
                          noBuiltins: true,
                          handlers: [
                            PlusMinusHandler(
                              plusKey: LogicalKeyboardKey.bracketRight,
                              minusKey: LogicalKeyboardKey.bracketLeft,
                              ctrl: true,
                              onPlus: doIndent,
                              onMinus: doDedent,
                            ),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyB], ctrl: true, onHandle: bold),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyI], ctrl: true, onHandle: italic),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyS], alt: true, onHandle: strikethrough),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyM], ctrl: true, onHandle: math),
                            PlusMinusHandler(
                              plusKey: LogicalKeyboardKey.equal,
                              minusKey: LogicalKeyboardKey.minus,
                              ctrl: true,
                              onPlus: upfont,
                              onMinus: downfont,
                            ),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyO], ctrl: true, onHandle: open)
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              if (sm.previewing && vertical) const Divider(height: 1),
              if (sm.previewing && !vertical) const VerticalDivider(width: 1),
              // A caching technique: Flexible as top-level child,
              // Visibility with maintainState set to true.
              Expanded(
                flex: sm.previewing ? 1 : 0,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Visibility(
                    visible: sm.previewing,
                    maintainState: true,
                    child: Scrollbar(
                      child: Consumer(builder: (bc, watch, __) {
                        final lines = watch(activeFile);
                        final _scale = watch(scale).state;
                        // Q: Most peculiar: Without changing any behavior, swapping a SingleChildScrollWidget
                        // for a ListView with a single child yields massive speed increases! What gives?
                        // A: From the official documentation:
                        // "When you have a list of children and do not require cross-axis shrink-wrapping behavior,
                        // for example a scrolling list that is always the width of the screen, consider ListView,
                        // which is vastly more efficient that a SingleChildScrollView containing a ListBody
                        // or Column with many children."
                        return ListView(
                            padding: vertical
                                ? Platform.isAndroid
                                    ? const EdgeInsets.fromLTRB(16, 32, 16, 8)
                                    : const EdgeInsets.fromLTRB(16, 16, 16, 8)
                                : Platform.isAndroid
                                    ? const EdgeInsets.fromLTRB(8, 32, 16, 8)
                                    : const EdgeInsets.fromLTRB(8, 16, 16, 8),
                            controller: sc,
                            children: [MarkdownPreview(expr: lines, scale: _scale)]);
                      }),
                    ),
                  ),
                ),
              ),
            ];
            return Column(children: [
              if (vertical)
                ...children.reversed
              else
                Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
              bottomBar
            ]);
          });
        }),
      ),
    );
  }
}
