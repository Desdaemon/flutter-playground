import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yata_flutter/main.dart';

import '../widgets/tex_markdown.dart';

final expr = StateProvider<String?>((_) => null);
final screenMode = StateProvider((_) => ScreenMode.sbs);
final lockstep = StateProvider((_) => true);
final scale = StateProvider((_) => 1.0);

/// Scalable fontsize.
final fontsize = Provider.family((ref, double size) => ref.watch(scale).state * size);

enum ScreenMode { edit, preview, sbs }

extension ScreenModeX on ScreenMode {
  ScreenMode get next {
    final idx = ScreenMode.values.indexOf(this);
    return ScreenMode.values[(idx + 1) % 3];
  }

  bool get editing => this == ScreenMode.edit || this == ScreenMode.sbs;
  bool get previewing => this == ScreenMode.preview || this == ScreenMode.sbs;
  Icon get icon {
    switch (this) {
      case ScreenMode.edit:
        return const Icon(Icons.edit, key: ValueKey('edit'));
      case ScreenMode.preview:
        return const Icon(
          Icons.visibility,
          key: ValueKey('preview'),
        );
      case ScreenMode.sbs:
        return const Icon(
          Icons.vertical_split,
          key: ValueKey('sbs'),
        );
    }
  }

  String get description {
    switch (this) {
      case ScreenMode.edit:
        return 'Edit';
      case ScreenMode.preview:
        return 'Preview';
      case ScreenMode.sbs:
        return 'Side-by-side';
    }
  }
}

class MathMarkdown extends StatefulWidget {
  const MathMarkdown({Key? key, this.restorationId}) : super(key: key);
  final String? restorationId;

  @override
  _MathMarkdownState createState() => _MathMarkdownState();
}

class _MathMarkdownState extends State<MathMarkdown> with RestorationMixin {
  static const sIndent = '  ';
  static const blocks = <String, String?>{"(": ")", "[": "]", "{": "}"};
  static final newline = '\n'.characters;
  static final letter = RegExp(r'\w');
  static final ul = RegExp(r'([-*] )(\[[x ]\] )?');
  static final ol = RegExp(r'([0-9]+)\. ');
  static const animDur = Duration(milliseconds: 200);

  final ctl = RestorableTextEditingController();
  final sc = ScrollController();

