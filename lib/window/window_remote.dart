/// The widget window over the bus, as face_remote.dart does for the face, and the one owner of the window's state that
/// the menu bar item reads (status_menu.dart). Client-only message names.
///
/// - `visage.window.set` with `peek` (bool) turns peek mode on or off and saves it; with `expanded` (bool) it
///   expands or collapses the window once, without changing the config; with `visible` (bool) it shows or hides the
///   window for this run; with `mode` (`float` or `desktop`) it moves a widget above or beneath other windows and
///   saves it. An ordinary window cannot become a widget while running, nor a widget an ordinary window.
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

/// What the native window does when the state changes: window_shell.dart on the desktop, fakes in tests.
class WindowEffects {
  const WindowEffects({required this.mode, required this.visible});

  final Future<void> Function(WindowMode mode) mode;
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

  /// Moves a widget between `float` and `desktop` and remembers it; anything else is reported and ignored.
  void setMode(WindowMode mode) {
    if (mode == WindowMode.window || !_config.isWidget) {
      reportFault('window mode ${_config.mode.name} -> ${mode.name}', StateError('only float and desktop switch at runtime'));
      return;
    }
    _config = _config.copyWith(mode: mode);
    log?.call('window mode is now ${mode.name}');
    _save();
    _apply('moving the window to ${mode.name}', effects.mode(mode));
    announce();
    notifyListeners();
  }

  void _setModeNamed(String name) {
    final mode = WindowMode.values.where((m) => m.name == name).firstOrNull;
    if (mode != null) return setMode(mode);
    reportFault('$windowSetMessage mode "$name"', ArgumentError.value(name, 'mode', 'not float or desktop'));
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

bool _boolOrAbsent(Object? value) => value == null || value is bool;

bool _modeOk(Map<dynamic, dynamic> data) => data['mode'] == null || data['mode'] is String;
