import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yata_flutter/helpers/utils.dart';

import '../../helpers/handlers.dart';
export '../../helpers/handlers.dart';

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

  /// If true, skips calling [allHandlers] when handling keystrokes.
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
    // yield const PairLeftHandler(pairs: pairs);
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
        expands: true,
        scrollController: scrollController,
        decoration: const InputDecoration.collapsed(hintText: null),
        controller: ctl,
        style: TextStyle(fontFamily: fontFamily, fontSize: fontSize),
        onChanged: onChange,
        inputFormatters: [/* LastKey(),  */ PairAdder()],
      ),
    );
  }
}

class LastKey extends TextInputFormatter {
  /// The signed length of [lastValue], negative if removal.
  static int delta = 0;
  static String lastValue = '';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final old = oldValue.text.length;
    final neo = newValue.text.length;
    delta = neo - old;
    lastValue = delta > 0 ? newValue.text.substring(old) : oldValue.text.substring(neo);
    // print('LastKey(delta: $delta lastValue: $lastValue)');
    return newValue;
  }
}

class PairAdder extends TextInputFormatter {
  static const pairs = {'(': ')', '{': '}', '[': ']'};

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final old = oldValue.text.length;
    final neo = newValue.text.length;
    if (neo - old != 1) {
      // print('oldValue: $oldValue\nnewValue: $newValue');
      return newValue;
    }

    final maybePos = newValue.selection.start - 1;
    final inserted = maybePos < neo ? newValue.text.characters.elementAt(maybePos) : newValue.text.characters.last;
    final pair = pairs[inserted];
    if (pair == null) return newValue;

    final sel = newValue.selection;
    final pre = newValue.text.substring(0, sel.start);
    final inner = newValue.text.substring(sel.start, sel.end);
    final post = newValue.text.substring(sel.end);
    return newValue.copyWith(text: '$pre$inner$pair$post');
  }
}
