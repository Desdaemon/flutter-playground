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
      onNew: create,
      onOpen: open,
      onOpenCheatsheet: openCheatsheet,
      onSave: save,
      onDelete: remove,
      onSetActive: (val) {
        context.read(files).focus(val);
        ctl.value.text = context.read(activeFile);
      });

  /// Makes [path] the active file and sets its [contents].
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
      alignment: Alignment.centerRight,
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
    return Scaffold(
      floatingActionButton: Consumer(
        builder: (bc, watch, _) {
          final sm = watch(screenMode).state;
          return FloatingActionButton(
            onPressed: () => bc.read(screenMode).state = sm.next,
            tooltip: sm.description,
            child: AnimatedSwitcher(duration: animDur, child: sm.icon),
          );
        },
      ),
      bottomNavigationBar: Consumer(builder: (bc, watch, _) {
        final sm = watch(screenMode).state;
        final ls = watch(lockstep).state;
        return BottomAppBar(
          child: Row(children: [
            AnimatedSwitcher(
              duration: animDur,
              transitionBuilder: (child, anim) => SizeTransition(sizeFactor: anim, child: child),
              child: Visibility(
                visible: sm == ScreenMode.sbs,
                key: ValueKey(sm.hashCode + ls.hashCode),
                child: IconButton(
                  icon: ls ? const Icon(Icons.lock) : const Icon(Icons.lock_open),
                  onPressed: () => bc.read(lockstep).state = !ls,
                  tooltip: 'Lockstep',
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: upfont, tooltip: 'Increase Font Size'),
            IconButton(icon: const Icon(Icons.remove), onPressed: downfont, tooltip: 'Decrease Font Size'),
            const Spacer(),
            Tooltip(
              message: 'Indent',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: changeIndent,
                  child: Row(children: [
                    const Icon(Icons.format_indent_increase),
                    Text(watch(indents).state.toString()),
                  ]),
                ),
              ),
            ),
            IconButton(onPressed: showMenu, icon: const Icon(Icons.menu), tooltip: 'Menu'),
          ]),
        );
      }),
      body: SafeArea(
        child: Consumer(builder: (bc, watch, _) {
          final sm = watch(screenMode).state;
          return LayoutBuilder(builder: (bc, cons) {
            final vertical = cons.maxWidth < 1000;
            final children = [
              if (sm.editing)
                Expanded(
                  child: Scrollbar(
                    notificationPredicate: handleScroll,
                    child: Padding(
                      padding: vertical
                          ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
                          : const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Consumer(builder: (bc, watch, _) {
                        final indent = watch(indents).state;
                        return Editor(
                          key: ValueKey(indent),
                          scrollController: editorSc,
                          controller: ctl.value,
                          onChange: bc.read(files).updateActive,
                          fontSize: watch(fontsize(Theme.of(bc).textTheme.bodyText2!.fontSize!)),
                          fontFamily: 'JetBrains Mono',
                          indent: indent,
                          handlers: [
                            PlusMinusHandler(
                              onMinus: downfont,
                              onPlus: upfont,
                              ctrl: true,
                              plusKey: LogicalKeyboardKey.equal,
                              minusKey: LogicalKeyboardKey.minus,
                            ),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyO], ctrl: true, onHandle: open)
                          ],
                        );
                      }),
                    ),
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
                        return MarkdownPreview(
                          sc: sc,
                          padding: vertical
                              ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                              : const EdgeInsets.fromLTRB(8, 16, 16, 16),
                          expr: watch(activeFile),
                          scale: watch(scale).state,
                        );
                      }),
                    ),
                  ),
                ),
              )
            ];
            return vertical
                ? Column(children: children.reversed.toList())
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
          });
        }),
      ),
    );
  }
}
