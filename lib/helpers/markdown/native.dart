import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yata_flutter/screens/markdown.dart';
import 'package:yata_flutter/state/markdown.dart';

mixin MarkdownPlatform on State<MathMarkdown> {
  RestorableTextEditingController get ctl;
  String get untitled;
  void activatePath(String path, String contents);

  Future<void> open() async {
    String contents, path;
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
    ctl.value.text = contents;
    activatePath(path, contents);
  }

  Future<void> exportImpl(String content, [String? key]) async {
    final appdir = await getApplicationSupportDirectory();
    final outpath = '${appdir.path}/${key ?? 'out'}.html';
    final file = File(outpath);
    await file.create();
    final template = await rootBundle.loadString('assets/template.html', cache: !kDebugMode);
    final markdown = md.markdownToHtml(
      content,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [TaskListSyntax(), md.TextSyntax(r'\\')],
    );
    final output = template
        .replaceFirst('{{ body }}', markdown)
        .replaceFirst('{{ title }}', p.basenameWithoutExtension(context.read(pActivePath)));
    await file.writeAsString(output);
    OpenFile.open(outpath);
  }

  Future<void> save() async {
    final contents = ctl.value.text;
    var path = context.read(pActivePath);
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
      if (Platform.isIOS) {
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
      activatePath(newpath, contents);
      context.read(pFiles.notifier).remove(path);
      path = newpath;
    }
    await File(path).writeAsString(contents);
  }
}
