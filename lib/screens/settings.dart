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
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
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
          )
        ],
      ),
    );
  }
}
