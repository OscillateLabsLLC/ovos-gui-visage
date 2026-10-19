import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../app_config.dart';
import '../face/face_spec.dart';
import '../faults.dart';
import 'kiosk_shell_io.dart';
import 'window_channel.dart';
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

/// Writes `peek` and `mode` into the config file's `window` object, keeping every other key; the rest of the window
/// config may come from the environment and is not written back.
Future<void> saveWindowConfig(WindowConfig config) => _editConfigFile((json) {
  final window = json['window'] is Map ? Map<String, dynamic>.from(json['window'] as Map) : <String, dynamic>{};
  json['window'] = window
    ..['peek'] = config.peek
    ..['mode'] = config.mode.name;
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

/// Starts a peeking widget collapsed to its badge; [setWidgetExpanded] grows and shrinks it in its corner. Kiosk fills
/// the screen; an ordinary window is left as the runner made it.
Future<void> applyWindowConfig(WindowConfig config) async {
  if (config.isKiosk) return _startKiosk();
  if (!config.isWidget) return;
  await windowManager.ensureInitialized();
  if (Platform.isMacOS) await _invoke('setActivationPolicy', 'accessory');
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
    if (config.mode == WindowMode.desktop) await _invoke('setWindowLevel', 'desktop');
    await windowManager.setPosition(bounds.topLeft);
    await windowManager.show();
  });
}

Future<void> _startKiosk() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(backgroundColor: Colors.transparent, skipTaskbar: true, titleBarStyle: TitleBarStyle.hidden);
  await windowManager.waitUntilReadyToShow(options, () async {
    await enterKiosk(from: WindowMode.kiosk);
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

/// Moves a widget above (`float`) or beneath (`desktop`) every other window while running, or into and out of
/// kiosk; a widget leaving kiosk lands in its corner at its peek size.
Future<void> setWindowMode(WindowConfig config, {required WindowMode from, required bool expanded}) async {
  if (config.isKiosk) return enterKiosk(from: from);
  if (from == WindowMode.kiosk) {
    final bounds = config.isWidget ? config.boundsIn(await _workArea(), expanded: expanded) : null;
    return leaveKiosk(config, bounds: bounds);
  }
  await windowManager.setAlwaysOnTop(config.mode == WindowMode.float);
  await _invoke('setWindowLevel', config.mode.name);
}

/// Orders the window out or back in front; a desktop-level window must not become key, so this is not
/// windowManager.show.
Future<void> setWindowVisible(bool visible) => _invoke('setVisible', visible);

Future<void> quitApp() => windowManager.destroy();

/// The runner implements these on macOS (MainFlutterWindow.swift); where it does not, the window stays as it was and
/// the fault is reported.
Future<void> _invoke(String method, Object arguments) async {
  try {
    await windowChannel.invokeMethod<void>(method, arguments);
  } on MissingPluginException catch (err, stack) {
    reportFault('$method is not implemented by this platform runner', err, stack);
  }
}
