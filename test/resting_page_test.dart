import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/resting_model.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/device_clock.dart';
import 'package:ovos_gui_visage/widgets/home_chips.dart';
import 'package:ovos_gui_visage/widgets/weather_icon.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const cloudy = {'current_temp': 21, 'condition': 'Cloudy', 'condition_code': 'cloudy'};

void main() {
  testWidgets('resting_ambient: after the template leaves, the resting page shows the clock and the ambient weather', (
    tester,
  ) async {
    late GuiState state;
    final faults = await collectFaults(() async => state = replayGui1(loadGui1Fixture('resting_ambient')));
    expect(faults, isEmpty);
    expect([state.active, state.current()], [isEmpty, isNull]);
    expect(state.ambient.keys, [ambientWeather, ambientNotifications]);
    expect(restingPage(state, ChosenProtocol.legacy), isNull, reason: 'legacy rests on the homescreen skill');
    await tester.pumpWidget(host(restingPage(state, ChosenProtocol.gui1, now: () => restingNow)!));
    expect([find.text('9:05'), find.text('AM'), find.text('21°'), find.byType(CountBadge)], everyElement(findsOneWidget));
    expect(tester.widget<WeatherIcon>(find.byType(WeatherIcon)).name, 'clouds');
    expect(tester.widget<CountBadge>(find.byType(CountBadge)).count, 2);
    expect(find.text('Cloudy'), findsNothing, reason: 'the icon is the one hero of the weather chip');
  });

  testWidgets('the resting clock reads the device hour format, as SYSTEM_clock does', (tester) async {
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: RestingPage(ambient: const {}, now: () => restingNow),
        ),
      ),
    );
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('AM'), findsNothing);
    await tester.pumpWidget(host(RestingPage(ambient: const {}, now: () => DateTime(2026, 10, 17, 21, 5))));
    expect([find.text('9:05'), find.text('PM')], everyElement(findsOneWidget));
  });

  testWidgets('without condition_code the weather chip shows the condition text; a zero count shows no badge', (tester) async {
    var opened = 0;
    final ambient = {
      ambientWeather: {'current_temp': 18, 'condition': 'Light rain'},
      ambientNotifications: {'count': 0},
    };
    await tester.pumpWidget(host(RestingPage(ambient: ambient, onShowNotifications: () => opened++, now: () => restingNow)));
    expect([find.text('Light rain'), find.text('18°')], everyElement(findsOneWidget));
    expect([find.byType(WeatherIcon), find.byType(CountBadge)], everyElement(findsNothing));
    await tester.pumpWidget(
      host(
        RestingPage(
          ambient: {
            ...ambient,
            ambientNotifications: {'count': 3},
          },
          onShowNotifications: () => opened++,
          now: () => restingNow,
        ),
      ),
    );
    await tester.tap(find.byType(CountBadge));
    expect([find.text('3'), opened], [findsOneWidget, 1]);
  });

  test('resting_ambient: the ambient data outlives the template, the snapshot and a reconnect', () {
    final frames = loadGui1Fixture('resting_ambient');
    final state = replayGui1(frames.take(4).toList());
    expect(state.ambient[ambientWeather]?['current_temp'], 21);
    replayGui1([...frames.skip(4), const Gui1Snapshot(sessionId: defaultSessionId, stack: [])], state: state);
    state.reset();
    expect(restingWeather(state.ambient, now: restingNow)?.temperature, '21°');
  });

  testWidgets('ambient weather is stamped on arrival and leaves the resting page three hours later, on the tick', (tester) async {
    final state = GuiState();
    applyGui1Frame(state, status(ambientWeather, cloudy), gaps: freshGaps(), now: () => restingNow);
    expect(state.ambientAt[ambientWeather], restingNow);
    var now = restingNow.add(restingWeatherLife - const Duration(minutes: 1));
    await tester.pumpWidget(host(restingPage(state, ChosenProtocol.gui1, now: () => now)!));
    expect(find.byType(WeatherIcon), findsOneWidget);
    now = restingNow.add(restingWeatherLife + const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WeatherIcon), findsNothing, reason: 'no frame arrived; the page re-read the clock');
    expect(find.text('12:06'), findsOneWidget);
    expect(state.ambient[ambientWeather], cloudy, reason: 'the payload is kept; only the chip leaves');
  });

  test('a payload of unknown age shows; a snapshot payload is stamped at the snapshot', () {
    expect(restingWeather({ambientWeather: cloudy}, now: restingNow.add(const Duration(days: 2))), isNotNull);
    final state = GuiState();
    final later = restingNow.add(const Duration(hours: 1));
    applyGui1Frame(
      state,
      const Gui1Snapshot(sessionId: defaultSessionId, stack: [], ambient: {ambientWeather: cloudy}),
      gaps: freshGaps(),
      now: () => later,
    );
    expect(state.ambientAt[ambientWeather], later);
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
    expect(restingWeather(state.ambient, now: restingNow), isNull);
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
    RestingWeather? of(Object? code, {DateTime? at}) => restingWeather({
      ambientWeather: {'current_temp': 21.6, 'condition': 'Showers', 'condition_code': code},
    }, now: at ?? restingNow);
    expect(of('thunder'), (temperature: '22°', condition: 'Showers', icon: 'storm'));
    expect(
      [of('partly_cloudy')?.icon, of('drizzle')?.icon, of('hail')?.icon, of(null)?.icon],
      ['partial_clouds', 'rain', null, null],
    );
  });

  test('a clear sky is the sun by day and the night icon from 20:00 to 06:00 by the device clock', () {
    String? iconAt(DateTime at, [String code = 'clear']) => restingWeather({
      ambientWeather: {'current_temp': 21, 'condition': 'Clear', 'condition_code': code},
    }, now: at)?.icon;
    expect(iconAt(DateTime(2026, 10, 25, 19, 59)), 'sun');
    expect(iconAt(DateTime(2026, 10, 25, 20)), 'night');
    expect(iconAt(DateTime(2026, 10, 26, 5, 59)), 'night');
    expect(iconAt(DateTime(2026, 10, 26, 6)), 'sun');
    expect(iconAt(DateTime(2026, 10, 25, 23), 'partly_cloudy'), 'partial_clouds', reason: 'no night variant is bundled');
    expect([isNightAt(DateTime(2026, 10, 25, 22)), isNightAt(DateTime(2026, 10, 25, 12))], [true, false]);
  });

  testWidgets('without ambient weather the resting page is the clock alone', (tester) async {
    await tester.pumpWidget(host(RestingPage(ambient: const {}, now: () => restingNow)));
    expect([find.byType(DeviceClock), find.text('9:05')], everyElement(findsOneWidget));
    expect(find.byType(WeatherIcon), findsNothing);
  });
}
