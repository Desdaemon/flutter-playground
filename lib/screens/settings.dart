import 'package:flutter/material.dart';
import 'package:flutter_playground/state/dark.dart';
import 'package:flutter_playground/state/markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static void noop() {}

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate.fixed([
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Settings'))),
              const Divider(),
              ListTile(
                title: const Text('Lockstep'),
                onTap: context.read(pLockstep.notifier).toggle,
                subtitle: const Text('Scrolls the preview pane together with the editor.'),
                trailing: Consumer(
                  builder: (bc, watch, _) => Switch(
                    value: watch(pLockstep).state,
                    onChanged: (val) => bc.read(pLockstep.notifier).state = val,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Theme'),
                leading: const Icon(Icons.brightness_4),
                trailing: Consumer(
                  builder: (bc, watch, _) => DropdownButton(
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    value: watch(darkTheme),
                    onChanged: (ThemeMode? val) => bc.read(darkTheme.notifier).state = val!,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Use fast parser'),
                subtitle: const Text('Work-in-progress feature. Not available for armv8l devices.'),
                onTap: context.read(pNativeParsing.notifier).toggle,
                trailing: Consumer(
                  builder: (bc, watch, _) => Switch(
                    value: !watch(pNativeParsing).state,
                    onChanged: (val) => bc.read(pNativeParsing.notifier).state = val,
                  ),
                ),
              ),
              const Divider(),
            ]),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 50,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            delegate: SliverChildListDelegate.fixed([
              TextButton.icon(
                onPressed: noop,
                icon: const Icon(Icons.insert_drive_file_outlined),
                label: const Text('New'),
              ),
              TextButton.icon(onPressed: noop, icon: const Icon(Icons.folder_open), label: const Text('Open')),
              TextButton.icon(onPressed: noop, icon: const Icon(Icons.save), label: const Text('Save')),
              TextButton.icon(onPressed: noop, icon: const Icon(Icons.import_export), label: const Text('Export')),
            ]),
          )
        ],
      ),
    );
  }
}
