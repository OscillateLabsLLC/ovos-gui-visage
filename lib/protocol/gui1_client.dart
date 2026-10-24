/// GUI-1 adapter client (WIRE.md): connect, say `hello`, take the `welcome` within [welcomeTimeout], then deliver
/// every frame typed. One connection per call to [Gui1Client.connect]; [GuiLink] owns the reconnect loop and the
/// choice between this and the legacy GuiClient.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../faults.dart';
import 'gui1_frames.dart';

export 'gui1_frames.dart';

const welcomeTimeout = Duration(seconds: 3);

/// The socket as the client uses it, so tests can script a server without one.
abstract interface class Gui1Socket {
  Future<void> get ready;
  Stream<dynamic> get stream;
  void add(String text);
  Future<void> close();
}

typedef Gui1Connector = Gui1Socket Function(Uri url);

Gui1Socket webSocketConnector(Uri url) => _ChannelSocket(WebSocketChannel.connect(url));

class _ChannelSocket implements Gui1Socket {
  _ChannelSocket(this.channel);

  final WebSocketChannel channel;

  @override
  Future<void> get ready => channel.ready;

  @override
  Stream<dynamic> get stream => channel.stream;

  @override
  void add(String text) => channel.sink.add(text);

  @override
  Future<void> close() async => channel.sink.close();
}

class Gui1Client {
  Gui1Client({
    required this.url,
    required this.onFrame,
    required this.onStatus,
    this.sessionId = defaultSessionId,
    this.connector = webSocketConnector,
    this.timeout = welcomeTimeout,
    this.log,
  });

  final Uri url;
  final void Function(Gui1Frame frame) onFrame;
  final void Function(bool connected) onStatus;
  final String sessionId;
  final Gui1Connector connector;

  /// How long the probe waits for `welcome`, from the start of the connection.
  final Duration timeout;
  final void Function(String)? log;
  Gui1Socket? _socket;
  StreamIterator<dynamic>? _frames;

  bool get connected => _socket != null;

  /// True once a welcome for this protocol, version and session arrives within [timeout]. A refusal, a timeout, an `error` or
  /// any other first frame is logged with its reason and gives false, with the socket closed.
  Future<bool> connect() async {
    final socket = connector(url);
    final frames = StreamIterator<dynamic>(socket.stream);
    try {
      final welcome = await _handshake(socket, frames).timeout(timeout);
      log?.call('GUI-1: welcomed at $url by ${welcome.server}, session ${welcome.sessionId}');
    } on Object catch (err) {
      log?.call('GUI-1 unavailable at $url: $err');
      _discard(socket, frames);
      return false;
    }
    _socket = socket;
    _frames = frames;
    return true;
  }

  /// Reports the connection up, then delivers frames until the socket closes; [connect] must have succeeded.
  Future<void> listen() async {
    final frames = _frames ?? (throw StateError('GUI-1 listen before a welcome'));
    onStatus(true);
    try {
      while (await frames.moveNext()) {
        _deliver(frames.current);
      }
      log?.call('GUI-1 socket closed');
    } on Object catch (err) {
      log?.call('GUI-1 socket failed: $err');
    }
    if (_socket == null) return;
    _socket = null;
    _frames = null;
    onStatus(false);
  }

  Future<void> stop() async {
    final socket = _socket;
    _socket = null;
    await _frames?.cancel();
    _frames = null;
    await socket?.close();
  }

  Future<Gui1Welcome> _handshake(Gui1Socket socket, StreamIterator<dynamic> frames) async {
    await socket.ready;
    socket.add(jsonEncode(helloFrame(sessionId: sessionId)));
    if (!await frames.moveNext()) throw StateError('closed before welcome');
    return switch (parseGui1Frame(_decode(frames.current))) {
      final Gui1Welcome w when w.protocol == gui1Protocol && w.version == gui1Version && w.sessionId == sessionId => w,
      Gui1Welcome(:final protocol, :final version, sessionId: final session) => throw StateError(
        'welcome for $protocol v$version session $session, asked for $gui1Protocol v$gui1Version session $sessionId',
      ),
      Gui1Error(:final reason) => throw StateError('error: $reason'),
      _ => throw StateError('first frame was not welcome: ${frames.current}'),
    };
  }

  /// A frame that will not decode or parse, or a handler that throws, is a fault to report with the payload; the
  /// socket and the rest of the state stay.
  void _deliver(dynamic raw) {
    try {
      onFrame(parseGui1Frame(_decode(raw)));
    } on Object catch (err, stack) {
      reportFault('GUI-1 frame $raw', err, stack);
    }
  }

  /// Not awaited: a socket that never opened may never finish closing, and the probe must not wait on it.
  void _discard(Gui1Socket socket, StreamIterator<dynamic> frames) {
    void logClose(Object err) => log?.call('GUI-1 close after a failed probe: $err');
    unawaited(frames.cancel().then((_) {}, onError: logClose));
    unawaited(socket.close().then((_) {}, onError: logClose));
  }
}

Json _decode(dynamic raw) {
  if (raw is! String) throw FormatException('GUI-1 frames are text', raw);
  return jsonDecode(raw) as Json;
}
