import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

const _resizePoll = Duration(milliseconds: 20);
const _resizePolls = 25;

/// Moves and sizes the native window to [bounds]. macOS takes both in one call. GTK applies a move at once but a
/// resize at its next layout pass, and KWin keeps a window on screen at the size it has when the move arrives, so a
/// badge collapsing at a right-hand corner was pushed left by its old width (measured: 1680 instead of 1808 at
/// 1920 wide). Off macOS a growth moves first, since the small window still fits at its new corner, and a collapse
/// resizes first and moves once the window reports the new size, or after half a second.
Future<void> setWindowBounds(Rect bounds, {required bool growing, bool animate = false}) async {
  if (Platform.isMacOS) return windowManager.setBounds(bounds, animate: animate);
  if (growing) await windowManager.setPosition(bounds.topLeft);
  await windowManager.setSize(bounds.size);
  if (growing) return;
  await _sizeApplied(bounds.size);
  await windowManager.setPosition(bounds.topLeft);
}

Future<void> _sizeApplied(Size size) async {
  for (var i = 0; i < _resizePolls; i++) {
    final current = await windowManager.getSize();
    if ((current.width - size.width).abs() < 1 && (current.height - size.height).abs() < 1) return;
    await Future<void>.delayed(_resizePoll);
  }
}
