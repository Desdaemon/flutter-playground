// import 'dart:async';
// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the FlutterPlayground plugin.
class FlutterPlaygroundWeb {
  static void initialize([String source = './assets/pkg/flutter_playground.js']) {
    final head = document.head;
    if (head == null) return;

    if (head.querySelector('#flt-flutter-playground-wasm') != null) return;

    final script = ScriptElement()
      ..id = 'flt-flutter-playground-wasm'
      ..type = 'module'
      ..async = true
      ..text = '''
          import init from '$source';
          import * as wasm from '$source';
          await init();
          Object.assign(window, wasm);
          ''';
    head.append(script);
  }

  static void registerWith(Registrar registrar) {
    initialize();
  }

  // /// Handles method calls over the MethodChannel of this plugin.
  // /// Note: Check the "federated" architecture for a new way of doing this:
  // /// https://flutter.dev/go/federated-plugins
  // Future<dynamic> handleMethodCall(MethodCall call) async {
  // switch (call.method) {
  // case 'getPlatformVersion':
  // return getPlatformVersion();
  // default:
  // throw PlatformException(
  // code: 'Unimplemented',
  // details: 'flutter_playground for web doesn\'t implement \'${call.method}\'',
  // );
  // }
  // }

  // /// Returns a [String] containing the version of the platform.
  // Future<String> getPlatformVersion() {
  // final version = html.window.navigator.userAgent;
  // return Future.value(version);
  // }
}
