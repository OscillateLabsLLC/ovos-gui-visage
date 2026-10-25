import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/resting_model.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/device_clock.dart';
import 'package:ovos_gui_visage/widgets/weather_icon.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

void main() {
  testWidgets('resting_ambient: after the template leaves, the resting page shows the clock and the ambient weather', (
    tester,
  ) async {
    late GuiState state;
    final faults = await collectFaults(() async => state = replayGui1(loadGui1Fixture('resting_ambient')));
    expect(faults, isEmpty, reason: 'gui.ambient.notifications is kept and shows nothing, without a fault');
    expect([state.active, state.current()], [isEmpty, isNull]);
    expect(state.ambient.keys, [ambientWeather, ambientNotifications]);
    expect(restingPage(state, ChosenProtocol.legacy), isNull, reason: 'legacy rests on the homescreen skill');
    await tester.pumpWidget(host(restingPage(state, ChosenProtocol.gui1, now: () => restingNow)!));
    expect([find.text('09:05'), find.text('21°'), find.text('Cloudy')], everyElement(findsOneWidget));
    expect(tester.widget<WeatherIcon>(find.byType(WeatherIcon)).name, 'clouds');
  });

  test('resting_ambient: the ambient data outlives the template, the snapshot and a reconnect', () {
    final frames = loadGui1Fixture('resting_ambient');
    final state = replayGui1(frames.take(4).toList());
    expect(state.ambient[ambientWeather]?['current_temp'], 21);
    replayGui1([...frames.skip(4), const Gui1Snapshot(sessionId: defaultSessionId, stack: [])], state: state);
    state.reset();
    expect(restingWeather(state.ambient)?.temperature, '21°');
  });

  test('a page on the stack, or no protocol chosen yet, shows no resting page', () {
    final showing = replayGui1([
      template(hello, 'SYSTEM_text', {'text': 'Hi'}),
    ]);
    expect(showsResting(showing, ChosenProtocol.gui1), isFalse);
    expect(showsResting(GuiState(), null), isFalse);
    expect(showsResting(GuiState(), ChosenProtocol.gui1), isTrue);
  });

  test('a SYSTEM_idle template, by any name, gives its namespace no page: the page beneath or the resting page shows', () async {
    late GuiState state;
    final faults = await collectFaults(() async {
      state = replayGui1([
        template(hello, 'SYSTEM_text', {'text': 'Hi'}),
        template(alerts, 'SYSTEM_idle', {}),
      ]);
    });
    expect(
      [faults, state.active, state.current()],
      [
        isEmpty,
        [alerts, hello],
        const Target(hello, 'SYSTEM_text', 0),
      ],
    );
    replayGui1([template(hello, 'Idle.qml', {})], state: state);
    expect([state.current(), showsResting(state, ChosenProtocol.gui1)], [isNull, isTrue]);
  });

  test('weather without its required keys is kept, reported once, and not shown', () async {
    final gaps = freshGaps();
    late GuiState state;
    final faults = await collectFaults(() async {
      state = replayGui1([
        status(ambientWeather, {'temperature': 21}),
        status(ambientWeather, {'temperature': 22}),
      ], gaps: gaps);
    });
    expect(state.ambient[ambientWeather], {'temperature': 22});
    expect(restingWeather(state.ambient), isNull);
    expect(faults.single.exceptionAsString(), allOf(contains(ambientWeather), contains('current_temp, condition')));
  });

  test('an ambient topic the spec does not name is kept without a fault', () async {
    late GuiState state;
    final faults = await collectFaults(
      () async => state = replayGui1([
        status('gui.ambient.tides', {'high': '14:02'}),
      ]),
    );
    expect(
      [faults, state.ambient['gui.ambient.tides']],
      [
        isEmpty,
        {'high': '14:02'},
      ],
    );
  });

  test('condition_code picks the icon; an unlisted code has none, and the condition text still shows', () {
    RestingWeather? of(Object? code) => restingWeather({
      ambientWeather: {'current_temp': 21.6, 'condition': 'Showers', 'condition_code': code},
    });
    expect(of('thunder'), (temperature: '22°', condition: 'Showers', icon: 'storm'));
    expect(
      [of('partly_cloudy')?.icon, of('drizzle')?.icon, of('hail')?.icon, of(null)?.icon],
      ['partial_clouds', 'rain', null, null],
    );
  });

  testWidgets('without ambient weather the resting page is the clock alone', (tester) async {
    await tester.pumpWidget(host(RestingPage(ambient: const {}, now: () => restingNow)));
    expect([find.byType(DeviceClock), find.text('09:05')], everyElement(findsOneWidget));
    expect(find.byType(WeatherIcon), findsNothing);
  });
}
