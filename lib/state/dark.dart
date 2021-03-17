import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final darkTheme = StateNotifierProvider((_) => Dark());

class Dark extends StateNotifier<bool> {
  final String boxname;
  bool firstrun = true;
  Dark({this.boxname = 'todo'}) : super(false);

  @override
  set state(bool dark) {
    super.state = dark;
    box.put('dark', dark);
  }

  @override
  bool get state {
    if (firstrun) {
      super.state = box.get('dark', defaultValue: false) as bool;
      firstrun = false;
    }
    return super.state;
  }

  Box get box => Hive.box(boxname);
}
