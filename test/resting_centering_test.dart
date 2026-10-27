import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/idle_page.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/widgets/home_chips.dart';

import 'gui1_fixture.dart';

/// Past the chips' entrance, so the measure is the layout and not a frame of the motion.
const _settled = Duration(seconds: 1);

void main() {
  testWidgets('the resting chips sit on the page centre line, with and without the weather chip', (tester) async {
    const weather = {
      ambientWeather: {'current_temp': 21, 'condition': 'Cloudy', 'condition_code': 'cloudy'},
      ambientNotifications: {'count': 2},
    };
    await tester.pumpWidget(host(RestingPage(ambient: weather, now: () => restingNow)));
    await tester.pump(_settled);
    final page = tester.getCenter(find.byType(RestingPage));
    expect(tester.getCenter(find.byType(ClockChip)).dx, page.dx);
    expect(tester.getCenter(find.byType(WeatherChip)).dx, page.dx);
    final top = tester.getTopLeft(find.byType(WeatherChip)).dy;
    final bottom = tester.getBottomLeft(find.byType(ClockChip)).dy;
    expect((top + bottom) / 2, closeTo(page.dy, 1), reason: 'the column is centred vertically');
    await tester.pumpWidget(host(RestingPage(ambient: const {}, now: () => restingNow)));
    await tester.pump(_settled);
    expect(tester.getCenter(find.byType(ClockChip)), tester.getCenter(find.byType(RestingPage)));
  });

  testWidgets('the homescreen idle page centres its chips the same way', (tester) async {
    const data = {'time_string': '09:05', 'weekday_string': 'Saturday', 'day_string': '17', 'month_string': 'October'};
    await tester.pumpWidget(host(IdlePage(data: data, events: const {}, storedNotifications: 1, onShowNotifications: () {})));
    await tester.pump(_settled);
    expect(tester.getCenter(find.byType(ClockChip)).dx, tester.getCenter(find.byType(IdlePage)).dx);
  });
}
