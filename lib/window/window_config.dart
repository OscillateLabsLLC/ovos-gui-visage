/// How the app's window sits on the desktop (SCOPE phase 6). `desktop`, the default, is a frameless window beneath
/// everything, like a desktop widget; `float` is the same window above everything; both are pinned to a screen
/// corner on every Space. `window` is an ordinary window. Read from ~/.config/ovos-gui-visage/config.json,
/// overridden by VISAGE_MODE, VISAGE_CORNER, VISAGE_HEIGHT and VISAGE_MARGIN.
library;

import 'dart:ui';

import '../face/face_theme.dart';

enum WindowMode { window, float, desktop }

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

const defaultWidgetHeight = 400.0;
const defaultMargin = 16.0;

class WindowConfig {
  const WindowConfig({
    this.mode = WindowMode.desktop,
    this.corner = Corner.topRight,
    this.height = defaultWidgetHeight,
    this.margin = defaultMargin,
  });

  /// [json] is the file's `window` object (or null); [env] wins over it.
  factory WindowConfig.from(Map<String, dynamic>? json, Map<String, String> env) {
    final defaults = const WindowConfig();
    return WindowConfig(
      mode: _enumFrom(WindowMode.values, env['VISAGE_MODE'] ?? json?['mode']) ?? defaults.mode,
      corner: _enumFrom(Corner.values, env['VISAGE_CORNER'] ?? json?['corner']) ?? defaults.corner,
      height: _positive(env['VISAGE_HEIGHT'] ?? json?['height']) ?? defaults.height,
      margin: _positive(env['VISAGE_MARGIN'] ?? json?['margin']) ?? defaults.margin,
    );
  }

  final WindowMode mode;
  final Corner corner;
  final double height;
  final double margin;

  bool get isWidget => mode != WindowMode.window;

  Size get size => Size(height * frameWidth / frameHeight, height);

  /// The window's top-left within [workArea], the display minus menu bar and dock, in logical pixels.
  Offset placeIn(Rect workArea) {
    final left = switch (corner) {
      Corner.topLeft || Corner.bottomLeft => workArea.left + margin,
      Corner.topRight || Corner.bottomRight => workArea.right - size.width - margin,
    };
    final top = switch (corner) {
      Corner.topLeft || Corner.topRight => workArea.top + margin,
      Corner.bottomLeft || Corner.bottomRight => workArea.bottom - size.height - margin,
    };
    return Offset(left, top);
  }
}

/// "top-right", "topRight" and "TOP_RIGHT" all name [Corner.topRight].
T? _enumFrom<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  final key = name.toString().toLowerCase().replaceAll(RegExp('[-_ ]'), '');
  for (final value in values) {
    if (value.name.toLowerCase() == key) return value;
  }
  return null;
}

double? _positive(Object? value) {
  final n = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  return n != null && n > 0 ? n : null;
}
