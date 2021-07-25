import 'package:hive/hive.dart';

part 'preferences.g.dart';

@HiveType(typeId: 1)
class Preferences {
  @HiveField(0, defaultValue: ParseMode.ast)
  late final ParseMode parseMode;
  @HiveField(1, defaultValue: ThemeType.system)
  late final ThemeType themeType;
  @HiveField(2, defaultValue: 1)
  late final double scale;
}

@HiveType(typeId: 2)
enum ParseMode {
  @HiveField(0)
  dart,
  @HiveField(1)
  json,
  @HiveField(2)
  ast,
}

@HiveType(typeId: 3)
enum ThemeType {
  @HiveField(0)
  light,
  @HiveField(1)
  dark,
  @HiveField(2)
  system,
}
