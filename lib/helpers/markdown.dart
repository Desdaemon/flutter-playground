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
import 'package:yata_flutter/screens/markdown.dart' show MathMarkdown;

import '../state/markdown.dart';

/// The logic part of [MathMarkdown], i.e. anything that relates to state, providers
/// and does not participate in widget building.
abstract class IMathMarkdownState extends State<MathMarkdown> {
  RestorableTextEditingController get ctl;
  ScrollController get sc;
  static const scaleStep = 0.1;
  String get untitled;
  int untitledIdx = 1;

  void upfont() => context.read(scale).state += scaleStep;
  void downfont() => context.read(scale).state -= scaleStep;
  void indent() => context.read(indents).state++;
  void dedent() {
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
  void setFile(String path, [String? contents]) {
    final _contents = contents ?? context.read(files.state)[path] ?? '';
    ctl.value.text = _contents;
    context.read(activePath).state = path;
    if (contents == null) context.read(files)[path] = _contents;
  }

  void delete(String file) {
    context.read(files).remove(file);
    final list = context.read(fileList);
    if (list.isEmpty) {
      context.read(activePath).state = untitled;
      ctl.value.clear();
    } else {
      context.read(activePath).state = list.last;
    }
  }

  void create() {
    ctl.value.clear();
    final newpath = '${untitled}_(${untitledIdx++}).md';
    setFile(newpath, '');
  }

  Future<void> open() async {
    String contents, path;
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['md', 'txt']);
      if (result == null) return;
      final file = result.files.single;
      path = file.path ?? file.name!;
      contents = kIsWeb ? String.fromCharCodes(result.files.single.bytes!) : await File(path).readAsString();
    } else {
      // Linux
      final result = await FilesystemPicker.open(
        context: context,
        rootDirectory: Directory.current,
        fileTileSelectMode: FileTileSelectMode.wholeTile,
      );
      if (result == null) return;
      path = result;
      contents = await File(path).readAsString();
    }
    ctl.value.text = contents;
    setFile(path, contents);
  }

  Future<void> save() async {
    var path = context.read(activePath).state;
    final contents = Uint8List.fromList(ctl.value.text.codeUnits);
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
                onFieldSubmitted: (val) => Navigator.pop(bc, val),
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
        await FileSaver.instance.saveFile(p.basenameWithoutExtension(newpath), contents, 'md', mimeType: MimeType.TEXT);
        return;
      }
      final dir = Platform.isAndroid
          ? await FilePicker.platform.getDirectoryPath()
          : await FilesystemPicker.open(
              context: context,
              fsType: FilesystemType.folder,
              rootDirectory: Directory.current,
            );
      if (dir == null) return;
      newpath = p.join(dir, p.basename(p.setExtension(newpath, '.md')));
      setFile(newpath, ctl.value.text);
      context.read(files).remove(path);
      path = newpath;
    }
    await File(path).writeAsBytes(contents, flush: true);
  }

  Future<void> export() async {
    final content = ctl.value.text;
    if (content.isEmpty) return;

    final template = await rootBundle.loadString('assets/template.html', cache: !kDebugMode);
    final appdir = await getApplicationSupportDirectory();
    final outpath = '${appdir.path}/out.html';
    final file = File(outpath);
    await file.create();
    final markdown =
        md.markdownToHtml(content, extensionSet: md.ExtensionSet.gitHubWeb, inlineSyntaxes: [TaskListSyntax()]);
    await file.writeAsString(template
        .replaceFirst('{{ body }}', markdown)
        .replaceFirst('{{ title }}', p.basenameWithoutExtension(context.read(activePath).state)));
    OpenFile.open(outpath);
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
    final contents = await rootBundle.loadString('assets/markdown_reference.md');
    setFile('markdown_reference.md', contents);
    context.read(screenMode).state = ScreenMode.preview;
  }
}
