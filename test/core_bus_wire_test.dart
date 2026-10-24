import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';

void main() {
  test('emit writes the same bytes as before; emitWithContext adds its keys beside source', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = StreamController<String>();
    server.listen((request) async => (await WebSocketTransformer.upgrade(request)).listen((m) => received.add(m as String)));
    final bus = CoreBus(url: 'ws://127.0.0.1:${server.port}/core')..start();
    await bus.whenConnected;
    final frames = StreamIterator(received.stream);

    bus.emit('ovos.common_play.resume');
    bus.emit('x.y', {'a': 1});
    bus.emitWithContext('x.y', {'a': 1}, {'gui_framework': 'html'});
    final lines = [for (var i = 0; i < 3; i++) await frames.moveNext().then((_) => frames.current)];
    expect(lines, [
      '{"type":"ovos.common_play.resume","data":{},"context":{"source":"ovos-gui-visage"}}',
      '{"type":"x.y","data":{"a":1},"context":{"source":"ovos-gui-visage"}}',
      '{"type":"x.y","data":{"a":1},"context":{"source":"ovos-gui-visage","gui_framework":"html"}}',
    ]);
    await bus.stop();
    await server.close(force: true);
  });
}
