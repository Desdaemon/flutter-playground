import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_playground/helpers/markdown.dart';
import 'package:flutter_playground/screens/settings.dart';
import 'package:flutter_playground/widgets/markdown/markdown_bottom_sheet.dart';
import 'package:flutter_playground/widgets/markdown/tex_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_io/io.dart';

import '../state/markdown.dart';
import '../widgets/markdown/editor.dart';

class MathMarkdown extends StatefulWidget {
  final String? restorationId;
  const MathMarkdown({Key? key, this.restorationId}) : super(key: key);

  @override
  _MathMarkdownState createState() => _MathMarkdownState();
}

class _MathMarkdownState extends IMathMarkdownState with RestorationMixin {
  static const animDur = Duration(milliseconds: 200);
  static final isMobile = Platform.isIOS || Platform.isAndroid;

  @override
  final ctl = RestorableTextEditingController();
  @override
  final sc = ScrollController();
  @override
  final editorSc = ScrollController();
  @override
  final untitled = 'Untitled';

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    editorSc.addListener(onScroll);
  }

  late final List<KeyHandler> handlers;
  _MathMarkdownState() {
    handlers = [
      PlusMinusHandler(
        plusKey: LogicalKeyboardKey.bracketRight,
        minusKey: LogicalKeyboardKey.bracketLeft,
        ctrl: true,
        onPlus: indent,
        onMinus: dedent,
      ),
      SingleHandler(
        keys: const [LogicalKeyboardKey.keyB],
        ctrl: true,
        onHandle: bold,
      ),
      SingleHandler(
        keys: const [LogicalKeyboardKey.keyI],
        ctrl: true,
        onHandle: italic,
      ),
      SingleHandler(
        keys: const [LogicalKeyboardKey.keyS],
        alt: true,
        onHandle: strikethrough,
      ),
      SingleHandler(
        keys: const [LogicalKeyboardKey.keyM],
        ctrl: true,
        onHandle: math,
      ),
      PlusMinusHandler(
        plusKey: LogicalKeyboardKey.equal,
        minusKey: LogicalKeyboardKey.minus,
        ctrl: true,
        onPlus: increaseFontSize,
        onMinus: decreaseFontSize,
      ),
      SingleHandler(
        keys: const [LogicalKeyboardKey.keyO],
        ctrl: true,
        onHandle: open,
      )
    ];
  }

  Widget get bottomSheet => MarkdownBottomSheet(
        onExport: export,
        onCreate: create,
        onOpen: open,
        onOpenCheatsheet: openCheatsheet,
        onSave: save,
        onRemove: remove,
        onUpfont: increaseFontSize,
        onDownfont: decreaseFontSize,
        onActivate: (val) {
          context.read(pFiles.notifier).focus(val);
          ctl.value.text = context.read(pActiveFile);
        },
      );

  @override
  String? get restorationId => widget.restorationId;

  @override
  Widget build(BuildContext bc) {
    return SafeArea(
      top: false,
      child: Scaffold(
        key: scaffoldKey,
        endDrawer: const Settings(),
        body: Consumer(
          builder: (bc, watch, _) {
            final sm = watch(pScreenMode).state;
            return LayoutBuilder(
              builder: (bc, cons) {
                final vertical = cons.maxWidth < 1000;
                final bottomBar = Material(
                  color: Theme.of(context).bottomAppBarColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => bc.read(pScreenMode).state = sm.next,
                                tooltip: sm.description,
                                icon: AnimatedSwitcher(duration: animDur, child: sm.icon),
                              ),
                              IconButton(icon: const Icon(Icons.format_bold), onPressed: bold, tooltip: 'Bold'),
                              IconButton(icon: const Icon(Icons.format_italic), onPressed: italic, tooltip: 'Italic'),
                              IconButton(
                                icon: const Icon(Icons.format_strikethrough),
                                onPressed: strikethrough,
                                tooltip: 'Strikethrough',
                              ),
                              IconButton(icon: const Icon(Icons.functions), onPressed: math, tooltip: 'Math'),
                              IconButton(
                                icon: const Icon(Icons.format_indent_increase),
                                onPressed: indent,
                                tooltip: 'Indent',
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_indent_decrease),
                                onPressed: dedent,
                                tooltip: 'Dedent',
                              ),
                              Consumer(
                                builder: (bc, watch, _) => Tooltip(
                                  message: 'Spaces',
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: changeIndent,
                                      child: Text(
                                        'Spaces: ${watch(pIndents).state}',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!vertical) Consumer(builder: (_, watch, __) => Text(watch(pTicker).state))
                            ],
                          ),
                        ),
                      ),
                      IconButton(onPressed: showMenu, icon: const Icon(Icons.menu), tooltip: 'Menu'),
                      IconButton(
                        onPressed: scaffoldKey.currentState!.openEndDrawer,
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                );
                final children = <Widget>[
                  if (sm.editing)
                    Expanded(
                      child: Consumer(
                        builder: (bc, watch, _) {
                          return Padding(
                            padding: vertical
                                ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                                : (isMobile
                                    ? const EdgeInsets.fromLTRB(16, 32, 8, 8)
                                    : const EdgeInsets.fromLTRB(16, 16, 8, 8)),
                            child: Editor(
                              scrollController: editorSc,
                              controller: ctl.value,
                              onChange: bc.read(pFiles.notifier).updateActive,
                              fontSize: watch(pFontSize(Theme.of(bc).textTheme.bodyText2!.fontSize!)),
                              fontFamily: 'JetBrains Mono',
                              indent: watch(pIndents).state,
                              noBuiltins: true,
                              handlers: handlers,
                            ),
                          );
                        },
                      ),
                    ),
                  if (sm.previewing && vertical) const Divider(height: 1),
                  if (sm.previewing && !vertical) const VerticalDivider(width: 1),
                  Expanded(
                    flex: sm.previewing ? 1 : 0,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Visibility(
                        visible: sm.previewing,
                        child: Consumer(
                          builder: (bc, watch, _) {
                            final lines = watch(pActiveFile);
                            final lockstep = watch(pLockstep).state;
                            final _scale = watch(pScale).state;
                            return Padding(
                              key: Key(lines),
                              padding: vertical
                                  ? isMobile
                                      ? const EdgeInsets.fromLTRB(16, 32, 16, 8)
                                      : const EdgeInsets.fromLTRB(16, 16, 16, 8)
                                  : isMobile
                                      ? const EdgeInsets.fromLTRB(8, 32, 16, 8)
                                      : const EdgeInsets.fromLTRB(8, 16, 16, 8),
                              child: MarkdownPreview(
                                expr: lines,
                                scale: _scale,
                                controller: sc,
                                lockstep: lockstep,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ];
                return Column(
                  children: [
                    if (vertical)
                      ...children.reversed
                    else
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      ),
                    bottomBar
                  ],
                );
              },
            );
          },
        ),
      ),
    );
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
  void dispose() {
    super.dispose();
    ctl.dispose();
    sc.dispose();
    editorSc.removeListener(onScroll);
    editorSc.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(ctl, 'ctl');
    final expr = context.read(pActiveFile);
    if (expr.isNotEmpty) ctl.value.text = expr;
  }

  void showMenu() {
    if (MediaQuery.of(context).size.width < 1000) {
      showModalBottomSheet(
        enableDrag: true,
        context: context,
        builder: (_) => bottomSheet,
        barrierColor: Colors.transparent,
      );
    } else {
      showDialog(
        context: context,
        builder: buildRightDrawer,
        barrierColor: Colors.transparent,
      );
    }
  }
}
