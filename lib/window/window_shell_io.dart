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
import 'plugin_calls.dart';
import 'window_bounds_io.dart';
import 'window_channel.dart';
import 'window_config.dart';

/// Where the widget goes when the platform cannot describe its display: a 1080p work area, so it still shows.
const _fallbackWorkArea = Rect.fromLTWH(0, 0, 1920, 1080);

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

/// Writes `peek`, `mode` and `corner` into the config file's `window` object, keeping every other key; the rest of
/// the window config may come from the environment and is not written back.
Future<void> saveWindowConfig(WindowConfig config) => _editConfigFile((json) {
  final window = json['window'] is Map ? Map<String, dynamic>.from(json['window'] as Map) : <String, dynamic>{};
  json['window'] = window
    ..['peek'] = config.peek
    ..['mode'] = config.mode.name
    ..['corner'] = config.corner.name;
});

/// The primary display minus menu bar, dock or panel, in logical pixels.
Future<Rect> workArea() => _workArea();

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
/// the screen; an ordinary window is left as the runner made it. Every step is attempted in turn: a platform
/// without one of them (Linux has no window shadow or all-workspaces call) reports it and still places and shows
/// the widget. The steps run after the plugin's ready call returns, not in its callback, which it does not await.
Future<void> applyWindowConfig(WindowConfig config) async {
  if (config.isKiosk) return _startKiosk();
  if (!config.isWidget) return;
  await _attempt('ensureInitialized', windowManager.ensureInitialized);
  if (Platform.isMacOS) await _invoke('setActivationPolicy', 'accessory');
  final workArea = await _attempt('getPrimaryDisplay', _workArea) ?? _fallbackWorkArea;
  final bounds = config.boundsIn(workArea, expanded: !config.peeks);
  final options = WindowOptions(
    size: bounds.size,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: config.mode == WindowMode.float,
  );
  await _attempt('waitUntilReadyToShow', () => windowManager.waitUntilReadyToShow(options));
  await _attempt('setAsFrameless', windowManager.setAsFrameless);
  await _attempt('setHasShadow', () => windowManager.setHasShadow(false));
  // GTK sizes a non-resizable window at its default size, not the size asked for, so Linux keeps it resizable.
  if (Platform.isMacOS) await _attempt('setResizable', () => windowManager.setResizable(false));
  await _attempt('setVisibleOnAllWorkspaces', () => windowManager.setVisibleOnAllWorkspaces(true));
  if (config.mode == WindowMode.desktop) await _setLevel(WindowMode.desktop);
  await _attempt('setPosition', () => windowManager.setPosition(bounds.topLeft));
  await _attempt('show', windowManager.show);
}

Future<void> _startKiosk() async {
  await _attempt('ensureInitialized', windowManager.ensureInitialized);
  const options = WindowOptions(backgroundColor: Colors.transparent, skipTaskbar: true, titleBarStyle: TitleBarStyle.hidden);
  await _attempt('waitUntilReadyToShow', () => windowManager.waitUntilReadyToShow(options));
  await enterKiosk(from: WindowMode.kiosk);
  await _attempt('show', windowManager.show);
}

/// `desktop` beneath every window and `float` above: the runner's own level on macOS, GTK keep-below elsewhere.
Future<void> _setLevel(WindowMode mode) async {
  if (Platform.isMacOS) return _invoke('setWindowLevel', mode.name);
  await _attempt('setAlwaysOnBottom', () => windowManager.setAlwaysOnBottom(mode == WindowMode.desktop));
}

Future<T?> _attempt<T>(String what, Future<T> Function() call) => attemptPluginCall('$what in widget setup', call);

/// Animates the widget window between its badge and its full size, anchored at its corner. A failure leaves the
/// window as it was and is reported.
Future<void> setWidgetExpanded(WindowConfig config, {required bool expanded}) async {
  if (!config.isWidget) return;
  try {
    await setWindowBounds(config.boundsIn(await _workArea(), expanded: expanded), growing: expanded, animate: true);
  } on Object catch (err, stack) {
    reportFault('resizing the widget window (expanded: $expanded)', err, stack);
  }
}

/// Moves a widget above (`float`) or beneath (`desktop`) every other window while running, or into and out of
/// kiosk; a widget leaving kiosk lands in its corner at its peek size.
Future<void> setWindowMode(WindowConfig config, {required WindowMode from, required bool expanded}) async {
  if (config.isKiosk) return enterKiosk(from: from);
  if (from == WindowMode.kiosk) {
    return leaveKiosk(
      config,
      bounds: config.isWidget ? () async => config.boundsIn(await _workArea(), expanded: expanded) : null,
    );
  }
  await windowManager.setAlwaysOnTop(config.mode == WindowMode.float);
  await _setLevel(config.mode);
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
