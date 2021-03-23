import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final screenMode = StateProvider((_) => ScreenMode.sbs);
final lockstep = StateProvider((_) => true);
final scale = StateProvider((_) => 1.0);
final indents = StateProvider((_) => 2);

/// The directory of files and its interim contents.
final files = StateNotifierProvider((_) => MarkdownStore());

/// The path to the file being edited.
final activePath = Provider((ref) => ref.watch(files.state).active);

/// The contents of the active file.
final activeFile = Provider((ref) => ref.watch(files.state).files[ref.watch(activePath)] ?? '');
final fileList = Provider((ref) => ref.watch(files.state).files.keys);

@immutable
class MarkdownState {
  final Map<String, String> files;
  final String active;
  const MarkdownState(this.files, this.active);
  MarkdownState copyWith({Map<String, String>? files, String? active}) =>
      MarkdownState(files ?? this.files, active ?? this.active);
}

class MarkdownStore extends StateNotifier<MarkdownState> {
  MarkdownStore({this.boxname = 'markdown', this.boxid = 'mapnoti', this.untitled = 'Untitled'})
      : super(const MarkdownState({}, 'Untitled'));
  final String boxname;
  final String boxid;
  final String untitled;
  bool firstrun = true;

  Box get box => Hive.box(boxname);
  String get mapid => 'left_$boxid';
  String get activepathid => 'right_$boxid';

  @override
  MarkdownState get state {
    if (firstrun) {
      firstrun = false;
      final left = box.get(mapid) as Map<String, String>?;
      final right = box.get(activepathid) as String?;
      super.state = MarkdownState(left ?? super.state.files, right ?? super.state.active);
    }
    return super.state;
  }

  /// Sets the [path] for [contents] without making it active.
  void operator []=(String path, String contents) {
    state = state.copyWith(files: {
      for (final en in state.files.entries)
        if (en.key == path) path: contents else en.key: en.value,
      if (!state.files.containsKey(path)) path: contents
    });
  }

  /// Sets the [contents] of [path] and makes it the active file.
  void activate(String path, String contents) {
    state = MarkdownState({
      for (final en in state.files.entries)
        if (en.key == path) path: contents else en.key: en.value,
      if (!state.files.containsKey(path)) path: contents
    }, path);
  }

  /// Returns the contents of the current active file, after removing [file].
  String remove(String file) {
    final String newpath;
    if (file != state.active) {
      newpath = state.active;
    } else {
      final paths = state.files.keys.toList(growable: false);
      final idx = paths.indexOf(file);
      newpath = idx > 0 && paths.length > 1 ? paths[idx - 1] : untitled;
    }
    state = MarkdownState({
      for (final en in state.files.entries)
        if (en.key != file) en.key: en.value
    }, newpath);
    return state.files[state.active] ?? '';
  }

  /// Sets [path] to be the active file.
  void focus(String path) => state = state.copyWith(active: path);

  /// Sets the contents of the current active file.
  void updateActive(String contents) {
    final active = state.active;
    state = state.copyWith(files: {
      for (final en in state.files.entries)
        if (en.key == active) active: contents else en.key: en.value,
      if (!state.files.containsKey(active)) active: contents
    });
  }

  @override
  void dispose() {
    box.put(mapid, state.files);
    box.put(activepathid, state.active);
    super.dispose();
  }
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
