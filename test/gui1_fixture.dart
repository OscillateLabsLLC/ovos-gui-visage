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

/// The `_note` of a hand-written fixture names its source: WIRE.md, the spec section (with or without a section sign)
/// and commit it was written from, or, for a template only a draft amendment defines, that amendment of
/// gui1-upstream SPEC_PROPOSALS.md.
final handWritten = {
  '_note': matches(
    RegExp(
      r'^written from (WIRE\.md|gui-1\.md §?[\d.]+( and §?[\d.]+)* at [0-9a-f]{7}|SPEC_PROPOSALS\.md amendment [A-G]), not recorded$',
    ),
  ),
};

/// `written from gui-1.md <section> at <sha>, not recorded`, the section sign optional.
final fromSpec = RegExp(r'^written from gui-1\.md §?\d+(\.\d+)*( and §?\d+(\.\d+)*)* at [0-9a-f]{7,40}, not recorded$');

List<Gui1Frame> _parse(Iterable<String> lines) => [for (final line in lines) parseGui1Frame(jsonDecode(line) as Json)];

List<String> _lines(String path) => File(path).readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();

/// A hand-written fixture's frames after its `_note` line, the handshake's `welcome` included.
List<Gui1Frame> loadGui1Fixture(String scenario) {
  final lines = _lines('test/fixtures/gui1/$scenario.jsonl');
  final note = jsonDecode(lines.first) as Json;
  expect(note.keys, ['_note'], reason: '$scenario starts with its note');
  expect(note['_note'], anyOf(handWritten['_note'], matches(fromSpec)), reason: '$scenario says it is hand-written');
  return _parse(lines.skip(1));
}

/// A fixture recorded from ovos-gui-plugin-visage (`test/fixtures/gui1` there, at `67fbaca`, copied unchanged): the
/// frames after the handshake, without a snapshot; `<scenario>_snapshot.jsonl` holds the snapshot a late joiner gets.
List<Gui1Frame> loadRecorded(String name) => _parse(_lines('test/fixtures/gui1/recorded/$name.jsonl'));

/// The `_note` of a recording the demo skill drove: when, the adapter's dump client, and the utterances it served.
final recordedDemo = RegExp(
  r'^recorded \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z by ovos-gui-plugin-visage tool/dump_client\.py \(client-side wire frames\) '
  r'while ovos-skill-gui1-demo served: \S.*$',
);

/// A fixture `ovos-skill-gui1-demo` recorded through the adapter (`fixtures/gui1` there): the frames after its `_note`,
/// without the welcome or the first snapshot. Each `idle` was given `"session_id": "default"` by a script for
/// amendment D, and the `_note` ends by saying so.
List<Gui1Frame> loadDemo(String name) {
  final lines = _lines('test/fixtures/gui1/recorded/demo/$name.jsonl');
  final note = jsonDecode(lines.first) as Json;
  expect(note.keys, ['_note'], reason: '$name starts with its note');
  expect(note['_note'], matches(recordedDemo), reason: '$name says how it was recorded');
  return _parse(lines.skip(1));
}

/// A Gui1Gaps of its own per test, so one test's reports never silence another's.
Gui1Gaps freshGaps() => Gui1Gaps(templates: TemplateGaps());

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

/// The fixed time the resting page tests read: Saturday 17 October 2026, 09:05.
final restingNow = DateTime(2026, 10, 17, 9, 5);

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
