import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/markdown.dart' show MathMarkdown;
import '../state/markdown.dart';
import 'markdown/markdown.dart' if (dart.library.io) 'markdown/native.dart' if (dart.library.html) 'markdown/web.dart';

/// The logic part of [MathMarkdown], i.e. anything that relates to state, providers
/// and does not participate in widget building.
abstract class IMathMarkdownState extends State<MathMarkdown> with MarkdownPlatform {
  ScrollController get sc;
  ScrollController get editorSc;

  static const scaleStep = 0.1;
  int untitledIdx = 1;
  Characters _indent = ''.characters;

  late TextSelection sel;
  late CharacterRange iter;

  final newline = '\n'.characters;

  void increaseFontSize() => context.read(pScale).state += scaleStep;
  void decreaseFontSize() => context.read(pScale).state -= scaleStep;
  void increaseIndent() => context.read(pIndents).state++;
  void decreaseIndent() {
    if (context.read(pIndents).state > 0) context.read(pIndents).state--;
  }

  void onScroll() {
    if (context.read(pLockstep).state && sc.hasClients) {
      final pos = sc.position;
      final epos = editorSc.position;
      final range = epos.maxScrollExtent - epos.minScrollExtent;
      final prev = pos.maxScrollExtent - pos.minScrollExtent;
      final ratio = prev / range;
      sc.jumpTo(epos.pixels * ratio);
    }
  }

  /// Sets the active file to be [path] and populates its [contents].
  @override
  void activatePath(String path, String contents) {
    ctl.value.text = contents;
    context.read(pFiles.notifier).activate(path, contents);
  }

  void remove(String file) {
    final contents = context.read(pFiles.notifier).remove(file);
    ctl.value.text = contents;
  }

  void create() {
    ctl.value.clear();
    final _files = context.read(pFiles).files;
    String newpath;
    do {
      newpath = '${untitled}_(${untitledIdx++}).md';
    } while (_files.containsKey(newpath));
    activatePath(newpath, '');
  }

  Future<void> export() async {
    final content = ctl.value.text;
    if (content.isEmpty) return;
    await exportImpl(content);
  }

  Future<void> changeIndent() async {
    final int? result = await showDialog(
      context: context,
      builder: (bc) => SimpleDialog(
        title: const Text('Indent size (in spaces)'),
        children: List.generate(
          8,
          (index) => SimpleDialogOption(
            onPressed: () => Navigator.pop(bc, index + 1),
            child: Text((index + 1).toString()),
          ),
          growable: false,
        ),
      ),
    );
    if (result != null) {
      context.read(pIndents).state = result;
    }
  }

  Future<void> openCheatsheet() async {
    // _export(await rootBundle.loadString('assets/markdown_reference.md', cache: !kDebugMode), 'markdown_reference');
    context.read(pFiles.notifier).activate(
        'markdown_reference.md', await rootBundle.loadString('assets/markdown_reference.md', cache: !kDebugMode));
  }

  /// Initializes and/or updates [_indent] only if their lengths mismatch.
  /// Returns the current indent size.
  int _prepareIndent() {
    final size = context.read(pIndents).state;
    if (_indent.length != size) {
      _indent = List.filled(size, ' ', growable: false).join().characters;
    }
    return size;
  }

  /// Setups for [iter.current] to contain the lines covered by [sel].
  void _prepareLine() {
    sel = ctl.value.selection;
    iter = ctl.value.text.characters.iterator
      ..moveNext(sel.start)
      ..collapseToEnd()
      ..expandNext(sel.isCollapsed ? 0 : sel.end - sel.start)
      ..expandBackUntil(newline)
      ..expandUntil(newline);
  }

  void _updateActive(String output, int start, int end) {
    ctl.value.value = TextEditingValue(
        text: output,
        selection: sel.isNormalized
            ? TextSelection(baseOffset: start, extentOffset: end)
            : TextSelection(baseOffset: end, extentOffset: start));
    context.read(pFiles.notifier).updateActive(output);
  }

  void indent() {
    final nIndents = _prepareIndent();
    _prepareLine();
    final inner = iter.currentCharacters.split(newline).map((e) => _indent.followedBy(e).join());
    final lines = inner.length;
    final innerOut = inner.join('\n');
    _updateActive('${iter.stringBefore}$innerOut${iter.stringAfter}', sel.start + nIndents, sel.end + nIndents * lines);
  }

  void dedent() {
    final nIndents = _prepareIndent();
    _prepareLine();
    int? firstlineback;
    int combinedback = 0;
    final inner = iter.currentCharacters.split(newline).map((line) {
      if (line.startsWith(_indent)) {
        firstlineback ??= -nIndents;
        combinedback -= nIndents;
        return line.skip(nIndents).join();
      } else if (line.startsWith(' '.characters)) {
        firstlineback ??= -1;
        combinedback--;
        return line.skip(1).join();
      } else {
        firstlineback ??= 0;
        return line.join();
      }
    }).join('\n');
    _updateActive('${iter.stringBefore}$inner${iter.stringAfter}', sel.start + firstlineback!, sel.end + combinedback);
  }

  bool wrap(String left, {String? right, bool unwrap = true, bool dryRun = false}) {
    right ??= left;
    sel = ctl.value.selection;
    final txt = ctl.value.text;
    final post = sel.textAfter(txt);
    final mayUnwrap = post.startsWith(right);
    if (unwrap && mayUnwrap) {
      ctl.value.selection = TextSelection.collapsed(offset: sel.end + right.length);
      return true;
    }
    if (dryRun) return mayUnwrap;
    final pre = sel.textBefore(txt);
    final inner = sel.textInside(txt);
    _updateActive('$pre$left$inner$right$post', sel.start + left.length, sel.end + left.length);
    return false;
  }

  void bold() => wrap('**');
  void italic() => wrap('*');
  void strikethrough() => wrap('~~');
  void math() => wrap(r'$');
}
