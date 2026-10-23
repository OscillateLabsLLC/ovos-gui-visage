import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../face/face_theme.dart';
import '../faults.dart';
import 'idle_inhibit.dart';
import 'idle_inhibit_dbus_io.dart';
import 'plugin_calls.dart';
import 'window_bounds_io.dart';
import 'window_channel.dart';
import 'window_config.dart';

/// Kiosk mode on the native window: frameless, the size of the primary display, above everything on every Space.
/// window_manager does what it can on every platform; the macOS runner adds the level above the Dock and
/// notifications, hides the Dock and the menu bar while the app is frontmost, and keeps the display awake
/// (macos/Runner/Kiosk.swift); on Linux a session-bus idle inhibit keeps it awake (idle_inhibit.dart). On macOS kiosk
/// is a regular app: an accessory app does not own the menu bar, so it cannot hide it. A call a platform lacks is
/// reported once and the rest still run (plugin_calls.dart).
Future<void> enterKiosk({required WindowMode from}) async {
  final before = from == WindowMode.window || !Platform.isMacOS ? await _attempt('getBounds', windowManager.getBounds) : null;
  if (from == WindowMode.window) _windowBounds = before;
  _beforeFullScreen = before;
  if (Platform.isMacOS) await _native('setActivationPolicy', 'regular');
  await _attempt('setAsFrameless', windowManager.setAsFrameless);
  await _attempt('setBackgroundColor', () => windowManager.setBackgroundColor(Colors.transparent));
  await _attempt('setHasShadow', () => windowManager.setHasShadow(false));
  // GTK sizes a non-resizable window at its default size, so leaving kiosk on Linux would land at 1280 x 720.
  if (Platform.isMacOS) await _attempt('setResizable', () => windowManager.setResizable(false));
  await _attempt('setVisibleOnAllWorkspaces', () => windowManager.setVisibleOnAllWorkspaces(true));
  await _attempt('setAlwaysOnTop', () => windowManager.setAlwaysOnTop(true));
  await _fillScreen();
  await _native('setWindowLevel', 'kiosk');
  await _native('setKiosk', true);
  await _keepAwake(true);
}

/// An ordinary window's frame before kiosk, so leaving puts it back where it was.
Rect? _windowBounds;

/// Off macOS, the frame the window manager gives back when fullscreen ends.
Rect? _beforeFullScreen;

/// Back to a corner widget at [bounds], or to an ordinary window with its title bar when [bounds] is null. [bounds]
/// is read after the Dock and the menu bar come back, so the work area is the one the widget will sit in.
Future<void> leaveKiosk(WindowConfig config, {Future<Rect> Function()? bounds}) async {
  await _keepAwake(false);
  await _native('setKiosk', false);
  if (!Platform.isMacOS) await _leaveFullScreen(bounds);
  if (Platform.isMacOS) await _native('setActivationPolicy', config.isWidget ? 'accessory' : 'regular');
  await _attempt('setAlwaysOnTop', () => windowManager.setAlwaysOnTop(config.mode == WindowMode.float));
  await _native('setWindowLevel', config.isWidget ? config.mode.name : 'normal');
  if (!Platform.isMacOS) {
    await _attempt('setAlwaysOnBottom', () => windowManager.setAlwaysOnBottom(config.mode == WindowMode.desktop));
  }
  if (bounds != null) return Platform.isMacOS ? _placeWidget(bounds) : null;
  await _attempt('setTitleBarStyle', () => windowManager.setTitleBarStyle(TitleBarStyle.normal));
  await _attempt('setResizable', () => windowManager.setResizable(true));
  await _attempt('setVisibleOnAllWorkspaces', () => windowManager.setVisibleOnAllWorkspaces(false));
  final screen = await _screen();
  final centred = screen == null ? null : Rect.fromCenter(center: screen.center, width: frameWidth, height: frameHeight);
  final restore = _windowBounds ?? centred;
  if (restore != null) await _attempt('setBounds', () => windowManager.setBounds(restore));
}

