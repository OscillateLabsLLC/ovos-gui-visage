import 'package:flutter/services.dart';

import '../app_config.dart';
import '../face/face_spec.dart';
import 'window_config.dart';

Future<AppConfig> loadAppConfig() async => const AppConfig();

/// The web build has no config file; a face chosen there lasts the page's lifetime, by design.
Future<void> saveFaceConfig(FaceSpec spec) async {}

/// Nor a window config to write back, nor a window to place or resize.
Future<void> saveWindowConfig(WindowConfig config) async {}

Future<void> applyWindowConfig(WindowConfig config) async {}

Future<void> setWidgetExpanded(WindowConfig config, {required bool expanded}) async {}

Future<void> setWindowMode(WindowConfig config, {required WindowMode from, required bool expanded}) async {}

Future<void> setWindowVisible(bool visible) async {}

/// The browser tab's title, which is the document title.
Future<void> setWindowTitle(String title) =>
    SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(label: title));

Future<void> quitApp() async {}
