import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yata_flutter/screens/markdown.dart';

const boxname = 'todo';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox(boxname);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, this.dark = false}) : super(key: key);
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'app',
      title: 'Flutter Demo',
      theme: ThemeData.from(colorScheme: const ColorScheme.light()),
      darkTheme: ThemeData.from(colorScheme: const ColorScheme.dark()),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const MathMarkdown(restorationId: 'math_markdown'),
    );
  }
}
