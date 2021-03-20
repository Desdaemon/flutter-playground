import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TextValueSetter = void Function(String text, int base, [int? extent]);

/// Usually calls `controller.selection=`.
typedef OffsetCallback = void Function(int offset);

String blanks(int length) {
  if (length < 1) return '';
  final bf = StringBuffer();
  for (var i = 0; i < length; i++) {
    bf.writeCharCode(32 /* space */);
  }
  return bf.toString();
}

abstract class KeyHandler {
  const KeyHandler();
  static final newline = '\n'.characters;

  /// The charCode of the character ' ' (space).
  static const int space = 32;

  /// Gets the contents of [pre] up until the first [newline], or if there is none [pre] itself.
  String preThisLine(String pre) {
    final preIter = pre.characters.iteratorAtEnd;
    return preIter.moveBackTo(newline) ? preIter.stringAfter : pre;
  }

  /// Handle an event.
  /// Returns whether the event was handled and should not propagate further.
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue);

  /// Determines whether the handler should intercept this event.
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post);

  /// Returns whether the event was handled and should not propagate further.
  bool execute(
    RawKeyEvent event, {
    required TextSelection sel,
    required String pre,
    required String post,
    required TextValueSetter setValue,
  }) {
    if (qualify(event, sel, pre, post)) return handle(event, sel, pre, post, setValue);
    return false;
  }
}

/// Mimics the behavior of the `Enter` key in VS Code's Markdown editor.
/// - In a list, take the list bullet or cardinal number and insert it into the next line.
/// - If a checkbox is present, it is also carried.
/// - If the line has no content, remove the list bullet/cardinal number and end the list.
///
/// Furthermore, it mimics the common behavior of VS Code's `Enter`:
/// - Indentations
/// - Insert indentation for qualified [pairs]
class EnterHandler extends KeyHandler {
  static final ul = RegExp(r'([->*] )(\[[x ]\] )?');
  static final ol = RegExp(r'([0-9]+)\. ');
  static final newline = '\n'.characters;
  final String indent;

  /// Pairs of characters that often go together.
  final Map<String, String?> pairs;
  const EnterHandler({required this.pairs, this.indent = '  '});

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    final preIter = pre.characters.iteratorAtEnd;
    final preThis = preIter.moveBackTo(newline) ? preIter.stringAfter : pre;
    final trimmed = preThis.trimLeft();
    RegExpMatch? isUl, isOl;
    String? header;
    String? thisheader;
    int? parsed;
    if ((isUl = ul.firstMatch(trimmed)) != null) {
      final headerkind = isUl!.group(1);
      header = headerkind == '> ' || isUl.group(2) == null ? headerkind : '$headerkind[ ] ';
      thisheader = isUl.group(0);
    } else if ((isOl = ol.firstMatch(trimmed)) != null) {
      if ((parsed = int.tryParse(isOl!.group(1)!)) != null) {
        header = '${parsed! + 1}. ';
        thisheader = isOl.group(0);
      }
    }
    final indents = List.filled(indent.allMatches(preThis).length, indent, growable: false).join();
    if (thisheader != null && sel.isCollapsed && preThis.replaceFirst(thisheader, '').isEmpty) {
      final preThisLen = preThis.length;
      final preOut = (pre.characters.iteratorAtEnd..moveBack(preThisLen)).stringBefore;
      setValue('$preOut\n$post', sel.start - preThisLen + 1);
      return true;
    } else if (header == null && pre.isNotEmpty && pairs.containsKey(pre.characters.last)) {
      setValue('$pre\n$indents$indent\n$indents$post', sel.start + 1 + indents.length * 2);
      return true;
    }
    header ??= '';
    final delta = indents.length + 1 + header.length;
    setValue('$pre\n$indents$header$post', sel.baseOffset + delta, sel.extentOffset + delta);
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) =>
      event.isKeyPressed(LogicalKeyboardKey.enter);
}

/// Generic handler for increment/decrement action pairs.
class PlusMinusHandler extends SingleHandler {
  final VoidCallback? onPlus;
  final VoidCallback? onMinus;
  final LogicalKeyboardKey plusKey;
  final LogicalKeyboardKey minusKey;
  PlusMinusHandler({
    required this.plusKey,
    required this.minusKey,
    this.onMinus,
    this.onPlus,
    bool ctrl = false,
    bool shift = false,
    bool alt = false,
    bool meta = false,
  }) : super(ctrl: ctrl, shift: shift, alt: alt, meta: meta, keys: [plusKey, minusKey], every: false);

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    if (event.isKeyPressed(plusKey)) {
      onPlus?.call();
    } else {
      onMinus?.call();
    }
    return true;
  }
}

/// Handles a key combination of `Ctrl`, `Alt`, `Shift`, `Meta` and an arbitrary number of keys.
class SingleHandler extends KeyHandler {
  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool meta;

  /// Whether all keys must match, or any one of them.
  final bool every;
  final List<LogicalKeyboardKey> keys;

