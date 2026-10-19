/// The widget window over the bus, as face_remote.dart does for the face, and the one owner of the window's state that
/// the menu bar item reads (status_menu.dart). Client-only message names.
///
/// - `visage.window.set` with `peek` (bool) turns peek mode on or off and saves it; with `expanded` (bool) it
///   expands or collapses the window once, without changing the config; with `visible` (bool) it shows or hides the
///   window for this run; with `mode` (`float`, `desktop` or `kiosk`) it moves a widget above or beneath other
///   windows, or fills the screen, and saves it. Any mode can enter and leave `kiosk`; otherwise an ordinary window
///   cannot become a widget while running, nor a widget an ordinary window.
/// - `visage.window.get` asks for the state.
/// - `visage.window.state` answers both and announces every change: `mode`, `corner`, `peek`, `peekSize`,
///   `expanded`, `visible`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../protocol/core_bus.dart';
import 'peek.dart';
import 'window_config.dart';

const windowSetMessage = 'visage.window.set';
const windowGetMessage = 'visage.window.get';
const windowStateMessage = 'visage.window.state';

typedef WindowPersist = Future<void> Function(WindowConfig config);

/// Moves the native window into [config]'s mode from [from]; [expanded] is the peek state it lands in.
typedef WindowModeEffect = Future<void> Function(WindowConfig config, {required WindowMode from, required bool expanded});

/// What the native window does when the state changes: window_shell.dart on the desktop, fakes in tests.
class WindowEffects {
  const WindowEffects({required this.mode, required this.visible});

  final WindowModeEffect mode;
  final Future<void> Function(bool visible) visible;
}

class WindowRemote extends ChangeNotifier {
  WindowRemote(this.bus, this.peek, {required WindowConfig initial, required this.persist, required this.effects, this.log})
    : _config = initial {
    bus.on(windowSetMessage, _onSet);
    bus.on(windowGetMessage, (_) => announce());
    peek.addListener(announce);
    unawaited(bus.whenConnected.then((_) => announce()));
  }

  final CoreBus bus;
  final PeekController peek;
  final WindowPersist persist;
  final WindowEffects effects;
  final void Function(String)? log;
  WindowConfig _config;
  bool _visible = true;

  WindowConfig get config => _config;

  bool get visible => _visible;

  void _onSet(Json message) {
    final data = message['data'];
    if (data is! Map || !['peek', 'expanded', 'visible'].every((key) => _boolOrAbsent(data[key])) || !_modeOk(data)) {
      reportFault(
        '$windowSetMessage wants an object with bool `peek`, `expanded`, `visible` and string `mode`',
        FormatException('$message'),
      );
      return;
    }
    if (data['peek'] case final bool on) setPeek(on);
    if (data['expanded'] case final bool expanded) peek.setExpanded(expanded);
    if (data['visible'] case final bool visible) setVisible(visible);
    if (data['mode'] case final String mode) _setModeNamed(mode);
  }

  /// Turns peek on or off, remembers it for the next start, and tells the bus.
  void setPeek(bool on) {
    _config = _config.copyWith(peek: on);
    log?.call('window peek is now $on');
    _save();
    final peekChanges = _config.isWidget && peek.enabled != on;
    peekChanges ? peek.setEnabled(on) : announce();
    notifyListeners();
  }

  /// Shows or hides the window for this run; a hidden face at the next start would look like a crash, so it is not saved.
  void setVisible(bool on) {
    _visible = on;
    log?.call('window visible is now $on');
    _apply('showing or hiding the window (visible: $on)', effects.visible(on));
    announce();
    notifyListeners();
  }

  /// Changes the mode and remembers it. Peek follows: it stops in kiosk and comes back with a widget. Between an
  /// ordinary window and a widget is reported and ignored; the current mode only announces.
  void setMode(WindowMode mode) {
    final from = _config.mode;
    if (mode == from) return announce();
    if (!_switches(from, mode)) {
      reportFault('window mode ${from.name} -> ${mode.name}', StateError('a window and a widget do not switch at runtime'));
      return;
    }
    _config = _config.copyWith(mode: mode, kioskExit: mode == WindowMode.kiosk ? from : null);
    log?.call('window mode is now ${mode.name}');
    _save();
    final peekChanges = peek.enabled != _config.peeks;
    if (peekChanges) peek.setEnabled(_config.peeks);
    _apply('moving the window to ${mode.name}', effects.mode(_config, from: from, expanded: peek.expanded));
    if (!peekChanges) announce();
    notifyListeners();
  }

  /// Escape and the menu: back to the mode kiosk was entered from.
  void leaveKiosk() {
    if (_config.isKiosk) setMode(_config.kioskExit);
  }

  void toggleKiosk() => _config.isKiosk ? leaveKiosk() : setMode(WindowMode.kiosk);

  void _setModeNamed(String name) {
    final mode = WindowMode.values.where((m) => m.name == name).firstOrNull;
    if (mode != null) return setMode(mode);
    reportFault('$windowSetMessage mode "$name"', ArgumentError.value(name, 'mode', 'not window, float, desktop or kiosk'));
  }

  void _save() => _apply('saving the window to the config file', persist(_config));

  void _apply(String what, Future<void> effect) =>
      unawaited(effect.catchError((Object err, StackTrace stack) => reportFault(what, err, stack)));

  void announce() => bus.emit(windowStateMessage, state());

  Json state() => {
    'mode': _config.mode.name,
    'corner': _config.corner.name,
    'peek': _config.peek,
    'peekSize': _config.peekSize,
    'expanded': peek.expanded,
    'visible': _visible,
  };
}

bool _switches(WindowMode from, WindowMode to) =>
    from == WindowMode.kiosk || to == WindowMode.kiosk || (from != WindowMode.window && to != WindowMode.window);

bool _boolOrAbsent(Object? value) => value == null || value is bool;

bool _modeOk(Map<dynamic, dynamic> data) => data['mode'] == null || data['mode'] is String;
