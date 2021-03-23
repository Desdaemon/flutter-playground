import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yata_flutter/helpers/utils.dart';
import 'package:yata_flutter/state/dark.dart';
import 'package:yata_flutter/state/markdown.dart';
import 'package:path/path.dart' as p;

class MarkdownBottomSheet extends StatelessWidget {
  const MarkdownBottomSheet({
    Key? key,
    this.onNew,
    this.onOpen,
    this.onSave,
    this.onExport,
    this.onOpenCheatsheet,
    this.onSetActive,
    this.onDelete,
  }) : super(key: key);

  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onOpenCheatsheet;
  final void Function(String)? onSetActive;
  final void Function(String)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Consumer(
        builder: (bc, watch, _) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Text(shortenPath(watch(activePath)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
      const Divider(),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          IconButton(icon: const Icon(Icons.insert_drive_file_outlined), tooltip: 'New', onPressed: onNew),
          IconButton(icon: const Icon(Icons.folder_open), tooltip: 'Open', onPressed: onOpen),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: onSave),
          IconButton(icon: const Icon(Icons.print), onPressed: onExport, tooltip: 'Export to HTML'),
          IconButton(icon: const Icon(Icons.help), tooltip: 'Cheat Sheet', onPressed: onOpenCheatsheet),
          Consumer(
            builder: (bc, watch, _) => IconButton(
              onPressed: bc.read(darkTheme).next,
              icon: iconOf(watch(darkTheme.state)),
            ),
          ),
        ]),
      ),
      const Divider(),
      Consumer(
        builder: (bc, watch, _) => Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Files (${watch(fileList).length})', style: Theme.of(bc).textTheme.caption, maxLines: 1),
        ),
      ),
      Flexible(
        child: Scrollbar(
          child: Consumer(builder: (bc, watch, _) {
            final list = watch(fileList);
            final active = watch(activePath);
            return ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (bc, i) {
                final file = list.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(p.basename(file), maxLines: 1),
                  selected: active == file,
                  trailing: IconButton(onPressed: () => onDelete?.call(file), icon: const Icon(Icons.cancel)),
                  onTap: () => onSetActive?.call(file),
                );
              },
            );
          }),
        ),
      ),
      const SizedBox(height: 16)
    ]);
  }
}
