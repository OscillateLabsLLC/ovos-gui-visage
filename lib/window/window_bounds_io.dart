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
    if (_same(await windowManager.getSize(), size)) return;
    await Future<void>.delayed(_resizePoll);
  }
}

/// What to do with the size a newly shown window reads back: [wait] while it is still changing.
enum MappedSizeStep { done, resize, wait }

MappedSizeStep mappedSizeStep({required Size wanted, required Size current, Size? previous}) {
  if (_same(current, wanted)) return MappedSizeStep.done;
  return previous != null && _same(current, previous) ? MappedSizeStep.resize : MappedSizeStep.wait;
}

/// GTK maps a frameless window that was built with a header bar 52 px short on each axis (measured on native Wayland,
/// KWin 5.27: it reads back 1332x819 before the map and 188x348 after, for 240x400). Once the size it reads back holds
/// still and is wrong, one resize puts it right; on X11 it reads back the size asked for and nothing is sent.
Future<void> correctMappedSize(Size wanted) async {
  Size? previous;
  for (var i = 0; i < _resizePolls; i++) {
    final current = await windowManager.getSize();
    switch (mappedSizeStep(wanted: wanted, current: current, previous: previous)) {
      case MappedSizeStep.done:
        return;
      case MappedSizeStep.resize:
        return windowManager.setSize(wanted);
      case MappedSizeStep.wait:
        previous = current;
        await Future<void>.delayed(_resizePoll);
    }
  }
}

bool _same(Size a, Size b) => (a.width - b.width).abs() < 1 && (a.height - b.height).abs() < 1;
