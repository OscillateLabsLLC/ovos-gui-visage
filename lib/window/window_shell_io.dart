import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../faults.dart';
import 'window_config.dart';

File configFile() {
  final home = Platform.environment['HOME'] ?? '';
  final base = Platform.environment['XDG_CONFIG_HOME'] ?? '$home/.config';
  return File('$base/ovos-gui-visage/config.json');
}

/// The `window` object of the config file, with the environment on top; a file that will not parse is reported
/// and treated as absent, so a typo never leaves the display without a window.
Future<WindowConfig> loadWindowConfig() async {
  final file = configFile();
  Map<String, dynamic>? window;
  if (file.existsSync()) {
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      window = json['window'] as Map<String, dynamic>?;
    } on Object catch (err, stack) {
      reportFault('reading ${file.path}', err, stack);
    }
  }
  return WindowConfig.from(window, Platform.environment);
}

Future<void> applyWindowConfig(WindowConfig config) async {
  if (!config.isWidget) return;
  await windowManager.ensureInitialized();
  final display = await screenRetriever.getPrimaryDisplay();
  final workArea = (display.visiblePosition ?? Offset.zero) & (display.visibleSize ?? display.size);
  final options = WindowOptions(
    size: config.size,
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
    await windowManager.setPosition(config.placeIn(workArea));
    await windowManager.show();
  });
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
