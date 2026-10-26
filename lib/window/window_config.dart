/// How the app's window sits on the desktop (SCOPE phase 6). `desktop`, the default, is a frameless window beneath
/// everything, like a desktop widget; `float` is the same window above everything; both are pinned to a screen
/// corner on every Space. `window` is an ordinary window. `kiosk` fills the primary display above everything, so the
/// screen is only the assistant. With `peek`, a widget idles as a small round badge and grows only while OVOS has
/// attention (peek.dart). Read from ~/.config/ovos-gui-visage/config.json, overridden by
/// VISAGE_MODE, VISAGE_CORNER, VISAGE_HEIGHT, VISAGE_MARGIN, VISAGE_PEEK and VISAGE_PEEK_SIZE.
library;

import 'dart:ui';

import '../face/face_theme.dart';

enum WindowMode { window, float, desktop, kiosk }

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

const defaultWidgetHeight = 400.0;
const defaultMargin = 16.0;
const defaultPeekSize = 96.0;

class WindowConfig {
  const WindowConfig({
    this.mode = WindowMode.desktop,
    this.corner = Corner.topRight,
    this.height = defaultWidgetHeight,
    this.margin = defaultMargin,
    this.peek = false,
    this.peekSize = defaultPeekSize,
    this.kioskExit = WindowMode.float,
  });

  /// [json] is the file's `window` object (or null); [env] wins over it.
  factory WindowConfig.from(Map<String, dynamic>? json, Map<String, String> env) {
    final defaults = const WindowConfig();
    return WindowConfig(
      mode: _enumFrom(WindowMode.values, env['VISAGE_MODE'] ?? json?['mode']) ?? defaults.mode,
      corner: _enumFrom(Corner.values, env['VISAGE_CORNER'] ?? json?['corner']) ?? defaults.corner,
      height: _positive(env['VISAGE_HEIGHT'] ?? json?['height']) ?? defaults.height,
      margin: _positive(env['VISAGE_MARGIN'] ?? json?['margin']) ?? defaults.margin,
      peek: _flag(env['VISAGE_PEEK'] ?? json?['peek']) ?? defaults.peek,
      peekSize: _positive(env['VISAGE_PEEK_SIZE'] ?? json?['peekSize']) ?? defaults.peekSize,
      kioskExit: _kioskExit(_enumFrom(WindowMode.values, json?['mode']) ?? defaults.mode),
    );
  }

  final WindowMode mode;
  final Corner corner;

  /// The corner widget's height in logical pixels; its width follows the frame. An ordinary window ignores it.
  final double height;
  final double margin;

  /// Configured; [peeks] says whether it applies, since an ordinary window never peeks.
  final bool peek;

  /// The collapsed badge's diameter in logical pixels.
  final double peekSize;

  /// The mode leaving kiosk returns to: the file's mode at startup, else the mode kiosk was entered from. Not saved.
  final WindowMode kioskExit;

  /// A corner widget: `float` or `desktop`. Neither `window` nor `kiosk` is one, so neither peeks.
  bool get isWidget => mode == WindowMode.float || mode == WindowMode.desktop;

  bool get isKiosk => mode == WindowMode.kiosk;

  bool get peeks => peek && isWidget;

  /// An ordinary window opens at the frame's own size, 480 x 800, so text reads at the size it was designed at;
  /// [height] sizes the corner widgets, which are the frame scaled down.
  Size get size =>
      mode == WindowMode.window ? const Size(frameWidth, frameHeight) : Size(height * frameWidth / frameHeight, height);

  Size get peekWindowSize => Size.square(peekSize);

  WindowConfig copyWith({WindowMode? mode, Corner? corner, bool? peek, WindowMode? kioskExit}) => WindowConfig(
    mode: mode ?? this.mode,
    corner: corner ?? this.corner,
    height: height,
    margin: margin,
    peek: peek ?? this.peek,
    peekSize: peekSize,
    kioskExit: kioskExit ?? this.kioskExit,
  );

  /// The window's frame within [workArea]: the full widget, or the badge when collapsed, in the same corner.
  Rect boundsIn(Rect workArea, {required bool expanded}) {
    final windowSize = expanded ? size : peekWindowSize;
    return placeIn(workArea, windowSize) & windowSize;
  }

  /// The top-left of a window of [windowSize] (the full widget by default) within [workArea], the display minus menu
  /// bar and dock, in logical pixels.
  Offset placeIn(Rect workArea, [Size? windowSize]) {
    final size = windowSize ?? this.size;
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

/// The corner of [workArea] a window dropped at [window] is nearest to: where its centre sits relative to the
/// work area's centre, so a widget dragged past the middle of the screen changes corner.
Corner nearestCorner(Rect window, Rect workArea) {
  final right = window.center.dx >= workArea.center.dx;
  final bottom = window.center.dy >= workArea.center.dy;
  return switch ((right, bottom)) {
    (false, false) => Corner.topLeft,
    (true, false) => Corner.topRight,
    (false, true) => Corner.bottomLeft,
    (true, true) => Corner.bottomRight,
  };
}

/// A file that says `kiosk` leaves kiosk to `float`, so Escape always lands somewhere visible.
WindowMode _kioskExit(WindowMode fileMode) => fileMode == WindowMode.kiosk ? WindowMode.float : fileMode;

/// "top-right", "topRight" and "TOP_RIGHT" all name [Corner.topRight].
T? _enumFrom<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  final key = name.toString().toLowerCase().replaceAll(RegExp('[-_ ]'), '');
  for (final value in values) {
    if (value.name.toLowerCase() == key) return value;
  }
  return null;
}

bool? _flag(Object? value) {
  if (value is bool) return value;
  return switch (value?.toString().trim().toLowerCase()) {
    '1' || 'true' || 'yes' || 'on' => true,
    '0' || 'false' || 'no' || 'off' => false,
    _ => null,
  };
}

double? _positive(Object? value) {
  final n = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  return n != null && n > 0 ? n : null;
}
