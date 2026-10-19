import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'kiosk_cursor.dart';
import 'peek.dart';
import 'window_config.dart';

/// What sits behind the 480 x 800 frame: nothing for a widget, so the rounded frame floats; the page colour for an
/// ordinary window; black for kiosk, so the bars beside the frame read as the screen's edge.
Color windowBackground(WindowMode mode) => switch (mode) {
  WindowMode.window => VisageColors.bg,
  WindowMode.kiosk => Colors.black,
  WindowMode.float || WindowMode.desktop => Colors.transparent,
};

/// The whole window around the frame. In kiosk mode Escape calls [onLeaveKiosk] and the pointer hides after
/// [cursorHideAfter] without movement. A drag on a widget calls [onDragStart], which hands the window to the window
/// manager to move. The tree is the same in every mode, so switching keeps the page's state.
class WindowSurface extends StatefulWidget {
  const WindowSurface({
    super.key,
    required this.mode,
    required this.onLeaveKiosk,
    required this.child,
    this.onDragStart,
    this.timer,
  });

  final WindowMode mode;
  final VoidCallback onLeaveKiosk;

  /// Null where the window cannot be dragged: an ordinary window, kiosk, or while try-on mode owns the gestures.
  final VoidCallback? onDragStart;
  final Widget child;

  /// Tests pass manual timers; the app uses real ones.
  final TimerFactory? timer;

  @override
  State<WindowSurface> createState() => _WindowSurfaceState();
}

class _WindowSurfaceState extends State<WindowSurface> {
  late final CursorHider cursor = CursorHider(timer: widget.timer)..addListener(_changed);

  bool get _kiosk => widget.mode == WindowMode.kiosk;

  @override
  void initState() {
    super.initState();
    cursor.setEnabled(_kiosk);
  }

  @override
  void didUpdateWidget(WindowSurface old) {
    super.didUpdateWidget(old);
    cursor.setEnabled(_kiosk);
  }

  @override
  void dispose() {
    cursor.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _draggable => widget.onDragStart != null && (widget.mode == WindowMode.float || widget.mode == WindowMode.desktop);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {if (_kiosk) const SingleActivator(LogicalKeyboardKey.escape): widget.onLeaveKiosk},
      child: Focus(
        autofocus: true,
        child: MouseRegion(
          cursor: cursor.hidden ? SystemMouseCursors.none : MouseCursor.defer,
          onHover: (_) => cursor.moved(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: _draggable ? (_) => widget.onDragStart!() : null,
            child: ColoredBox(color: windowBackground(widget.mode), child: widget.child),
          ),
        ),
      ),
    );
  }
}