  /// Further restricts the conditions under which this handler may be called.
  final bool Function()? mayHandle;
  final VoidCallback? onHandle;
  const SingleHandler({
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
    this.keys = const [],
    this.mayHandle,
    this.onHandle,
    this.every = true,
  });

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    onHandle?.call();
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) =>
      (!ctrl || ctrl && event.isControlPressed) &&
      (!alt || alt && event.isAltPressed) &&
      (!shift || shift && event.isShiftPressed) &&
      (!meta || meta && event.isMetaPressed) &&
      (mayHandle?.call() ?? true) &&
      (every ? keys.every : keys.any)(event.isKeyPressed);
}

class IndentHandler extends KeyHandler {
  final int indent;
  const IndentHandler({this.indent = 2});
  static final newline = '\n'.characters;

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    final preIter = pre.characters.iteratorAtEnd;
    final preThis = preIter.moveBackTo(newline) ? preIter.stringAfter : pre;
    final trimmed = preThis.trimLeft();
    final blanks = preThis.length - trimmed.length;
    final int indents, delta;
    if (event.isKeyPressed(LogicalKeyboardKey.bracketRight)) {
      indents = blanks + indent;
      delta = indent;
    } else {
      final remainder = blanks % indent;
      if (remainder == 0) {
        if (blanks < indent) {
          delta = indents = 0;
        } else {
          indents = blanks - indent;
          delta = -indent;
        }
      } else {
        indents = blanks;
        delta = -remainder;
      }
    }
    final preOut = (pre.characters.iteratorAtEnd..moveBack(preThis.length)).stringBefore;
    final indentOut = List.filled(indents, ' ', growable: false).join();
    setValue('$preOut$indentOut$trimmed$post', sel.baseOffset + delta, sel.extentOffset + delta);
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) =>
      event.isControlPressed &&
      (event.isKeyPressed(LogicalKeyboardKey.bracketLeft) || event.isKeyPressed(LogicalKeyboardKey.bracketRight));
}

/// Handles math syntax a la VS Code's Markdown.
class MathHandler extends KeyHandler {
  final OffsetCallback updateSelection;
  const MathHandler({required this.updateSelection});

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    if (post.startsWith(r'$')) {
      updateSelection(sel.start + 1);
    } else {
      setValue('$pre\$\$$post', sel.start + 1);
    }
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) =>
      sel.isCollapsed && event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyM);
}

class PairLeftHandler extends KeyHandler {
  final Map<String, String?> pairs;
  const PairLeftHandler({required this.pairs});

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    final close = pairs[event.character];
    final range = sel.end - sel.start;
    final inner = post.substring(0, range);
    final postOut = post.substring(range);
    setValue('$pre${event.character}$inner$close$postOut', sel.baseOffset + 1, sel.extentOffset + 1);
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) => pairs.containsKey(event.character);
}

class PairRightHandler extends KeyHandler {
  final Map<String, String?> pairs;
  final OffsetCallback updateSelection;

  const PairRightHandler({required this.pairs, required this.updateSelection});

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    updateSelection(sel.start + 1);
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) =>
      sel.isCollapsed &&
      post.isNotEmpty &&
      post.characters.first == event.character &&
      pairs.containsValue(event.character);
}

/// Maps a single [LogicalKeyboardKey] to a specific input.
/// If [blocking] is set to true (false by default), this handler
/// will consume [key] and disallow subsequent handlers from responding to the same key.
class MapHandler extends KeyHandler {
  final LogicalKeyboardKey key;
  final String input;
  final bool blocking;
  const MapHandler(this.key, this.input, {this.blocking = false});

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    setValue('$pre$input$post', sel.start + input.length);
    return blocking;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) => event.isKeyPressed(key);
}

class PairRemoverHandler extends KeyHandler {
  final Map<String, String?> pairs;
  final reversePair = <String, String?>{};
  PairRemoverHandler({required this.pairs});

  String? keyOf(String value) => reversePair.putIfAbsent(value, () {
        for (final entry in pairs.entries) {
          if (entry.value == value) return entry.key;
        }
      });

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    final postOut = post.substring(1);
    setValue('$pre$postOut', sel.start);
    return true;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) {
    if (!(sel.isCollapsed && event.isKeyPressed(LogicalKeyboardKey.backspace) && post.isNotEmpty)) return false;

    final right = post.characters.first;
    final left = keyOf(right);
    if (left == null) return false;

    return pre.isEmpty || !preThisLine(pre).contains(left);
  }
}

class DedentHandler extends KeyHandler {
  /// The amount of spaces per indent.
  /// Must be larger than or equal to 2.
  final int indent;
  const DedentHandler({required int indent})
      : assert(indent > 1, 'It might be a mistake to depend on DedentHandler for indent sizes smaller than 2.'),
        indent = indent - 1;

  @override
  bool handle(RawKeyEvent event, TextSelection sel, String pre, String post, TextValueSetter setValue) {
    final preIter = pre.characters.iteratorAtEnd;
    if (preIter.moveBack(indent) &&
        preIter.current == ' ' &&
        preIter.utf16CodeUnits.every((el) => el == KeyHandler.space)) {
      setValue('${preIter.stringBefore}$post', sel.start - indent);
    }
    return false;
  }

  @override
  bool qualify(RawKeyEvent event, TextSelection sel, String pre, String post) {
    return !event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.backspace);
  }
}
