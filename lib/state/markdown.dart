import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final screenMode = StateProvider((_) => ScreenMode.sbs);
final lockstep = StateProvider((_) => true);
final scale = StateProvider((_) => 1.0);
final indents = StateProvider((_) => 2);

/// The path to the file being edited.
final activePath = StateProvider((_) => 'Untitled');

/// The directory of files and its interim contents.
final files = StateNotifierProvider((_) => MapNotifier<String, String?>());
final activeFile = Provider((ref) => ref.watch(files.state)[ref.watch(activePath).state] ?? '');
final fileList = Provider((ref) => ref.watch(files.state).keys);

class MapNotifier<K, V> extends StateNotifier<Map<K, V>> {
  MapNotifier([Map<K, V> state = const {}]) : super(state);

  void operator []=(K key, V value) {
    state = {
      // This is some Python-level super-duper weird syntax, but it works.
      for (final en in state.entries)
        if (en.key == key) key: value else en.key: en.value,
      if (!state.containsKey(key)) key: value
    };
  }

  void remove(K key) {
    state = {
      for (final en in state.entries)
        if (en.key != key) en.key: en.value
    };
  }
}

void setFileContent(BuildContext bc, String contents) {
  final active = bc.read(activePath).state;
  bc.read(files)[active] = contents;
}

/// Scalable fontsize.
final fontsize = Provider.family((ref, double size) => ref.watch(scale).state * size);

enum ScreenMode { edit, preview, sbs }

extension ScreenModeX on ScreenMode {
  ScreenMode get next => ScreenMode.values[(index + 1) % 3];

  bool get editing => this == ScreenMode.edit || this == ScreenMode.sbs;
  bool get previewing => this == ScreenMode.preview || this == ScreenMode.sbs;
  Icon get icon {
    switch (this) {
      case ScreenMode.edit:
        return const Icon(Icons.edit, key: ValueKey('edit'));
      case ScreenMode.preview:
        return const Icon(Icons.visibility, key: ValueKey('preview'));
      case ScreenMode.sbs:
        return const Icon(Icons.vertical_split, key: ValueKey('sbs'));
    }
  }

  String get description {
    switch (this) {
      case ScreenMode.edit:
        return 'Edit';
      case ScreenMode.preview:
        return 'Preview';
      case ScreenMode.sbs:
        return 'Side-by-side';
    }
  }
}
