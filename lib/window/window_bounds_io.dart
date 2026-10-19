import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

/// Moves and sizes the native window to [bounds]. macOS takes both in one call. GTK moves first and resizes second,
/// and an X11 window manager keeps the window on screen at its old size, so a shrinking window at a far corner would
/// be pushed back by its old width: off macOS a collapse resizes first, and a growth moves first, since the small
/// window still fits at its new corner. Measured on KWin: a 96 px badge collapsing at the top right ended 128 px left
/// of its corner until the order was split.
Future<void> setWindowBounds(Rect bounds, {required bool growing, bool animate = false}) async {
  if (Platform.isMacOS) return windowManager.setBounds(bounds, animate: animate);
  if (growing) await windowManager.setPosition(bounds.topLeft);
  await windowManager.setSize(bounds.size);
  if (!growing) await windowManager.setPosition(bounds.topLeft);
}
