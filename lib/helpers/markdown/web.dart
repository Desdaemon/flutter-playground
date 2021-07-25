import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_playground/screens/markdown.dart';
import 'package:flutter_playground/state/markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

mixin MarkdownPlatform on State<MathMarkdown> {
  RestorableTextEditingController get ctl;
  String get untitled;
  void activatePath(String path, String contents);
  Future<void> exportImpl(String content, [String? key]) async {
    throw UnimplementedError('Sorry, not implemented yet...');
  }

  Future<void> open() async {
    String contents, path;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['md', 'txt']);
    if (result == null) return;
    final file = result.files.single;
    path = file.name;
    contents = String.fromCharCodes(file.bytes!);
    ctl.value.text = contents;
    activatePath(path, contents);
  }

  Future<void> save() async {
    final contents = ctl.value.text;
    final path = context.read(pActivePath);
    String? filename;
    if (path.startsWith(untitled)) {
      filename = await showDialog(
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
    }
    if (filename == null) return;
    await FileSaver.instance.saveFile(
      p.basenameWithoutExtension(filename),
      Uint8List.fromList(contents.codeUnits),
      'md',
      mimeType: MimeType.TEXT,
    );
  }
}
