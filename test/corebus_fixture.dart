import 'dart:convert';
import 'dart:io';

import 'package:ovos_gui_visage/json.dart';

/// A recorded or hand-written core bus session under test/fixtures/corebus, as (type, data) in order.
List<(String, Json)> coreBusFixture(String name) => [
  for (final line in File('test/fixtures/corebus/$name.jsonl').readAsLinesSync())
    if (line.trim().isNotEmpty) _message(jsonDecode(line) as Json),
];

(String, Json) _message(Json message) => (message['type'] as String, (message['data'] ?? <String, dynamic>{}) as Json);

/// Delivers [fixture] to [handle] up to and including the first [until] message.
void replayUntil(List<(String, Json)> fixture, String until, void Function(String, Json) handle) {
  for (final (type, data) in fixture) {
    handle(type, data);
    if (type == until) return;
  }
  throw StateError('$until is not in the fixture');
}
