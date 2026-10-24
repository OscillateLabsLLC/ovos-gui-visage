import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../volume_controls.dart';
import 'kiosk_cursor.dart';
import 'peek.dart';
import 'two_finger_tap.dart';
import 'window_config.dart';

/// What sits behind the 480 x 800 frame: nothing for a widget, so the rounded frame floats; the page colour for an
/// ordinary window; black for kiosk, so the bars beside the frame read as the screen's edge.
Color windowBackground(WindowMode mode) => switch (mode) {
  WindowMode.window => VisageColors.bg,
  WindowMode.kiosk => Colors.black,
  WindowMode.float || WindowMode.desktop => Colors.transparent,
};

final volumeKeys = {
  LogicalKeyboardKey.audioVolumeUp: VolumeAction.up,
  LogicalKeyboardKey.audioVolumeDown: VolumeAction.down,
  LogicalKeyboardKey.audioVolumeMute: VolumeAction.toggleMute,
};

/// The whole window around the frame. In kiosk mode Escape calls [onLeaveKiosk] and the pointer hides after
/// [cursorHideAfter] without movement. A drag on a widget calls [onDragStart], which hands the window to the window
/// manager to move. A right-click, a two-finger tap or the menu key calls [onMenu] with the window position; the left
/// and right arrow keys call [onStep]; the volume keys call [onVolume], where the system passes them to the app. The
/// tree is the same in every mode, so switching keeps the page's state.
class WindowSurface extends StatefulWidget {
  const WindowSurface({
    super.key,
    required this.mode,
    required this.onLeaveKiosk,
    required this.child,
    this.onDragStart,
    this.onMenu,
    this.onDismiss,
    this.onStep,
    this.onVolume,
    this.timer,
  });

  final WindowMode mode;
  final VoidCallback onLeaveKiosk;

  /// Null where the window cannot be dragged: an ordinary window, kiosk, or while try-on mode owns the gestures.
  final VoidCallback? onDragStart;
  final Widget child;

  /// Opens the menu at a position in the window; null where there is none.
  final void Function(Offset at)? onMenu;

  /// Escape closes what [onDismiss] reports open (the menu) before it leaves kiosk.
  final bool Function()? onDismiss;

  /// Moves between the active skill's pages: -1 back, 1 forward.
  final void Function(int delta)? onStep;

  /// Volume up, down and mute: sent on the bus, so the PHAL volume plugin changes the level.
  final void Function(VolumeAction action)? onVolume;

  /// Tests pass manual timers; the app uses real ones.
  final TimerFactory? timer;

  @override
  State<WindowSurface> createState() => _WindowSurfaceState();
}

class _WindowSurfaceState extends State<WindowSurface> {
  late final CursorHider cursor = CursorHider(timer: widget.timer)..addListener(_changed);
  late final TwoFingerTap twoFingers = TwoFingerTap(onTap: (at) => widget.onMenu?.call(at));

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

  Map<ShortcutActivator, VoidCallback> get _keys => {
    const SingleActivator(LogicalKeyboardKey.escape): _escape,
    if (widget.onStep case final step?) ...{
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => step(-1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => step(1),
    },
    if (widget.onMenu case final menu?) const SingleActivator(LogicalKeyboardKey.contextMenu): () => menu(_centre),
    if (widget.onVolume case final volume?)
      for (final MapEntry(key: key, value: action) in volumeKeys.entries) SingleActivator(key): () => volume(action),
  };

  void _escape() {
    if (widget.onDismiss?.call() ?? false) return;
    if (_kiosk) widget.onLeaveKiosk();
  }

  Offset get _centre => (context.size ?? Size.zero).center(Offset.zero);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _keys,
      child: Focus(
        autofocus: true,
        child: MouseRegion(
          cursor: cursor.hidden ? SystemMouseCursors.none : MouseCursor.defer,
          onHover: (_) => cursor.moved(),
          child: _touches(
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _draggable ? (_) => widget.onDragStart!() : null,
              onSecondaryTapUp: widget.onMenu == null ? null : (d) => widget.onMenu!(d.localPosition),
              child: ColoredBox(color: windowBackground(widget.mode), child: widget.child),
            ),
          ),
        ),
      ),
    );
  }

  /// Raw touches feed the two-finger tap; they pass on to the gestures below unchanged.
  Widget _touches(Widget child) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) => _touch(e) ? twoFingers.down(e.pointer, e.localPosition, e.timeStamp) : null,
    onPointerMove: (e) => _touch(e) ? twoFingers.move(e.pointer, e.localPosition) : null,
    onPointerUp: (e) => _touch(e) ? twoFingers.up(e.pointer, e.timeStamp) : null,
    onPointerCancel: (e) => _touch(e) ? twoFingers.cancel(e.pointer) : null,
    child: child,
  );

  bool _touch(PointerEvent event) => widget.onMenu != null && event.kind == PointerDeviceKind.touch;
}
