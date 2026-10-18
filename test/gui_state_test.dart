// Every recorded fixture replayed through GuiState must match the Python reference's snapshot (test/fixtures/expected,
// generated from ovos_visage/state.py). Regenerate the goldens from the Python repo when the reference changes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

final fixtures = Directory('test/fixtures');

List<Json> loadFixture(File file) => [
  for (final line in file.readAsLinesSync())
    if (line.trim().isNotEmpty) jsonDecode(line) as Json,
];

GuiState replay(List<Json> messages, [GuiState? state]) {
  state ??= GuiState();
  for (final message in messages) {
    expect(state.apply(message), isTrue, reason: jsonEncode(message));
  }
  return state;
}

void main() {
  final files = fixtures.listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  test('fixtures are present', () => expect(files.length, 14));

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.jsonl', '');
    test('$name matches the Python reference', () {
      final golden = jsonDecode(File('test/fixtures/expected/$name.json').readAsStringSync()) as Json;
      final state = replay(loadFixture(file));
      expect(jsonDecode(jsonEncode(state.snapshot())), equals(golden['snapshot']));
      final current = state.current();
      expect(current == null ? null : [current.namespace, current.page], equals(golden['current']));
    });
  }

  test('boot sync shows the homescreen idle page', () {
    final state = replay(loadFixture(File('test/fixtures/boot_sync_idle.jsonl')));
    expect(state.active, [defaultIdleNamespace]);
    expect(state.current(), const Target(defaultIdleNamespace, 'idle', 0));
  });

  test('unknown messages are refused; malformed ones throw with their cause', () {
    final state = GuiState();
    expect(state.apply({'type': 'nope'}), isFalse);
    expect(() => state.apply({'type': 'mycroft.session.set', 'namespace': 'x'}), throwsA(isA<MalformedMessage>()));
    expect(state.current(), isNull);
  });
}
