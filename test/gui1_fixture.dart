import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const hello = 'ovos-skill-hello.openvoiceos';
const alerts = 'ovos-skill-alerts.openvoiceos';
const weather = 'ovos-skill-weather.openvoiceos';

/// The `_note` of a hand-written fixture names its source: WIRE.md, or the spec section (with or without a section
/// sign) and commit it was written from.
final handWritten = {'_note': matches(RegExp(r'^written from (WIRE\.md|gui-1\.md §?[\d.]+ at [0-9a-f]{7}), not recorded$'))};

List<Gui1Frame> _parse(Iterable<String> lines) => [for (final line in lines) parseGui1Frame(jsonDecode(line) as Json)];

List<String> _lines(String path) => File(path).readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();

/// A hand-written fixture's frames after its `_note` line, the handshake's `welcome` included.
List<Gui1Frame> loadGui1Fixture(String scenario) {
  final lines = _lines('test/fixtures/gui1/$scenario.jsonl');
  expect(jsonDecode(lines.first), handWritten, reason: '$scenario says it is hand-written');
  return _parse(lines.skip(1));
}

/// A fixture recorded from ovos-gui-plugin-visage (`test/fixtures/gui1` there, copied unchanged): the frames after the
/// handshake, without a snapshot; `<scenario>_snapshot.jsonl` holds the snapshot a late joiner gets.
List<Gui1Frame> loadRecorded(String name) => _parse(_lines('test/fixtures/gui1/recorded/$name.jsonl'));

/// A Gui1Gaps of its own per test, so one test's reports never silence another's.
Gui1Gaps freshGaps([List<String>? logs]) => Gui1Gaps(templates: TemplateGaps(), log: logs?.add ?? (_) {});

GuiState replayGui1(List<Gui1Frame> frames, {Gui1Gaps? gaps, GuiState? state}) {
  state ??= GuiState();
  final told = gaps ?? freshGaps();
  for (final frame in frames) {
    applyGui1Frame(state, frame, gaps: told);
  }
  return state;
}

Gui1Template template(String skill, String name, Json data, {String session = defaultSessionId}) =>
    Gui1Template(skillId: skill, template: name, data: data, sessionId: session);

Gui1Status status(String topic, [Json data = const {}]) => Gui1Status(eventName: topic, data: data, sessionId: defaultSessionId);

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 736, child: page)),
  ),
);

Widget pageOf(GuiState state, {TemplateGaps? gaps}) {
  final target = state.current()!;
  final ctx = PageContext(namespace: target.namespace, page: target.page, events: const {});
  return resolve(target, gaps: gaps ?? TemplateGaps())(state.namespace(target.namespace).data, ctx);
}
