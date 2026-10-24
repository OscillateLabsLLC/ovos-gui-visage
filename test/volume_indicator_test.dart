import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/outcome.dart';
import 'package:ovos_gui_visage/volume.dart';
import 'package:ovos_gui_visage/widgets/offline_pill.dart';
import 'package:ovos_gui_visage/widgets/outcome_pill.dart';
import 'package:ovos_gui_visage/widgets/volume_indicator.dart';

import 'corebus_fixture.dart';
import 'manual_timers.dart';

Widget _frame(VolumeModel model, {List<Widget> before = const []}) => MaterialApp(
  home: Material(
    child: Stack(
      children: [
        TopStatus(
          children: [
            ...before,
            VolumeIndicator(showing: model.showing, level: model.level, muted: model.muted),
          ],
        ),
      ],
    ),
  ),
);

void main() {
  late ManualTimers timers;
  late VolumeModel model;

  setUp(() {
    timers = ManualTimers();
    model = VolumeModel(ask: () => true, timer: timers.create);
  });

  test('dots light in tenths with the remainder part-lit; the label reads the level or the mute', () {
    expect([for (var i = 0; i < volumeDots; i++) dotLight(0.38, i)], [1, 1, 1, closeTo(0.8, 1e-9), 0, 0, 0, 0, 0, 0]);
    expect([dotLight(0, 0), dotLight(1, 9)], [0, 1]);
    expect(volumeLabel(0.38, muted: false), '38%');
    expect(volumeLabel(0.38, muted: true), 'Muted');
    expect(volumeLabel(null, muted: false), 'Volume');
  });

  testWidgets('the recorded Mac increase shows the level the get found, then fades out of the status row', (tester) async {
    model.handle(volumeReportEvent, {'percent': 38});
    for (final (type, data) in coreBusFixture('volume_mac_plugin').skip(2).take(2)) {
      model.handle(type, data);
    }
    model.handle(volumeReportEvent, {'percent': 48});
    await tester.pumpWidget(_frame(model));
    await tester.pump(volumeFade);
    expect(find.text('48%'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    timers.fireAll();
    await tester.pumpWidget(_frame(model));
    await tester.pumpAndSettle();
    expect(find.text('48%'), findsNothing);
    expect(tester.getSize(find.byType(VolumeIndicator)), Size.zero, reason: 'hidden, it takes no room in the row');
  });

  testWidgets('the recorded mute shows the muted glyph and label', (tester) async {
    for (final (type, data) in coreBusFixture('volume_mac_plugin').take(8)) {
      model.handle(type, data);
    }
    expect(model.muted, isTrue);
    await tester.pumpWidget(_frame(model));
    await tester.pump(volumeFade);
    expect(find.text('Muted'), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(tester.getSize(find.text('Muted')).height, lessThan(20), reason: 'one line: it wrapped in a fixed 34 px box live');
  });

  testWidgets('it sits under the offline and outcome pills and, like them, lets taps through', (tester) async {
    model.handle(volumeReportEvent, {'percent': 0.5, 'muted': false});
    model.handle(volumeReportEvent, {'percent': 0.6, 'muted': false});
    await tester.pumpWidget(
      _frame(
        model,
        before: const [
          OfflinePill(),
          OutcomePill(outcome: Outcome.success),
        ],
      ),
    );
    await tester.pump(volumeFade);
    final offline = tester.getRect(find.byType(OfflinePill));
    final outcome = tester.getRect(find.text('Done'));
    final volume = tester.getRect(find.text('60%'));
    expect([offline.bottom <= outcome.top, outcome.bottom <= volume.top], [true, true]);
    final ignoring = tester.widget<IgnorePointer>(
      find.ancestor(of: find.byType(VolumeIndicator), matching: find.byType(IgnorePointer)).first,
    );
    expect(ignoring.ignoring, isTrue);
  });
}
