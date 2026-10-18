import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../app_config.dart';
import '../face/face_spec.dart';
import '../faults.dart';
import 'window_config.dart';

File configFile() {
  final home = Platform.environment['HOME'] ?? '';
  final base = Platform.environment['XDG_CONFIG_HOME'] ?? '$home/.config';
  return File('$base/ovos-gui-visage/config.json');
}

/// The config file with the environment on top; a file that will not parse is reported and treated as absent, so
/// a typo never leaves the display without a window.
Future<AppConfig> loadAppConfig() async {
  final file = configFile();
  Map<String, dynamic>? json;
  if (file.existsSync()) {
    try {
      json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on Object catch (err, stack) {
      reportFault('reading ${file.path}', err, stack);
    }
  }
  return AppConfig.from(json, Platform.environment);
}

/// Writes the face into the config file's `face` object, keeping everything else in the file, so a face chosen on
/// the device or over the bus is the face at the next start.
Future<void> saveFaceConfig(FaceSpec spec) => _editConfigFile((json) => json['face'] = spec.toJson());

/// Writes `peek` into the config file's `window` object, keeping every other key; the rest of the window config may
/// come from the environment and is not written back.
Future<void> saveWindowConfig(WindowConfig config) => _editConfigFile((json) {
  final window = json['window'] is Map ? Map<String, dynamic>.from(json['window'] as Map) : <String, dynamic>{};
  json['window'] = window..['peek'] = config.peek;
});

Future<void> _editConfigFile(void Function(Map<String, dynamic> json) edit) async {
  final file = configFile();
  var json = <String, dynamic>{};
  if (file.existsSync()) json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  edit(json);
  await file.create(recursive: true);
  await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(json)}\n');
}

Future<Rect> _workArea() async {
  final display = await screenRetriever.getPrimaryDisplay();
  return (display.visiblePosition ?? Offset.zero) & (display.visibleSize ?? display.size);
}

/// Starts a peeking widget collapsed to its badge; [setWidgetExpanded] grows and shrinks it in its corner.
Future<void> applyWindowConfig(WindowConfig config) async {
  if (!config.isWidget) return;
  await windowManager.ensureInitialized();
  final bounds = config.boundsIn(await _workArea(), expanded: !config.peeks);
  final options = WindowOptions(
    size: bounds.size,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: config.mode == WindowMode.float,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false);
    await windowManager.setResizable(false);
    await windowManager.setVisibleOnAllWorkspaces(true);
    if (config.mode == WindowMode.desktop) await _setDesktopLevel();
    await windowManager.setPosition(bounds.topLeft);
    await windowManager.show();
  });
}

/// Animates the widget window between its badge and its full size, anchored at its corner. A failure leaves the
/// window as it was and is reported.
Future<void> setWidgetExpanded(WindowConfig config, {required bool expanded}) async {
  if (!config.isWidget) return;
  try {
    await windowManager.setBounds(config.boundsIn(await _workArea(), expanded: expanded), animate: true);
  } on Object catch (err, stack) {
    reportFault('resizing the widget window (expanded: $expanded)', err, stack);
  }
}

const _native = MethodChannel('ovos_gui_visage/window');

/// window_manager has no always-on-bottom on macOS, so the runner provides the desktop level (MainFlutterWindow.swift).
/// Where no runner implements it, the window stays at its normal level and the fault is reported.
Future<void> _setDesktopLevel() async {
  try {
    await _native.invokeMethod<void>('setDesktopLevel');
  } on MissingPluginException catch (err, stack) {
    reportFault('desktop mode is not implemented by this platform runner', err, stack);
  }
}
