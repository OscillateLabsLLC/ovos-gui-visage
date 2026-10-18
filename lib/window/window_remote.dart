/// The widget window over the bus, as face_remote.dart does for the face. Client-only message names.
///
/// - `visage.window.set` with `peek` (bool) turns peek mode on or off and saves it; with `expanded` (bool) it
///   expands or collapses the window once, without changing the config.
/// - `visage.window.get` asks for the state.
/// - `visage.window.state` answers both and announces every change: `mode`, `corner`, `peek`, `peekSize`, `expanded`.
library;

import 'dart:async';

import '../faults.dart';
import '../protocol/core_bus.dart';
import 'peek.dart';
import 'window_config.dart';

const windowSetMessage = 'visage.window.set';
const windowGetMessage = 'visage.window.get';
const windowStateMessage = 'visage.window.state';

typedef WindowPersist = Future<void> Function(WindowConfig config);

class WindowRemote {
  WindowRemote(this.bus, this.peek, {required WindowConfig initial, required this.persist, this.log}) : _config = initial {
    bus.on(windowSetMessage, _onSet);
    bus.on(windowGetMessage, (_) => announce());
    peek.addListener(announce);
    unawaited(bus.whenConnected.then((_) => announce()));
  }

  final CoreBus bus;
  final PeekController peek;
  final WindowPersist persist;
  final void Function(String)? log;
  WindowConfig _config;

  WindowConfig get config => _config;

  void _onSet(Json message) {
    final data = message['data'];
    if (data is! Map || !_boolOrAbsent(data['peek']) || !_boolOrAbsent(data['expanded'])) {
      reportFault('$windowSetMessage wants an object with bool `peek` and `expanded`', FormatException('$message'));
      return;
    }
    if (data['peek'] case final bool on) setPeek(on);
    if (data['expanded'] case final bool expanded) peek.setExpanded(expanded);
  }

  /// Turns peek on or off, remembers it for the next start, and tells the bus.
  void setPeek(bool on) {
    _config = _config.copyWith(peek: on);
    log?.call('window peek is now $on');
    persist(_config)
        .catchError((Object err, StackTrace stack) => reportFault('saving the window to the config file', err, stack));
    final peekChanges = _config.isWidget && peek.enabled != on;
    peekChanges ? peek.setEnabled(on) : announce();
  }

  void announce() => bus.emit(windowStateMessage, state());

  Json state() => {
    'mode': _config.mode.name,
    'corner': _config.corner.name,
    'peek': _config.peek,
    'peekSize': _config.peekSize,
    'expanded': peek.expanded,
  };
}

bool _boolOrAbsent(Object? value) => value == null || value is bool;
