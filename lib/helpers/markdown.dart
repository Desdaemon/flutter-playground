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

import '../screens/markdown.dart' show MathMarkdown;
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
    activate(path, contents);
  }

  Future<void> save() async {
    assert(ctl.value.text == context.read(activeFile), 'Controller text desynced with store');
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
              context: context,
              fsType: FilesystemType.folder,
              rootDirectory: Directory.current,
            );
      if (dir == null) return;
      newpath = p.join(dir, p.basename(p.setExtension(newpath, '.md')));
      activate(newpath, contents);
      context.read(files).remove(path);
      path = newpath;
    }
    await File(path).writeAsString(contents);
  }

  Future<void> export() async {
    final content = ctl.value.text;
    if (content.isEmpty) return;

    final template = await rootBundle.loadString('assets/template.html', cache: !kDebugMode);
    final appdir = await getApplicationSupportDirectory();
    final outpath = '${appdir.path}/out.html';
    final file = File(outpath);
    await file.create();
    final markdown = md.markdownToHtml(
      content,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [TaskListSyntax(), md.TextSyntax(r'\\')],
    );
    final output = template
        .replaceFirst('{{ body }}', markdown)
        .replaceFirst('{{ title }}', p.basenameWithoutExtension(context.read(activePath)));
    await file.writeAsString(output);
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      launch('file://$outpath');
    } else {
      OpenFile.open(outpath);
    }
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
    activate('markdown_reference.md', contents);
    context.read(screenMode).state = ScreenMode.preview;
  }
}
