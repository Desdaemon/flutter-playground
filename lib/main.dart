import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yata_flutter/screens/markdown.dart';
import 'package:yata_flutter/state/dark.dart';

const boxname = 'markdown';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox(boxname);
  runApp(const RootRestorationScope(restorationId: 'root', child: ProviderScope(child: MarkdownApp())));
}

const ayuFg = Color(0xff575f66);

/// See [ayu-colors](https://github.com/ayu-theme/ayu-colors)
const ayuDark = ColorScheme(
  primary: Color(0xff39bae6), // syntax.tag
  primaryVariant: Color(0xff59c2ff), // syntax.entity
  secondary: Color(0xffe6b450), // common.accent
  secondaryVariant: Color(0xffffb454), // syntax.func
  surface: Color(0xff273747), // ui.selection.bg
  background: Color(0xff0a0e14), // common.bg
  error: Color(0xffff3333), // syntax.error
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onSurface: Color(0xffb3b1ad),
  onBackground: Color(0xffb3b1ad), // common.fg
  onError: Colors.black, // common.fg
  brightness: Brightness.dark,
);

const ayuLight = ColorScheme(
  primary: Color(0xff55b4d4),
  primaryVariant: Color(0xff399ee6),
  secondary: Color(0xffff9940),
  secondaryVariant: Color(0xfff2ae49),
  surface: Color(0xffe7e8e9),
  background: Color(0xfffafafa),
  error: Color(0xfff51818),
  onPrimary: Colors.black,
  onSecondary: Colors.black,
  onSurface: Color(0xff575f66),
  onBackground: Color(0xff575f66),
  onError: Colors.black,
  brightness: Brightness.light,
);

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
