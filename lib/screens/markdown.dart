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

import '../state/dark.dart';
import '../state/markdown.dart';
import '../utils.dart';
import '../widgets/editor.dart';
import '../widgets/tex_markdown.dart';

class MathMarkdown extends StatefulWidget {
  const MathMarkdown({Key? key, this.restorationId}) : super(key: key);
  final String? restorationId;

  @override
  _MathMarkdownState createState() => _MathMarkdownState();
}

class _MathMarkdownState extends State<MathMarkdown> with RestorationMixin {
  static const animDur = Duration(milliseconds: 200);
  static const scaleStep = 0.1;

  final ctl = RestorableTextEditingController();
  final sc = ScrollController();
  final editorSc = ScrollController();
  static const untitled = 'Untitled';
  int untitledIdx = 1;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(ctl, 'ctl');
    final expr = context.read(activeFile);
    if (expr.isNotEmpty) ctl.value.text = expr;
  }

  @override
  void dispose() {
    ctl.dispose();
    sc.dispose();
    editorSc.dispose();
    super.dispose();
  }

  void fontSizeUp() => context.read(scale).state += scaleStep;
  void fontSizeDown() => context.read(scale).state -= scaleStep;
  void indentUp() => context.read(indents).state++;
  void indentDown() {
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

  void newFile() {
    ctl.value.clear();
    final newpath = '${untitled}_(${untitledIdx++}).md';
    context.read(files)[newpath] = '';
    context.read(activePath).state = newpath;
  }

  Future<void> openFile() async {
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
    context.read(files)[path] = contents;
    context.read(activePath).state = path;
  }

  Future<void> saveFile(BuildContext bc) async {
    var path = bc.read(activePath).state;
    final contents = Uint8List.fromList(bc.read(activeFile).codeUnits);
    if (path.startsWith(untitled)) {
      final String? filename = await showDialog(
        context: bc,
        builder: (bc) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('File Name', style: Theme.of(bc).textTheme.headline6),
              ),
              TextFormField(
                initialValue: 'Unknown',
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
      path = filename;
      if (kIsWeb || Platform.isIOS) {
        // TODO: Properly handle saving on iOS when I finally have a debugging device
        await FileSaver.instance.saveFile(p.basenameWithoutExtension(path), contents, 'md', mimeType: MimeType.TEXT);
        return;
      }
      String? dir;
      if (Platform.isAndroid) {
        dir = await FilePicker.platform.getDirectoryPath();
      } else {
        // Linux, Windows, MacOS
        dir = await FilesystemPicker.open(context: bc, rootDirectory: await getApplicationDocumentsDirectory());
      }
      if (dir == null) return;
      path = p.join(dir, p.basename(p.setExtension(path, '.md')));
    }
    await File(path).writeAsBytes(contents, flush: true);
  }

  Future<void> export() async {
    final content = context.read(activeFile);
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
          7,
          (index) => SimpleDialogOption(
            onPressed: () => Navigator.pop(bc, index + 1),
            child: Text(index.toString()),
          ),
          growable: false,
        ),
      ),
    );
    if (result != null) {
      context.read(indents).state = result;
    }
  }

  Widget buildBottomSheet(BuildContext bc) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Consumer(
        builder: (bc, watch, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Text(shortenPath(watch(activePath).state), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
      const Divider(),
      Row(children: [
        IconButton(icon: const Icon(Icons.insert_drive_file_outlined), tooltip: 'New', onPressed: newFile),
        IconButton(icon: const Icon(Icons.folder_open), tooltip: 'Open', onPressed: openFile),
        IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: () => saveFile(bc)),
        IconButton(icon: const Icon(Icons.print), onPressed: export, tooltip: 'Export to HTML'),
        const Spacer(),
        IconButton(
          onPressed: () async {
            final contents = await rootBundle.loadString('assets/markdown_reference.md');
            bc.read(files)['markdown_reference'] = contents;
            bc.read(activePath).state = 'markdown_reference';
            bc.read(screenMode).state = ScreenMode.preview;
          },
          icon: const Icon(Icons.help),
          tooltip: 'Cheat Sheet',
        ),
        Consumer(
          builder: (bc, watch, _) => IconButton(
            onPressed: bc.read(darkTheme).next,
            icon: iconOf(watch(darkTheme.state)),
          ),
        ),
      ]),
      const Divider(),
      Consumer(
        builder: (bc, watch, _) => Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Files (${watch(fileList).length})', style: Theme.of(bc).textTheme.caption),
        ),
      ),
      Flexible(
        child: Scrollbar(
          child: Consumer(builder: (bc, watch, _) {
            final list = watch(fileList);
            final active = watch(activePath).state;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (bc, i) {
                final file = list.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(p.basename(file)),
                  selected: active == file,
                  trailing: IconButton(
                    onPressed: () {
                      bc.read(files).remove(file);
                      final list = bc.read(fileList);
                      if (list.isEmpty) {
                        bc.read(activePath).state = untitled;
                        ctl.value.clear();
                      } else {
                        bc.read(activePath).state = list.last;
                      }
                    },
                    icon: const Icon(Icons.cancel),
                  ),
                  onTap: () {
                    ctl.value.text = bc.read(files.state)[file]!;
                    bc.read(activePath).state = file;
                  },
                );
              },
            );
          }),
        ),
      ),
      const SizedBox(height: 16)
    ]);
  }

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
      bottomNavigationBar: Consumer(builder: (bc, watch, _) {
        final sm = watch(screenMode).state;
        final ls = watch(lockstep).state;
        return BottomAppBar(
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
            const Spacer(),
            Tooltip(
              message: 'Indent',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: changeIndent,
                  child: Row(children: [
                    const Icon(Icons.format_indent_increase),
                    Text(watch(indents).state.toString()),
                  ]),
                ),
              ),
            ),
            IconButton(
              onPressed: () => showModalBottomSheet(enableDrag: true, context: bc, builder: buildBottomSheet),
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
            )
          ]),
        );
      }),
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
                    child: Padding(
                      padding: vertical
                          ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
                          : const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      child: Consumer(builder: (bc, watch, _) {
                        final indent = watch(indents).state;
                        return Editor(
                          key: ValueKey(indent),
                          scrollController: editorSc,
                          controller: ctl.value,
                          onChange: (val) => setFileContent(bc, val),
                          fontSize: watch(fontsize(Theme.of(bc).textTheme.bodyText2!.fontSize!)),
                          fontFamily: 'JetBrains Mono',
                          indent: indent,
                          handlers: [
                            PlusMinusHandler(
                              onMinus: fontSizeDown,
                              onPlus: fontSizeUp,
                              ctrl: true,
                              plusKey: LogicalKeyboardKey.equal,
                              minusKey: LogicalKeyboardKey.minus,
                            ),
                            SingleHandler(keys: const [LogicalKeyboardKey.keyO], ctrl: true, onHandle: openFile)
                          ],
                        );
                      }),
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Visibility(
                    visible: sm.previewing,
                    maintainState: true,
                    child: Scrollbar(
                      child: Consumer(builder: (bc, watch, __) {
                        return MarkdownPreview(
                          sc: sc,
                          padding: vertical
                              ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                              : const EdgeInsets.fromLTRB(8, 16, 16, 16),
                          expr: watch(activeFile),
                          scale: watch(scale).state,
                        );
                      }),
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
