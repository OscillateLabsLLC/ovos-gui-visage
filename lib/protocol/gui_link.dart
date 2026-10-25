/// The display's one GUI connection, over whichever protocol [mode] allows (WIRE.md, Client behaviour). `legacy` runs
/// [GuiClient] exactly as before. `auto` probes GUI-1 before every connection and falls back to legacy for that
/// connection; it never switches while a connection holds. `gui1` retries the adapter only.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../faults.dart';
import 'core_bus.dart' show reconnectDelay;
import 'gui1_client.dart';
import 'gui1_outgoing.dart';
import 'gui_client.dart';
import 'wire_protocol.dart';

export 'wire_protocol.dart';

class GuiLink {
  GuiLink({required this.mode, required this.legacy, required this.gui1, this.log, this.retryDelay = reconnectDelay}) {
    title.value = protocolTitle(mode, null);
  }

  final WireProtocol mode;
  final GuiClient legacy;
  final Gui1Client gui1;

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
  bool _touchReported = false;

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

  /// Legacy: the GUI socket, unchanged. GUI-1: a page event goes to the adapter as an `interaction` or `focus` frame
  /// (gui1_outgoing.dart), never on the core bus. Anything but a page event has no GUI-1 frame and is logged, not sent.
  bool send(Json message) {
    if (_chosen != ChosenProtocol.gui1) return legacy.send(message);
    if (message['type'] != eventsTriggered) {
      log?.call('GUI-1 has no frame for $message; not sent');
      return false;
    }
    final frame = gui1FrameFor(message);
    if (frame == null) return _touchWithoutEntry(message);
    final sent = gui1.send(frame);
    log?.call('GUI-1: ${sent ? 'sent' : 'could not send'} $frame');
    return sent;
  }

  /// A user's request for entry [page] of [namespace]: a swipe, an arrow key or a chevron. GUI-1 sends it as `focus`.
  /// Legacy sends nothing here, since FocusAnnouncer reports the change once the page shows; false then.
  bool requestFocus(String namespace, int page) {
    if (_chosen != ChosenProtocol.gui1) return false;
    final frame = focusFrame(namespace, page);
    final sent = gui1.send(frame);
    log?.call('GUI-1: ${sent ? 'sent' : 'could not send'} $frame');
    return sent;
  }

  /// A touch on GUI-1 is a focus on the active entry, which the `template` frame does not name (finding F45): reported
  /// once per run, then logged.
  bool _touchWithoutEntry(Json message) {
    final unknown = StateError('a touch on GUI-1 needs the active entry, which no frame names; not sent: $message');
    if (_touchReported) {
      log?.call('$unknown');
      return false;
    }
    _touchReported = true;
    reportFault('GUI-1 touch', unknown);
    return false;
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
