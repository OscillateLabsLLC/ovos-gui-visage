/// OVOS core messagebus client: one reconnecting websocket with handlers keyed by message type (port of bus.py).
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef Json = Map<String, dynamic>;
typedef BusHandler = void Function(Json message);

const defaultBusUrl = 'ws://127.0.0.1:8181/core';
const reconnectDelay = Duration(seconds: 3);
const _source = 'ovos-gui-visage';

class CoreBus {
  CoreBus({this.url = defaultBusUrl, this.log});

  final String url;
  final void Function(String)? log;
  final Map<String, List<BusHandler>> _handlers = {};
  WebSocketChannel? _channel;
  bool _running = false;
  Completer<void> _connected = Completer();

  bool get connected => _channel != null;

  Future<void> get whenConnected => _connected.future;

  void on(String type, BusHandler handler) => _handlers.putIfAbsent(type, () => []).add(handler);

  void start() {
    _running = true;
    unawaited(_keepConnected());
  }

  Future<void> stop() async {
    _running = false;
    await _channel?.sink.close();
    _channel = null;
  }

  bool emit(String type, [Json? data]) {
    final channel = _channel;
    if (channel == null) {
      log?.call('bus not connected; dropping $type');
      return false;
    }
    channel.sink.add(jsonEncode({'type': type, 'data': data ?? {}, 'context': {'source': _source}}));
    return true;
  }

  void dispatch(Json message) {
    for (final handler in _handlers[message['type']] ?? const <BusHandler>[]) {
      handler(message);
    }
  }

  Future<void> _keepConnected() async {
    while (_running) {
      try {
        await _holdConnection();
      } on Object catch (err) {
        log?.call('bus unavailable at $url: $err');
      }
      _channel = null;
      if (_connected.isCompleted) _connected = Completer();
      if (_running) await Future.delayed(reconnectDelay);
    }
  }

  Future<void> _holdConnection() async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    await channel.ready;
    _channel = channel;
    _connected.complete();
    log?.call('connected to messagebus at $url');
    await for (final frame in channel.stream) {
      if (frame is String) dispatch(jsonDecode(frame) as Json);
    }
    log?.call('messagebus connection closed');
  }
}
