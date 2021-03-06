import 'package:flutter/material.dart';
import 'package:flutter_playground/state/dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/utils.dart';

PreferredSizeWidget commonAppBar(BuildContext bc, {String title = 'Widgets Funhouse', List<Widget>? actions}) {
  return AppBar(
    title: Text(title),
    actions: [
      if (actions != null) ...actions,
      // A minimal example usage of a self-contained Consumer.
      Consumer(
        builder: (bc, watch, _) =>
            IconButton(onPressed: bc.read(darkTheme.notifier).next, icon: iconOf(watch(darkTheme))),
      ),
    ],
  );
}