/// Off macOS the window manager gives the window back at the size it had before fullscreen: GTK's 1280 x 720 default
/// in the middle of the screen when the app started in kiosk, shown for most of a second before the widget moved
/// (issue #16). Unless that frame is already the widget's, the widget is hidden across the switch, sized and moved
/// while hidden, and shown in its corner. KWin places a re-shown window itself when it was last seen in that corner
/// (measured on Kubuntu 24.04: at 0,0), so the corner is set again once it shows. No wait for the Dock: the work area
/// does not change here.
Future<void> _leaveFullScreen(Future<Rect> Function()? bounds) async {
  final target = bounds == null ? null : await _attempt('work area', bounds);
  if (target == null || _sameFrame(target, _beforeFullScreen)) {
    await _attempt('setFullScreen', () => windowManager.setFullScreen(false));
    await _attempt('unmaximize', windowManager.unmaximize);
    if (target != null) await _attempt('setBounds', () => setWindowBounds(target, growing: false));
    return;
  }
  await _attempt('hide', windowManager.hide);
  await _attempt('setFullScreen', _unfullscreenHidden);
  await _attempt('unmaximize', windowManager.unmaximize);
  await _attempt('setBounds', () => setWindowBounds(target, growing: false));
  await _attempt('show', windowManager.show);
  await _attempt('setPosition', () => windowManager.setPosition(target.topLeft));
}

bool _sameFrame(Rect a, Rect? b) =>
    b != null && (a.topLeft - b.topLeft).distance < 1 && (a.bottomRight - b.bottomRight).distance < 1;

/// A single unfullscreen on the hidden window let it come back fullscreen in one switch of three (Kubuntu 24.04):
/// until GDK has seen the unmap it seems to send the request to KWin, which drops it for a window it is unmapping.
/// Asking again until GDK reports the state gone took that to none in fifteen.
Future<void> _unfullscreenHidden() async {
  for (var i = 0; i < 25; i++) {
    await windowManager.setFullScreen(false);
    if (!await windowManager.isFullScreen()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('the hidden window is still fullscreen after half a second');
}

/// Waits for the work area to grow back from the hidden Dock (at most half a second), then places the widget.
Future<void> _placeWidget(Future<Rect> Function() bounds) async {
  final hidden = await _attempt('work area', bounds);
  var target = hidden;
  for (var i = 0; i < 10 && target != null && target == hidden; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    target = await _attempt('work area', bounds);
  }
  if (target != null) await _attempt('setBounds', () => setWindowBounds(target!, growing: false));
}

/// macOS sizes the window to the display itself, since native fullscreen would make its own Space. Elsewhere the
/// window manager's fullscreen state does it: a plain window sized to the screen gets flagged maximized by KWin and
/// then refuses to shrink again (measured on Kubuntu 24.04), and fullscreen also covers the panel.
Future<void> _fillScreen() async {
  if (!Platform.isMacOS) return _attempt('setFullScreen', () => windowManager.setFullScreen(true));
  final screen = await _screen();
  if (screen != null) await _attempt('setBounds', () => setWindowBounds(screen, growing: true));
}

/// The primary display's whole area, menu bar included; null, reported, where the platform cannot say.
Future<Rect?> _screen() async {
  final display = await _attempt('getPrimaryDisplay', screenRetriever.getPrimaryDisplay);
  return display == null ? null : Offset.zero & display.size;
}

/// The Linux idle inhibit kiosk mode holds; a test swaps in a fake bus.
@visibleForTesting
IdleInhibitor kioskIdleInhibitor = IdleInhibitor(DBusInhibitBus());

Future<void> _keepAwake(bool on) async {
  if (Platform.isMacOS) return _native('setKeepAwake', on);
  await (on ? kioskIdleInhibitor.hold() : kioskIdleInhibitor.release());
}

/// Lets go of the idle inhibit before the app quits; the session bus would drop it with the connection anyway.
Future<void> releaseKioskIdleInhibit() => kioskIdleInhibitor.release();

Future<T?> _attempt<T>(String what, Future<T> Function() call) => attemptPluginCall('$what in kiosk mode', call);

/// A runner without the method is reported once; a runner that refuses an argument is reported every time.
Future<void> _native(String method, Object arguments) async {
  try {
    await windowChannel.invokeMethod<void>(method, arguments);
  } on MissingPluginException catch (err, stack) {
    reportPluginFaultOnce('$method is not implemented by this platform runner', err, stack);
  } on PlatformException catch (err, stack) {
    reportFault('$method($arguments) in kiosk mode', err, stack);
  }
}
