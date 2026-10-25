/// The display's one GUI connection, over whichever protocol [mode] allows (WIRE.md, Client behaviour). `legacy` runs
/// [GuiClient] exactly as before. `auto` probes GUI-1 before every connection and falls back to legacy for that
/// connection; it never switches while a connection holds. `gui1` retries the adapter only.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../faults.dart';
import 'core_bus.dart';
import 'gui1_client.dart';
import 'gui_client.dart';
import 'wire_protocol.dart';

export 'wire_protocol.dart';

/// The context legacy ovos-gui added to every message it forwarded from this app's GUI socket.
const forwardedContext = {'gui_framework': framework};

class GuiLink {
  GuiLink({
    required this.mode,
    required this.legacy,
    required this.gui1,
    required this.bus,
    this.log,
    this.retryDelay = reconnectDelay,
  }) {
    title.value = protocolTitle(mode, null);
  }

  final WireProtocol mode;
  final GuiClient legacy;
  final Gui1Client gui1;

  /// Where page events go on GUI-1, which has no reply leg of its own.
  final CoreBus bus;
  final void Function(String)? log;

  /// The pause between one connection ending and the next attempt.
  final Duration retryDelay;

  /// What the current connection speaks; null until the first one is chosen.
  ChosenProtocol? get chosen => _chosen;

  /// The status menu's protocol line.
  final ValueNotifier<String> title = ValueNotifier('');
  ChosenProtocol? _chosen;
  bool _running = false;
  bool _lossReported = false;

  void start() {
    if (mode == WireProtocol.legacy) {
      _choose(ChosenProtocol.legacy);
      return legacy.start();
    }
    _running = true;
    unawaited(_keepConnected());
  }

  Future<void> stop() async {
    _running = false;
    await gui1.stop();
    await legacy.stop();
  }

  /// Legacy: the GUI socket, unchanged. GUI-1 has no reply leg (gui-1.md 7.2), so Visage puts a page event on the core
  /// bus itself, as the message legacy ovos-gui would have forwarded (bus.py `on_message`, `busMessageFor`), with its
  /// `gui_framework` context. Anything but a page event is logged, not sent (finding F14).
  bool send(Json message) {
    if (_chosen != ChosenProtocol.gui1) return legacy.send(message);
    if (message['type'] != eventsTriggered) {
      log?.call('GUI-1 has no reply leg; not sent: $message');
      return false;
    }
    final forwarded = busMessageFor(message);
    final type = forwarded['type'] as String;
    final sent = bus.emitWithContext(type, forwarded['data'] as Json, forwardedContext);
    log?.call('GUI-1: ${sent ? 'forwarded' : 'could not forward'} $type on the core bus');
    return sent;
  }

  Future<void> _keepConnected() async {
    while (_running) {
      await _connectOnce();
      if (_running) await Future.delayed(retryDelay);
    }
  }

  Future<void> _connectOnce() async {
    if (await gui1.connect()) {
      _choose(ChosenProtocol.gui1);
      await gui1.listen();
      if (_running) _lost();
      return;
    }
    if (mode == WireProtocol.gui1 || !_running) return;
    _choose(ChosenProtocol.legacy);
    await legacy.connectOnce();
  }

  /// The adapter closed a welcomed connection. The menu line says so until the next probe chooses again; the first
  /// loss of the run is a fault, later ones are logged, so a flapping adapter does not flood the fault log.
  void _lost() {
    title.value = protocolTitle(mode, ChosenProtocol.gui1, lost: true);
    final lost = StateError('the GUI-1 connection to ${gui1.url} closed; reconnecting');
    if (_lossReported) return log?.call('$lost');
    _lossReported = true;
    reportFault('GUI-1 connection', lost);
  }

  void _choose(ChosenProtocol protocol) {
    log?.call('GUI protocol ($mode): ${protocol.label}${protocol == ChosenProtocol.gui1 ? ' at ${gui1.url}' : ''}');
    _chosen = protocol;
    title.value = protocolTitle(mode, protocol);
  }
}
