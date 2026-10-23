import 'package:flutter/services.dart';

/// The runner's own channel. On macOS (macos/Runner/MainFlutterWindow.swift): window level, visibility, activation
/// policy and the menu bar item, the parts window_manager lacks there. On Linux (linux/runner/window_channel.cc): only
/// `displayBackend`, the GDK backend the window is on.
const windowChannel = MethodChannel('ovos_gui_visage/window');
