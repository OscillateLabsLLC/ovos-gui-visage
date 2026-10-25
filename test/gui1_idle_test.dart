/// `idle` per session (WIRE.md, amendment D; it supersedes finding F16) and the snapshot's ambient map (finding F34).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const _idle = Gui1Idle(sessionId: defaultSessionId);
const _kitchenIdle = Gui1Idle(sessionId: 'kitchen');

void main() {
  test("this session's idle empties the state even while it shows a page, and keeps the ambient data", () async {
    final state = replayGui1([
      status(ambientNotifications, {'count': 1}),
      template(hello, 'SYSTEM_text', {'text': 'x'}),
      _idle,
    ]);
    expect([state.active, state.namespaces, state.current()], [isEmpty, isEmpty, isNull]);
    expect(state.ambient[ambientNotifications], {'count': 1});
  });

  test("another session's idle is reported once and changes nothing", () async {
    final gaps = freshGaps();
    late GuiState state;
    final faults = await collectFaults(() async {
      state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'x'}),
        _kitchenIdle,
        _kitchenIdle,
      ], gaps: gaps);
    });
    expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
    expect(faults.map((f) => '${f.exception}'), ['Bad state: idle for session kitchen, this display is default; ignored']);
  });

  test('a snapshot applies its ambient map over the kept one, and leaves topics it does not name', () {
    final state = replayGui1([
      status(ambientNotifications, {'count': 4}),
      const Gui1Snapshot(
        sessionId: defaultSessionId,
        stack: [],
        ambient: {
          ambientWeather: {'current_temp': 21, 'condition': 'Cloudy'},
        },
      ),
    ]);
    expect(state.ambient, {
      ambientNotifications: {'count': 4},
      ambientWeather: {'current_temp': 21, 'condition': 'Cloudy'},
    });
  });

  test('a snapshot ambient entry outside gui.ambient.* is reported and not kept; one lacking keys is reported', () async {
    late GuiState state;
    final faults = await collectFaults(() async {
      state = replayGui1([
        const Gui1Snapshot(
          sessionId: defaultSessionId,
          stack: [],
          ambient: {
            'ovos.utterance.speak': {'utterance': 'hi'},
            ambientWeather: {'condition': 'Cloudy'},
          },
        ),
      ]);
    });
    expect(state.ambient.keys, [ambientWeather]);
    expect(faults.map((f) => '${f.exception}'), [contains('ovos.utterance.speak'), contains('lacks current_temp')]);
  });

  test('every hand-written and recorded idle names the default session', () {
    final frames = [
      ...loadGui1Fixture('idle'),
      ...loadGui1Fixture('resting_ambient'),
      ...loadRecorded('weather_then_clear'),
      ...loadDemo('full_demo'),
    ];
    final idles = frames.whereType<Gui1Idle>().toList();
    expect(idles, hasLength(22));
    expect(idles.map((f) => f.sessionId).toSet(), {defaultSessionId});
  });
}