  bool mathMode = false;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/markdown_reference.md').then((value) => setState(() {
          ctl.value.text = value;
        }));
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(ctl, 'ctl');
  }

  @override
  void dispose() {
    ctl.dispose();
    sc.dispose();
    super.dispose();
  }

  void setValue(String text, int curpos) {
    ctl.value.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: curpos));
    context.read(expr).state = text;
  }

  bool handleKey(FocusNode fn, RawKeyEvent event) {
    final val = ctl.value;
    final sel = val.selection;
    final pre = val.text.substring(0, sel.start);
    final post = val.text.substring(sel.end);
    final ctrl = event.isControlPressed;

    if (ctrl && event.isKeyPressed(LogicalKeyboardKey.backspace)) {
      // Ctrl + Backspace
      if (sel.isCollapsed) {
        final iter = pre.characters.iteratorAtEnd..moveBack();
        while (letter.hasMatch(iter.current)) {
          iter.moveBack();
        }
        if (iter.stringAfterLength > 2) iter.moveNext();
        final output = iter.stringBefore;
        setValue('$output$post', output.length);
      } else {
        setValue('$pre$post', sel.start);
      }
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
      // Tab
      setValue('$pre$sIndent$post', sel.start + sIndent.length);
      return true;
    } else if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      // Enter
      final preIter = pre.characters.iteratorAtEnd;
      final preThis = preIter.moveBackTo(newline) ? preIter.stringAfter : pre;
      final trimmed = preThis.trimLeft();
      RegExpMatch? isUl, isOl;
      String? header, thisheader;
      int? parsed;
      if ((isUl = ul.firstMatch(trimmed)) != null) {
        final headerkind = isUl!.group(1);
        header = isUl.group(2) == null ? headerkind : '$headerkind[ ] ';
        thisheader = isUl.group(0);
      } else if ((isOl = ol.firstMatch(trimmed)) != null) {
        if ((parsed = int.tryParse(isOl!.group(1)!)) != null) {
          header = '${parsed! + 1}. ';
          thisheader = isOl.group(0);
        }
      }

      if (thisheader != null && preThis.replaceFirst(thisheader, '').isEmpty) {
        final preOut = (pre.characters.iteratorAtEnd..moveBack(preThis.length)).stringBefore;
        setValue('$preOut\n$post', preOut.length + 1);
        return true;
      } else if (header == null && blocks.containsKey(pre.characters.last)) {
        setValue('$pre\n$sIndent\n$post', sel.start + 1 + sIndent.length);
        return true;
      }

      header ??= '';
      final indents = List.filled(sIndent.allMatches(preThis).length, sIndent).join();
      setValue('$pre\n$indents$header$post', sel.start + indents.length + 1 + header.length);
      return true;
    } else if (ctrl && (event.isKeyPressed(LogicalKeyboardKey.equal) || event.isKeyPressed(LogicalKeyboardKey.minus))) {
      if (event.isKeyPressed(LogicalKeyboardKey.equal)) {
        fontSizeUp();
      } else {
        fontSizeDown();
      }
      return true;
    } else if (ctrl && event.isKeyPressed(LogicalKeyboardKey.keyM)) {
      if (!mathMode) {
        setValue('$pre\$\$$post', sel.start + 1);
        mathMode = true;
      } else if (post.startsWith(r'$')) {
        ctl.value.selection = TextSelection.collapsed(offset: sel.end + 1);
        mathMode = false;
      }
    } else if (blocks.containsKey(event.character)) {
      // A character in blocks
      final close = blocks[event.character]!;
      setValue('$pre${event.character}$close$post', sel.start + 1);
      return true;
    } else if (blocks.containsValue(event.character) && post.characters.first == event.character) {
      ctl.value.selection = TextSelection.collapsed(offset: sel.start + 1);
      return true;
    }
    return false;
  }

  bool handleScroll(ScrollNotification noti) {
    if (context.read(lockstep).state && sc.hasClients) {
      final m = noti.metrics;
      final pos = sc.position;
      final range = m.maxScrollExtent - m.minScrollExtent;
      final prevRange = pos.maxScrollExtent - pos.minScrollExtent;
      final ratio = prevRange / range;
      sc.jumpTo(m.pixels * ratio);
    }
    return true;
  }

  void fontSizeUp() => context.read(scale).state += 0.1;
  void fontSizeDown() => context.read(scale).state -= 0.1;

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
      bottomNavigationBar: Consumer(
        builder: (bc, watch, _) {
          final sm = watch(screenMode).state;
          final ls = watch(lockstep).state;
          final dark = Theme.of(bc).brightness == Brightness.dark;
          return Material(
            elevation: 10,
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
              IconButton(icon: const Icon(Icons.add), onPressed: fontSizeUp, tooltip: 'Increase Font Size'),
              IconButton(icon: const Icon(Icons.remove), onPressed: fontSizeDown, tooltip: 'Decrease Font Size'),
              Text('${watch(scale).state.toStringAsFixed(1)}x'),
              const Spacer(),
              IconButton(
                icon: dark ? const Icon(Icons.brightness_2) : const Icon(Icons.brightness_7),
                tooltip: 'Toggle Dark Theme',
                onPressed: () => Navigator.of(bc).pushReplacement(
                  MaterialPageRoute(builder: (_) => MyApp(dark: !dark)),
                ),
              )
            ]),
          );
        },
      ),
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
                    child: FocusScope(
                      onKey: handleKey,
                      child: Consumer(
                        builder: (bc, watch, _) => TextField(
                          maxLines: null,
                          expands: true,
                          controller: ctl.value,
                          decoration: const InputDecoration.collapsed(hintText: null),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: watch(fontsize(Theme.of(bc).textTheme.bodyText2!.fontSize!)),
                          ),
                          onChanged: (val) => bc.read(expr).state = val,
                        ),
                      ),
                    ),
                  ),
                ),
              if (sm.previewing && vertical) const Divider(height: 1),
              if (sm.previewing && !vertical) const VerticalDivider(width: 1),
              // A caching technique: Flexible as top-level child,
              // Visibility with maintainState set to true.
              Flexible(
                flex: sm.previewing ? 1 : 0,
                fit: FlexFit.tight,
                child: Visibility(
                  visible: sm.previewing,
                  maintainState: true,
                  child: Scrollbar(
                    child: Consumer(
                      builder: (bc, watch, __) {
                        final ls = watch(lockstep).state;
                        return MarkdownPreview(
                          sc: sc,
                          padding: vertical
                              ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                              : const EdgeInsets.fromLTRB(8, 16, 16, 16),
                          // only listen for keystrokes when in lockstep, reduces the amount of updates
                          expr: (ls ? watch(expr).state : bc.read(expr).state) ?? ctl.value.text,
                          scale: watch(scale).state,
                        );
                      },
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
