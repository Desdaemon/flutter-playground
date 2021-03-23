import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/markdown.dart';
import 'state/dark.dart';
import 'styles/color_schemes.dart';

const boxname = 'markdown';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox(boxname);
  runApp(const RootRestorationScope(restorationId: 'root', child: ProviderScope(child: MarkdownApp())));
}

class MarkdownApp extends StatelessWidget {
  const MarkdownApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, watch, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mathdown',
        theme: ThemeData.from(colorScheme: ayuLight, textTheme: Typography.englishLike2018),
        darkTheme: ThemeData.from(colorScheme: ayuDark, textTheme: Typography.englishLike2018),
        themeMode: watch(darkTheme.state),
        home: child,
      ),
      child: const MathMarkdown(restorationId: 'MathMarkdown'),
    );
  }
}
