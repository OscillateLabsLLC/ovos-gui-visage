import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/attention.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/screen_link.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

/// The adapter's own recordings, in the order ovos-gui really calls it: session_update, template, then activated.
void main() {
  test('text_then_weather: weather ends on top with its last data, hello beneath; nothing but the weather gap', () async {
    final gaps = freshGaps();
    late GuiState state;
    final faults = await collectFaults(() async {
      final face = FaceController();
      final attention = Attention(face);
      state = GuiState();
      for (final frame in loadRecorded('text_then_weather')) {
        applyGui1(state, attention, frame, gaps: gaps);
      }
      attention.dispose();
      expect(resolve(state.current(), gaps: gaps.templates), same(FallbackPage.page));
    });
    expect(state.active, [weather, hello]);
    expect(state.namespace(weather).data['current'], 22);
    expect(faults.map((f) => '${f.exception}'), ['UnimplementedError: SYSTEM_weather has no page yet']);
  });

  test('text_then_weather: its snapshot alone gives the same state as the stream', () {
    final streamed = replayGui1(loadRecorded('text_then_weather'));
    final joined = replayGui1(loadRecorded('text_then_weather_snapshot'));
    expect(joined.snapshot(), equals(streamed.snapshot()));
  });

  testWidgets('text_then_weather: after the first three frames the text page renders', (tester) async {
    final state = replayGui1(loadRecorded('text_then_weather').take(3).toList());
    expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
    await tester.pumpWidget(host(pageOf(state)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TextFramePage), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });

  test('weather_then_clear: hello shows again, then the session empties and idle is honoured', () {
    final logs = <String>[];
    final frames = loadRecorded('weather_then_clear');
    expect(frames, hasLength(12));
    final gaps = freshGaps(logs);
    final state = replayGui1(frames.take(10).toList(), gaps: gaps);
    expect(state.current(), const Target(hello, 'SYSTEM_text', 0));
    replayGui1(frames.skip(10).toList(), state: state, gaps: gaps);
    expect([state.active, state.namespaces, logs], [isEmpty, isEmpty, isEmpty]);
    expect(frames.last, isA<Gui1Idle>());
  });

  test('weather_then_clear: its snapshot is the empty stack it ends with', () {
    final joined = replayGui1(loadRecorded('weather_then_clear_snapshot'));
    expect(joined.snapshot(), equals(replayGui1(loadRecorded('weather_then_clear')).snapshot()));
  });
}
