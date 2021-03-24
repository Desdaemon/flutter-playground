import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/markdown.dart' show MathMarkdown;
import '../state/markdown.dart';

/// The logic part of [MathMarkdown], i.e. anything that relates to state, providers
/// and does not participate in widget building.
abstract class IMathMarkdownState extends State<MathMarkdown> {
  RestorableTextEditingController get ctl;
  ScrollController get sc;

  static const scaleStep = 0.1;
  String get untitled;
  String contentkey = '';
  int untitledIdx = 1;
  Characters indent = ''.characters;

  late TextSelection sel;
  late CharacterRange iter;

  final newline = '\n'.characters;

  void upfont() => context.read(scale).state += scaleStep;
  void downfont() => context.read(scale).state -= scaleStep;
  void upindent() => context.read(indents).state++;
  void downindent() {
    if (context.read(indents).state > 0) context.read(indents).state--;
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

  /// Sets the active file to be [path] and populates its [contents].
  void activate(String path, String contents) {
    ctl.value.text = contents;
    context.read(files).activate(path, contents);
  }

  void remove(String file) {
    final contents = context.read(files).remove(file);
    ctl.value.text = contents;
  }

  void create() {
    ctl.value.clear();
    final newpath = '${untitled}_(${untitledIdx++}).md';
    activate(newpath, '');
  }

  Future<void> open() async {
    String contents, path;
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['md', 'txt']);
      if (result == null) return;
      final file = result.files.single;
      path = file.name!;
      contents = String.fromCharCodes(file.bytes!);
    } else {
      final Directory root;
      if (Platform.isAndroid) {
        root = Directory('/storage/emulated/0');
      } else if (Platform.isWindows) {
        root = Directory(r'C:\Users');
      } else if (Platform.isLinux) {
        root = Directory('/home');
      } else if (Platform.isMacOS) {
        root = Directory('/Users');
      } else {
        root = await getApplicationDocumentsDirectory();
      }
      final result = await FilesystemPicker.open(
        context: context,
        rootDirectory: root,
        fsType: FilesystemType.file,
        fileTileSelectMode: FileTileSelectMode.wholeTile,
        allowedExtensions: const ['.md', '.txt'],
        requestPermission: () async {
          if (!(Platform.isAndroid || Platform.isIOS)) return true;
          final status = await Permission.storage.request();
          return status.isGranted;
        },
      );
      if (result == null) return;
      path = result;
      contents = await File(path).readAsString();
    }
    ctl.value.text = contents;
    activate(path, contents);
  }

  Future<void> save() async {
    final contents = ctl.value.text;
    var path = context.read(activePath);
    if (path.startsWith(untitled)) {
      final String? filename = await showDialog(
        context: context,
        builder: (bc) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('File Name', style: Theme.of(bc).textTheme.headline6),
              ),
              TextFormField(
                initialValue: untitled,
                onFieldSubmitted: Navigator.of(bc).pop,
                autofocus: true,
                decoration: const InputDecoration(filled: true, suffixText: '.md'),
                textInputAction: TextInputAction.next,
              )
            ]),
          ),
        ),
      );
      if (filename == null) return;
      var newpath = filename;
      if (kIsWeb || Platform.isIOS) {
        // TODO: Properly handle saving on iOS when I finally have a debugging device
        await FileSaver.instance.saveFile(
          p.basenameWithoutExtension(newpath),
          Uint8List.fromList(contents.codeUnits),
          'md',
          mimeType: MimeType.TEXT,
        );
        return;
      }
      final dir = Platform.isAndroid
          ? await FilePicker.platform.getDirectoryPath()
          : await FilesystemPicker.open(
              context: context, fsType: FilesystemType.folder, rootDirectory: Directory.current);
      if (dir == null) return;
      newpath = p.join(dir, p.basename(p.setExtension(newpath, '.md')));
      activate(newpath, contents);
      context.read(files).remove(path);
      path = newpath;
    }
    await File(path).writeAsString(contents);
  }

  Future<void> _export(String content, [String? key]) async {
    final appdir = await getApplicationSupportDirectory();
    final outpath = '${appdir.path}/${key ?? 'out'}.html';
    // TODO: Find a replacement for String.hashCode
    final file = File(outpath);
    if (key == null || contentkey != key || !(await file.exists())) {
      await file.create();
      contentkey = key ?? content.hashCode.toString();
      final template = await rootBundle.loadString('assets/template.html', cache: !kDebugMode);
      final markdown = md.markdownToHtml(
        content,
        extensionSet: md.ExtensionSet.gitHubWeb,
        inlineSyntaxes: [TaskListSyntax(), md.TextSyntax(r'\\')],
      );
      final output = template
          .replaceFirst('{{ body }}', markdown)
          .replaceFirst('{{ title }}', p.basenameWithoutExtension(context.read(activePath)));
      await file.writeAsString(output);
    }
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      launch('file://$outpath');
    } else {
      OpenFile.open(outpath);
    }
  }

  Future<void> export() async {
    final content = ctl.value.text;
    if (content.isEmpty) return;
    await _export(content);
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
      context.read(indents).state = result;
    }
  }

  Future<void> openCheatsheet() async {
    _export(await rootBundle.loadString('assets/markdown_reference.md', cache: !kDebugMode), 'markdown_reference');
  }

  /// Initializes and/or updates [indent] only if their lengths mismatch.
  /// Returns the current indent size.
  int _setindent() {
    final size = context.read(indents).state;
    if (indent.length != size) {
      indent = List.filled(size, ' ', growable: false).join().characters;
    }
    return size;
  }

  /// Setups for [iter.current] to contain the lines covered by [sel].
  void _setline() {
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
    context.read(files).updateActive(output);
  }

  void doIndent() {
    final nIndents = _setindent();
    _setline();
    final inner = iter.currentCharacters.split(newline).map((e) => indent.followedBy(e).join());
    final lines = inner.length;
    final innerOut = inner.join('\n');
    _updateActive('${iter.stringBefore}$innerOut${iter.stringAfter}', sel.start + nIndents, sel.end + nIndents * lines);
  }

  void doDedent() {
    final nIndents = _setindent();
    _setline();
    int? firstlineback;
    int combinedback = 0;
    final inner = iter.currentCharacters.split(newline).map((line) {
      if (line.startsWith(indent)) {
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
