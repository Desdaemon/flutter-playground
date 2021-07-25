// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParseModeAdapter extends TypeAdapter<ParseMode> {
  @override
  final int typeId = 2;

  @override
  ParseMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ParseMode.dart;
      case 1:
        return ParseMode.json;
      case 2:
        return ParseMode.ast;
      default:
        return ParseMode.dart;
    }
  }

  @override
  void write(BinaryWriter writer, ParseMode obj) {
    switch (obj) {
      case ParseMode.dart:
        writer.writeByte(0);
        break;
      case ParseMode.json:
        writer.writeByte(1);
        break;
      case ParseMode.ast:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParseModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThemeTypeAdapter extends TypeAdapter<ThemeType> {
  @override
  final int typeId = 3;

  @override
  ThemeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ThemeType.light;
      case 1:
        return ThemeType.dark;
      case 2:
        return ThemeType.system;
      default:
        return ThemeType.light;
    }
  }

  @override
  void write(BinaryWriter writer, ThemeType obj) {
    switch (obj) {
      case ThemeType.light:
        writer.writeByte(0);
        break;
      case ThemeType.dark:
        writer.writeByte(1);
        break;
      case ThemeType.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PreferencesAdapter extends TypeAdapter<Preferences> {
  @override
  final int typeId = 1;

  @override
  Preferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Preferences()
      ..parseMode = fields[0] == null ? ParseMode.ast : fields[0] as ParseMode
      ..themeType =
          fields[1] == null ? ThemeType.system : fields[1] as ThemeType
      ..scale = fields[2] == null ? 1 : fields[2] as double;
  }

  @override
  void write(BinaryWriter writer, Preferences obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.parseMode)
      ..writeByte(1)
      ..write(obj.themeType)
      ..writeByte(2)
      ..write(obj.scale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
