/// The display's one GUI connection, over whichever protocol [mode] allows (WIRE.md, Client behaviour). `legacy` runs
/// [GuiClient] exactly as before. `auto` probes GUI-1 before every connection and falls back to legacy for that
/// connection; it never switches while a connection holds. `gui1` retries the adapter only.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core_bus.dart';
import 'gui1_client.dart';
import 'gui_client.dart';
import 'wire_protocol.dart';

export 'wire_protocol.dart';

class GuiLink {
  GuiLink({required this.mode, required this.legacy, required this.gui1, this.log}) {
    title.value = protocolTitle(mode, null);
  }

  final WireProtocol mode;
  final GuiClient legacy;
  final Gui1Client gui1;
  final void Function(String)? log;

  /// What the current connection speaks; null until the first one is chosen.
  ChosenProtocol? get chosen => _chosen;

  /// The status menu's protocol line.
  final ValueNotifier<String> title = ValueNotifier('');
  ChosenProtocol? _chosen;
  bool _running = false;

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

  /// GUI-1 has no reply leg (spec §7.2), so a page's events and focus changes have nowhere to go on it: logged, not
  /// sent.
  bool send(Json message) {
    if (_chosen != ChosenProtocol.gui1) return legacy.send(message);
    log?.call('GUI-1 has no reply leg; not sent: $message');
    return false;
  }

  Future<void> _keepConnected() async {
    while (_running) {
      await _connectOnce();
      if (_running) await Future.delayed(reconnectDelay);
    }
  }

  Future<void> _connectOnce() async {
    if (await gui1.connect()) {
      _choose(ChosenProtocol.gui1);
      return gui1.listen();
    }
    if (mode == WireProtocol.gui1 || !_running) return;
    _choose(ChosenProtocol.legacy);
    await legacy.connectOnce();
  }

  void _choose(ChosenProtocol protocol) {
    log?.call('GUI protocol ($mode): ${protocol.label}${protocol == ChosenProtocol.gui1 ? ' at ${gui1.url}' : ''}');
    _chosen = protocol;
    title.value = protocolTitle(mode, protocol);
  }
}
