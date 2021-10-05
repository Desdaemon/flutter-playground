import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_playground/types/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/markdown.dart';
import 'state/dark.dart';
import 'styles/color_schemes.dart';

const boxname = 'markdown';
const prefname = 'prefs';

class Logger extends ProviderObserver {
  const Logger();
  @override
  void didUpdateProvider(ProviderBase provider, Object? newValue) {
    if (!kDebugMode) return;
    dynamic value = newValue;
    if (newValue is StateController<dynamic>) {
      value = newValue.state;
    } else if (newValue is String) {
      value = newValue.length < 80 ? newValue : '${newValue.characters.take(70).toString()} (${newValue.length}C)';
    }
    debugPrint('[${DateTime.now()}] ${provider.name ?? provider.runtimeType}(${provider.argument ?? ''}): $value');
  }
}

Future<void> main() async {
  Hive.registerAdapter(PreferencesAdapter());
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ParseModeAdapter());
  await Hive.initFlutter();
  await Hive.openBox(boxname);
  await Hive.openBox(prefname);
  runApp(const ProviderScope(observers: [Logger()], child: MarkdownApp()));
}

class MarkdownApp extends ConsumerWidget {
  const MarkdownApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(colorScheme: ayuLight, textTheme: Typography.englishLike2018),
      darkTheme: ThemeData.from(colorScheme: ayuDark, textTheme: Typography.englishLike2018),
      themeMode: watch(darkTheme),
      home: const MathMarkdown(restorationId: 'MathMarkdown'),
      restorationScopeId: 'root',
    );
  }
}
