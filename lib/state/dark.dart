import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final darkTheme = StateNotifierProvider((_) => Dark(boxname: 'prefs'));

class Dark extends StateNotifier<ThemeMode> {
  final String boxname;
  bool firstrun = true;
  Dark({this.boxname = 'todo'}) : super(ThemeMode.system);

  @override
  set state(ThemeMode dark) {
    super.state = dark;
    box.put('dark', dark.index);
  }

  void next() {
    switch (state) {
      case ThemeMode.system:
        state = ThemeMode.light;
        break;
      case ThemeMode.light:
        state = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        state = ThemeMode.system;
        break;
    }
  }

  @override
  ThemeMode get state {
    if (firstrun) {
      final idx = box.get('dark', defaultValue: ThemeMode.system.index) as int;
      super.state = ThemeMode.values[idx];
      firstrun = false;
    }
    return super.state;
  }

  Box get box => Hive.box(boxname);
}
