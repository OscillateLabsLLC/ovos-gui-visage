import 'package:flutter/services.dart';

/// The runner's own channel (macos/Runner/MainFlutterWindow.swift): window level, visibility, activation policy and
/// the menu bar item, the parts window_manager lacks on macOS.
const windowChannel = MethodChannel('ovos_gui_visage/window');
