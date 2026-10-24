import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/attention.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/status_page.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/screen_link.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';

const hello = 'ovos-skill-hello.openvoiceos';
const alerts = 'ovos-skill-alerts.openvoiceos';
const weather = 'ovos-skill-weather.openvoiceos';
const handWritten = {'_note': 'written from WIRE.md, not recorded'};

/// The fixture's frames after its `_note` line, the handshake's `welcome` included.
List<Gui1Frame> loadGui1Fixture(String scenario) {
  final lines = File('test/fixtures/gui1/$scenario.jsonl').readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
  expect(jsonDecode(lines.first), handWritten, reason: '$scenario says it is hand-written');
  return [for (final line in lines.skip(1)) parseGui1Frame(jsonDecode(line) as Json)];
}

GuiState replayGui1(List<Gui1Frame> frames, {TemplateGaps? gaps, GuiState? state}) {
  state ??= GuiState();
  for (final frame in frames) {
    applyGui1Frame(state, frame, gaps: gaps ?? TemplateGaps());
  }
  return state;
}

Gui1Template template(String skill, String name, Json data, {String session = defaultSessionId}) =>
    Gui1Template(skillId: skill, template: name, data: data, sessionId: session);

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

void main() {
  group('frames', () {
    test('a template before any activated shows exactly that page and activates the namespace', () {
      final state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'Hello'}),
      ]);
      expect(state.active, [hello]);
      expect(state.namespace(hello).pages, ['SYSTEM_text']);
      expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
    });

    test('a later template replaces the page and the whole data map', () {
      final state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'Hello', 'title': 'Hi'}),
        template(hello, 'SYSTEM_status', {'label': 'ok', 'success': true}),
      ]);
      expect(state.namespace(hello).pages, ['SYSTEM_status']);
      expect(state.namespace(hello).data, {'label': 'ok', 'success': true});
    });

    test('session_update replaces the data, never merges, and does not activate', () {
      final state = replayGui1([
        const Gui1SessionUpdate(skillId: hello, data: {'a': 1, 'b': 2}, sessionId: defaultSessionId),
        const Gui1SessionUpdate(skillId: hello, data: {'b': 3}, sessionId: defaultSessionId),
      ]);
      expect(state.namespace(hello).data, {'b': 3});
      expect(state.active, isEmpty);
    });

    test('activated moves a namespace to the top; one without a page lets the next one show', () {
      final state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'Hello'}),
        template(alerts, 'SYSTEM_text', {'text': 'Timer'}),
        const Gui1Activated(skillId: hello, sessionId: defaultSessionId),
      ]);
      expect(state.active, [hello, alerts]);
      replayGui1([const Gui1Activated(skillId: weather, sessionId: defaultSessionId)], state: state);
      expect(state.active, [weather, hello, alerts]);
      expect(state.current()?.namespace, hello);
    });

    test('deactivated drops the namespace and its data', () {
      final state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'Hello'}),
        const Gui1Deactivated(skillId: hello, sessionId: defaultSessionId),
      ]);
      expect(state.active, isEmpty);
      expect(state.namespaces, isEmpty);
      expect(state.current(), isNull);
    });

    test('a frame for another session is reported and changes nothing', () async {
      final state = GuiState();
      final faults = await collectFaults(() async {
        replayGui1([
          template(hello, 'SYSTEM_text', {'text': 'x'}, session: 'kitchen'),
        ], state: state);
      });
      expect(state.namespaces, isEmpty);
      expect(faults.map((f) => '${f.exception}'), ['Bad state: frame for session kitchen, this display is default']);
    });

    test('status, welcome and error change no state', () {
      final state = replayGui1([
        const Gui1Status(eventName: 'speak', data: {}),
        const Gui1Welcome(protocol: gui1Protocol, version: 1, sessionId: defaultSessionId, server: 's'),
        const Gui1Error('x'),
      ]);
      expect(state.snapshot(), GuiState().snapshot());
    });
  });

  group('fixtures', () {
    testWidgets('text_then_weather: the text page renders, then weather degrades with one report', (tester) async {
      final frames = loadGui1Fixture('text_then_weather');
      final state = replayGui1(frames.take(5).toList());
      expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
      expect(state.namespace(hello).data, {'title': 'Hi', 'text': 'Hello'});
      await tester.pumpWidget(host(pageOf(state)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFramePage), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('HI'), findsOneWidget);

      replayGui1(frames.skip(5).toList(), state: state);
      expect(state.active, [weather, hello]);
      final gaps = TemplateGaps();
      final faults = await collectFaults(() async => expect(resolve(state.current(), gaps: gaps), same(FallbackPage.page)));
      expect(faults.map((f) => '${f.exception}'), ['UnimplementedError: SYSTEM_weather has no page yet']);
    });

    test('two_namespaces_deactivate: the remaining namespace shows again', () {
      final state = replayGui1(loadGui1Fixture('two_namespaces_deactivate'));
      expect(state.active, [hello]);
      expect(state.namespaces.keys, [hello]);
      expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
    });

    test('idle: the stack empties, so the face shows over a blank screen', () {
      final state = replayGui1(loadGui1Fixture('idle'));
      expect(state.active, isEmpty);
      expect(state.current(), isNull);
      expect(isContentPage(state.current(), state.idleNamespace), isFalse);
    });

    testWidgets('snapshot_late_joiner: the whole stack in order, the top page renders', (tester) async {
      final state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'stale'}),
        ...loadGui1Fixture('snapshot_late_joiner'),
      ]);
      expect(state.active, [alerts, hello, weather]);
      expect(state.namespace(weather).pages, isEmpty);
      expect(state.namespace(weather).data['location'], 'San Antonio');
      expect(state.namespace(hello).data, {'title': 'Hi', 'text': 'Hello'});
      expect(state.current(), const Target(alerts, 'SYSTEM_status', 0));
      await tester.pumpWidget(host(pageOf(state)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(StatusPage), findsOneWidget);
      expect(find.text('Timer set'), findsOneWidget);
    });

    test('status_events: status frames drive the face like the legacy system events', () {
      final face = FaceController();
      final attention = Attention(face);
      final state = GuiState();
      final modes = <FaceMode>[];
      for (final frame in loadGui1Fixture('status_events')) {
        applyGui1(state, attention, frame);
        if (frame is Gui1Status) modes.add(face.mode);
      }
      expect(modes, [FaceMode.listening, FaceMode.thinking, FaceMode.speaking, FaceMode.rest]);
      expect(attention.shown, isTrue, reason: 'the face fades a second after audio ends');
      expect(state.current(), const Target(hello, 'SYSTEM_status', 0));
      attention.dispose();
    });

    test('a status event Visage does not know changes nothing and reports nothing', () async {
      final face = FaceController();
      final attention = Attention(face);
      final faults = await collectFaults(() async {
        applyGui1(GuiState(), attention, const Gui1Status(eventName: 'ovos.hologram.started', data: {'x': 1}));
      });
      expect([faults, attention.shown, face.mode], [isEmpty, false, FaceMode.rest]);
      attention.dispose();
    });

    testWidgets('status_events: SYSTEM_status with success true renders the success state', (tester) async {
      final state = replayGui1(loadGui1Fixture('status_events'));
      await tester.pumpWidget(host(pageOf(state)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Done'), findsOneWidget);
      expect(find.byKey(const ValueKey(true)), findsOneWidget);
    });

    test('unknown_template: shows the fallback, reported once through TemplateGaps', () async {
      final gaps = TemplateGaps();
      late GuiState state;
      final faults = await collectFaults(() async {
        state = replayGui1(loadGui1Fixture('unknown_template'), gaps: gaps);
        expect(resolve(state.current(), gaps: gaps), same(FallbackPage.page));
      });
      expect(state.current(), const Target(hello, 'SYSTEM_hologram', 0));
      expect(state.namespace(hello).data, {'text': 'again'});
      expect(faults, hasLength(1), reason: 'reported once for two frames');
      expect(faults.single.exceptionAsString(), allOf(contains('SYSTEM_hologram'), contains('not a GUI-1 template')));
    });

    test('every GUI-1 fixture says it is hand-written and parses', () {
      final files = Directory('test/fixtures/gui1').listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'));
      expect(files.length, 6);
      for (final file in files) {
        final name = file.uri.pathSegments.last.replaceAll('.jsonl', '');
        expect(loadGui1Fixture(name).first, isA<Gui1Welcome>(), reason: name);
      }
    });
  });
}
