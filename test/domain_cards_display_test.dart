import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/clock_page.dart';
import 'package:ovos_gui_visage/pages/map_page.dart';
import 'package:ovos_gui_visage/pages/system_timer_page.dart';
import 'package:ovos_gui_visage/pages/system_weather_page.dart';
import 'package:ovos_gui_visage/pages/timer_page.dart';
import 'package:ovos_gui_visage/shell_overlays.dart' show attentionStrip;
import 'package:ovos_gui_visage/widgets/motion_icon.dart';

const frame = Size(480, 800);
const cornerWidget = Size(240, 400);
const endTime = 1792929600;

final pulse = find.descendant(of: find.byType(SystemTimerPage), matching: find.byType(FadeTransition));

DateTime secondsBefore(int seconds) => DateTime.fromMillisecondsSinceEpoch((endTime - seconds) * 1000);

/// ScreenFrame's page padding: 24 at the sides, 32 above, and 32 below, or the attention strip while the face is
/// compact (lib/screen_frame.dart, lib/shell_overlays.dart), leaving 432 x 736 or 432 x 650.
EdgeInsets pagePadding({bool compactFace = false}) => EdgeInsets.fromLTRB(24, 32, 24, compactFace ? attentionStrip : 32);

/// The page in the 480 x 800 frame, scaled into [window] as the shell does (lib/main.dart, FittedBox).
Widget framed(Widget page, {Size window = frame, bool still = false, bool compactFace = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: window, disableAnimations: still),
    child: Center(
      child: SizedBox.fromSize(
        size: window,
        child: FittedBox(
          child: SizedBox.fromSize(
            size: frame,
            child: Material(
              child: Padding(
                padding: pagePadding(compactFace: compactFace),
                child: page,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Map<String, Widget> pages(DateTime Function() now) => {
  'clock': ClockPage(now: now),
  'timer': SystemTimerPage(data: const {'end_time': endTime, 'label': 'Pasta'}, now: now),
  'weather': SystemWeatherPage(
    data: {
      'current_temp': 21,
      'min_temp': 14,
      'max_temp': 25,
      'condition': 'Sunny',
      'condition_code': 'clear',
      'location': 'San Antonio',
      'forecast': [
        for (var day = 0; day < 4; day++)
          {'time': endTime + day * 86400, 'min_temp': 12, 'max_temp': 101, 'condition_code': 'rain'},
      ],
    },
  ),
  'map': const MapPage(data: {'latitude': 29.4252, 'longitude': -98.4946, 'label': 'The Alamo'}),
};

void main() {
  for (final (window, compactFace) in [(frame, false), (frame, true), (cornerWidget, false), (cornerWidget, true)]) {
    final size = '${window.width.round()} x ${window.height.round()}';
    testWidgets('every domain card lays out in $size${compactFace ? ' beside the compact face' : ''} without overflow', (
      tester,
    ) async {
      for (final MapEntry(key: name, value: page) in pages(() => secondsBefore(90)).entries) {
        await tester.pumpWidget(framed(page, window: window, compactFace: compactFace));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: name);
      }
    });
  }

  testWidgets('reduced motion: the clock still ticks', (tester) async {
    var now = DateTime(2026, 10, 25, 9, 59, 59);
    await tester.pumpWidget(framed(ClockPage(now: () => now), still: true));
    expect(find.text('9:59'), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('reduced motion: the timer still counts down, and the expired ring holds instead of pulsing', (tester) async {
    var now = secondsBefore(2);
    Widget timer({required bool still}) => framed(
      SystemTimerPage(data: const {'end_time': endTime}, now: () => now),
      still: still,
    );
    await tester.pumpWidget(timer(still: true));
    expect(find.text('0:02'), findsOneWidget);
    now = secondsBefore(-1);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(finished), findsOneWidget);
    expect(pulse, findsNothing);

    await tester.pumpWidget(timer(still: false));
    expect(pulse, findsOneWidget, reason: 'the pulse runs when motion is allowed');
  });

  testWidgets('reduced motion: the weather icon draws its still frame', (tester) async {
    await tester.pumpWidget(framed(pages(DateTime.now)['weather']!, still: true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MotionIcon), findsNWidgets(4), reason: 'now, and three of the four forecast entries');
    expect(find.text('21°'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
