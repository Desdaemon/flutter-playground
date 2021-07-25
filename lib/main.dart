import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yata_flutter/types/preferences.dart';

import 'screens/markdown.dart';
import 'state/dark.dart';
import 'styles/color_schemes.dart';

const boxname = 'markdown';
const prefname = 'prefs';

Future<void> main() async {
  Hive.registerAdapter(PreferencesAdapter());
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ParseModeAdapter());
  await Hive.initFlutter();
  await Hive.openBox(boxname);
  await Hive.openBox(prefname);
  runApp(const RootRestorationScope(restorationId: 'root', child: ProviderScope(child: MarkdownApp())));
}

class MarkdownApp extends StatelessWidget {
  const MarkdownApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, watch, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.from(colorScheme: ayuLight, textTheme: Typography.englishLike2018),
        darkTheme: ThemeData.from(colorScheme: ayuDark, textTheme: Typography.englishLike2018),
        themeMode: watch(darkTheme),
        home: child,
        restorationScopeId: 'root',
      ),
      child: const MathMarkdown(restorationId: 'MathMarkdown'),
    );
  }
}
