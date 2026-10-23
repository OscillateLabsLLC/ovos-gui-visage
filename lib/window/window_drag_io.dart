import 'dart:async';

import 'package:window_manager/window_manager.dart';

import 'plugin_calls.dart';
import 'widget_placement.dart';
import 'widget_placement_io.dart';
import 'window_config.dart';
import 'window_shell_io.dart';

/// How long the window must stay still after a drag before it counts as dropped.
const dragSettleAfter = Duration(milliseconds: 400);

/// Drag a widget to another corner. A drag on the widget hands the move to the window manager, which owns the
/// pointer until the button is released and tells the app only that the window moves; once the moves stop, the
/// window is read back and [onCorner] gets the corner of the work area it is nearest to, so the widget snaps there
/// and the corner is saved. Try-on mode owns the gestures while it is active, so the shell does not start a drag then.
/// Native Wayland cannot report the window's position, so there the window stays where it is dropped and nothing is
/// saved (measured: every drop read as `topLeft`, issue #13).
class WindowDrag with WindowListener {
  WindowDrag({
    required this.config,
    required this.onCorner,
    this.settleAfter = dragSettleAfter,
    this.placement = widgetPlacement,
    this.readDrop = droppedCorner,
  });

  final WindowConfig Function() config;
  final void Function(Corner corner) onCorner;
  final Duration settleAfter;
  final Future<WidgetPlacement> Function() placement;

  /// The corner the dropped window is nearest to, or null when it cannot be read (already reported).
  final Future<Corner?> Function() readDrop;
  bool _dragging = false;
  Timer? _settle;

  void attach() => windowManager.addListener(this);

  void start() {
    if (!config().isWidget) return;
    _dragging = true;
    unawaited(attemptPluginCall('startDragging', windowManager.startDragging));
    _arm();
  }

  @override
  void onWindowMove() {
    if (_dragging) _arm();
  }

  void dispose() {
    _settle?.cancel();
    windowManager.removeListener(this);
  }

  void _arm() {
    _settle?.cancel();
    _settle = Timer(settleAfter, () => unawaited(_settled()));
  }

  Future<void> _settled() async {
    _dragging = false;
    if (!(await placement()).snapsAfterDrag) return;
    final corner = await readDrop();
    if (corner != null) onCorner(corner);
  }
}

Future<Corner?> droppedCorner() async {
  final window = await attemptPluginCall('getBounds after a drag', windowManager.getBounds);
  final area = await attemptPluginCall('work area after a drag', workArea);
  if (window == null || area == null) return null;
  return nearestCorner(window, area);
}
