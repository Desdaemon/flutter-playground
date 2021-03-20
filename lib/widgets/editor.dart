import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'handlers.dart';
export 'handlers.dart';

/// A [TextField] that expands to its parent's size and handles some common
/// hotkeys unless `noBuiltins` is passed, (in order of processing):
///
/// Hotkey|Command|Note
/// :-|:-|:-
/// `Enter`|VS Code's `Enter`|[markdown] changes behavior
/// `Tab`|VS Code's `Tab`
/// `Ctrl` + `Backspace`|Word delete
/// `Ctrl` + `=`|Increase font size|Calls [onFontSizeUp]
/// `Ctrl` + `-`|Decrease font size|Calls [onFontSizeDown]
/// `Ctrl` + `M`|Insert math block|When not selecting
/// Any key in [pairs]|Insert paired item
/// Any key in [pairs]'s value|Move cursor forward|When next to it
class Editor extends StatelessWidget {
  const Editor({
    Key? key,
    required TextEditingController controller,
    this.onChange,
    this.markdown = true,
    this.fontSize,
    this.fontFamily,
    this.handlers,
    this.noBuiltins = false,
    this.indent = 2,
    this.scrollController,
  })  : ctl = controller,
        super(key: key);

  final TextEditingController ctl;
  final void Function(String text)? onChange;

  /// Enables Markdown-specific behavior.
  final bool markdown;
  final double? fontSize;
  final String? fontFamily;

  /// Handlers for the keystrokes. When [noBuiltins] is set to false (by default),
  /// these handlers will take precedence.
  final List<KeyHandler>? handlers;

  /// If true, skips calling [builtins] when handling keystrokes.
  final bool noBuiltins;
  final int indent;
  final ScrollController? scrollController;

  static const pairs = <String, String?>{'(': ')', '[': ']', '{': '}'};

  void updateSelection(int offset) => ctl.selection = TextSelection.collapsed(offset: offset);

  Iterable<KeyHandler> get allHandlers sync* {
    if (handlers != null) yield* handlers!;
    if (noBuiltins) return;
    yield MapHandler(LogicalKeyboardKey.tab, blanks(indent));
    yield const EnterHandler(pairs: pairs);
    yield IndentHandler(indent: indent);
    yield PairRemoverHandler(pairs: pairs);
    if (indent > 1) yield DedentHandler(indent: indent);
    yield const PairLeftHandler(pairs: pairs);
    yield PairRightHandler(pairs: pairs, updateSelection: updateSelection);
    yield MathHandler(updateSelection: updateSelection);
  }

  void setValue(String text, int base, [int? extent]) {
    ctl.value = TextEditingValue(text: text, selection: TextSelection(baseOffset: base, extentOffset: extent ?? base));
    onChange?.call(text);
  }

  bool handleKey(FocusNode _, RawKeyEvent event) {
    final val = ctl.value;
    final sel = val.selection;
    final pre = val.text.substring(0, sel.start);
    final post = val.text.substring(sel.start);
    for (final handler in allHandlers) {
      if (handler.execute(event, sel: sel, pre: pre, post: post, setValue: setValue)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext bc) {
    return FocusScope(
      onKey: handleKey,
      child: TextField(
        maxLines: null,
        scrollController: scrollController,
        expands: true,
        controller: ctl,
        decoration: const InputDecoration.collapsed(hintText: null),
        style: TextStyle(fontFamily: fontFamily, fontSize: fontSize),
        onChanged: onChange,
      ),
    );
  }
}
