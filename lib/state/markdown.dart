import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_playground/main.dart' show boxname, prefname;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final pScreenMode = StateProvider((_) => ScreenMode.sbs);
final pLockstep = StateProvider((_) => true);
final pNativeParsing = StateProvider((_) => true);
final pScale = StateProvider((_) => 1.0);
final pIndents = StateProvider((_) => 2);
final pTicker = StateProvider((_) => '');
final pCache = StateProvider((_) => true);

/// The directory of files and its interim contents.
final pFiles = StateNotifierProvider<MarkdownStore, MarkdownState>(
  (_) => MarkdownStore(boxname: boxname, prefname: prefname),
);

/// The path to the file being edited.
final pActivePath = Provider((ref) => ref.watch(pFiles).active);

/// The contents of the active file.
final pActiveFile =
    Provider((ref) => ref.watch(pFiles).files[ref.watch(pActivePath)] ?? '');
final pFileList = Provider((ref) => ref.watch(pFiles).files.keys);
final pIsPreviewing =
    Provider((ref) => ref.watch(pScreenMode).state.previewing);

/// Scalable fontsize.
final pFontSize =
    Provider.family((ref, double size) => ref.watch(pScale).state * size);

@immutable
class MarkdownState {
  final Map<String, String?> files;
  final String active;
  const MarkdownState(this.files, this.active);
  MarkdownState copyWith({Map<String, String?>? files, String? active}) =>
      MarkdownState(files ?? this.files, active ?? this.active);
}

class MarkdownStore extends StateNotifier<MarkdownState> {
  MarkdownStore({
    this.boxname = 'markdown',
    this.boxid = 'markdown',
    this.untitled = 'Untitled',
    this.prefname = 'prefs',
  }) : super(const MarkdownState({}, 'Untitled'));
  final String boxname;
  final String boxid;
  final String prefname;
  final String untitled;
  Timer timer = Timer(Duration.zero, () {});
  bool firstrun = true;

  String get activepathid => 'right_$boxid';

  @override
  MarkdownState get state {
    if (firstrun) {
      firstrun = false;
      // Since we only store String? in this box, it is safe to perform this cast.
      final left = Hive.box(boxname).toMap().cast<String, String?>();
      final right = Hive.box('prefs').get(activepathid) as String?;
      super.state = MarkdownState(left, right ?? super.state.active);
    }
    return super.state;
  }

  @override
  set state(MarkdownState s) {
    super.state = s;
    Hive.box(prefname).put(activepathid, s.active);
  }

  void persist(String path) {
    Hive.box(boxname).put(path, state.files[path]);
  }

  /// Sets the [path] for [contents] without making it active.
  void operator []=(String path, String contents) {
    state = state.copyWith(
      files: {
        for (final en in state.files.entries)
          if (en.key == path) path: contents else en.key: en.value,
        if (!state.files.containsKey(path)) path: contents
      },
    );
    persist(path);
  }

  /// Sets the [contents] of [path] and makes it the active file.
  void activate(String path, String contents) {
    state = MarkdownState(
      {
        for (final en in state.files.entries)
          if (en.key == path) path: contents else en.key: en.value,
        if (!state.files.containsKey(path)) path: contents
      },
      path,
    );
    persist(path);
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
    state = MarkdownState(
      {
        for (final en in state.files.entries)
          if (en.key != file) en.key: en.value
      },
      newpath,
    );
    Hive.box(boxname).delete(file);
    return state.files[state.active] ?? '';
  }

  /// Sets [path] to be the active file.
  void focus(String path) {
    state = state.copyWith(active: path);
  }

  /// Sets the contents of the current active file.
  void updateActive(String contents) {
    timer.cancel();
    final active = state.active;
    timer = Timer(const Duration(milliseconds: 200), () {
      state = state.copyWith(
        files: {
          for (final en in state.files.entries)
            if (en.key == active) active: contents else en.key: en.value,
          if (!state.files.containsKey(active)) active: contents
        },
      );
    });
    persist(active);
  }
}

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
