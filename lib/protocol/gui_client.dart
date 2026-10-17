/// GUI websocket protocol client for ovos-gui (SPEC 5.1): announce on the core bus, get the port, connect, announce
/// again on the GUI socket (without the second announcement ovos-gui treats the socket as qt5). Port of gui_client.py.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'core_bus.dart';

const framework = 'html';
const guiRoute = '/gui';
const portTimeout = Duration(seconds: 10);

typedef GuiMessageHandler = void Function(Json message);
typedef GuiStatusHandler = void Function(bool connected);

Json announcement(String guiId) => {'gui_id': guiId, 'framework': framework};

/// ovos-gui reads `parameters` (not `data`) from client events and takes the namespace from `skillId`.
Json focusMessage(String namespace, int number) => {
      'type': 'mycroft.events.triggered',
      'namespace': namespace,
      'event_name': 'page_gained_focus',
      'parameters': {'number': number, 'skillId': namespace},
    };

class GuiClient {
  GuiClient({required this.bus, required this.guiId, required this.onMessage, required this.onStatus, this.log}) {
    bus.on('mycroft.gui.port', _onPort);
  }

  final CoreBus bus;
  final String guiId;
  final GuiMessageHandler onMessage;
  final GuiStatusHandler onStatus;
  final void Function(String)? log;
  Completer<int>? _portWaiter;
  WebSocketChannel? _channel;
  bool _running = false;

  bool get connected => _channel != null;

  void start() {
    _running = true;
    unawaited(_keepConnected());
  }

  Future<void> stop() async {
    _running = false;
    await _channel?.sink.close();
    _channel = null;
  }

  bool send(Json message) {
    final channel = _channel;
    if (channel == null) {
      log?.call('GUI socket not connected; dropping $message');
      return false;
    }
    channel.sink.add(jsonEncode(message));
    return true;
  }

  Uri guiUrl(int port) => Uri.parse(bus.url).replace(port: port, path: guiRoute);

  Future<void> _keepConnected() async {
    while (_running) {
      try {
        final port = await _negotiatePort();
        await _holdGuiSocket(port);
      } on Object catch (err) {
        log?.call('GUI socket unavailable: $err');
      }
      if (_channel != null) {
        _channel = null;
        onStatus(false);
      }
      if (_running) await Future.delayed(reconnectDelay);
    }
  }

  Future<int> _negotiatePort() async {
    await bus.whenConnected;
    final waiter = _portWaiter = Completer<int>();
    bus.emit('mycroft.gui.connected', announcement(guiId));
    log?.call('sent mycroft.gui.connected on the core bus (gui_id=$guiId, framework=$framework)');
    try {
      return await waiter.future.timeout(portTimeout);
    } finally {
      _portWaiter = null;
    }
  }

  void _onPort(Json message) {
    final data = (message['data'] ?? <String, dynamic>{}) as Json;
    if (data['gui_id'] != guiId) return;
    final waiter = _portWaiter;
    if (waiter == null || waiter.isCompleted) return;
    log?.call('mycroft.gui.port -> $data');
    waiter.complete((data['port'] as num).toInt());
  }

  Future<void> _holdGuiSocket(int port) async {
    final url = guiUrl(port);
    final channel = WebSocketChannel.connect(url);
    await channel.ready;
    _channel = channel;
    channel.sink.add(jsonEncode({'type': 'mycroft.gui.connected', ...announcement(guiId)}));
    log?.call('connected to $url and re-announced framework=$framework on the GUI socket');
    onStatus(true);
    await for (final frame in channel.stream) {
      if (frame is String) _deliver(jsonDecode(frame) as Json);
    }
    log?.call('GUI socket closed');
  }

  /// A handler fault is a bug to log loudly, not a reason to drop the socket and lose state.
  void _deliver(Json message) {
    try {
      onMessage(message);
    } on Object catch (err, stack) {
      log?.call('GUI message handler failed on $message: $err\n$stack');
    }
  }
}
