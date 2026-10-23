import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/widgets/notification_popups.dart';
import 'package:ovos_gui_visage/widgets/notification_stack.dart';
import 'package:ovos_gui_visage/widgets/widget_manager.dart';

import 'corebus_fixture.dart';
import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

void main() {
  late RecordingBus bus;
  late ManualTimers timers;
  late NotificationPopups popups;
  late WidgetManager manager;

  setUp(() {
    bus = RecordingBus();
    timers = ManualTimers();
    popups = NotificationPopups(timer: timers.create, onExpired: (record) => manager.popClear(record));
    manager = WidgetManager(bus, clock: () => 1.0, popups: popups);
  });

  void replay(String fixture, {int? first}) {
    final messages = coreBusFixture(fixture);
    for (final (type, data) in messages.take(first ?? messages.length)) {
      bus.send(type, data);
    }
  }

  List<String> texts() => [for (final p in popups.all) p.text];

  test('the recorded transient and sticky notifications pop up, oldest first', () {
    replay('notifications_api', first: 2);
    expect(texts(), ['Missed timer: pasta', 'Battery low']);
    expect([for (final p in popups.all) p.kind], [PopupKind.transient, PopupKind.sticky]);
    expect(popups.all.last.style, 'warning');
  });

  test('a transient stays its duration, then clears to storage as the shell does; a sticky has no timer', () {
    replay('notifications_api', first: 2);
    expect(timers.pending.single.after, const Duration(seconds: 10));
    timers.fireAll();
    expect(texts(), ['Battery low']);
    expect(manager.storage.single['text'], 'Missed timer: pasta');
    expect(manager.notifications.single['text'], 'Battery low');
  });

  test('the controlled notification updates in place and goes on remove', () {
    replay('notifications_api', first: 3);
    final id = popups.controlled!.id;
    expect(popups.all.first.text, 'Downloading update 40%');
    replay('notifications_api', first: 4);
    expect(texts().where((t) => t.startsWith('Downloading')), ['Downloading update 80%']);
    expect(popups.controlled!.id, id);
    replay('notifications_api');
    expect(popups.controlled, isNull);
    expect(bus.types.last, 'ovos.notification.controlled.type.remove');
  });

  test('a sticky stays until its clear arrives on the bus', () {
    replay('notifications_sticky_cleared', first: 1);
    timers.fireAll();
    expect(texts(), ['Battery low']);
    replay('notifications_sticky_cleared');
    expect(popups.all, isEmpty);
  });

  test('a cleared transient cancels its timer and is not cleared twice', () {
    var expired = 0;
    final local = NotificationPopups(timer: timers.create, onExpired: (_) => expired++);
    local.show({'sender': 's', 'text': 't', 'duration': 3});
    local.cleared({'sender': 's', 'text': 't'});
    expect(timers.pending, isEmpty);
    expect(expired, 0);
  });

  test('a duration that is not a positive number is reported and falls back to ten seconds', () async {
    final faults = await collectFaults(() async => popups.show({'sender': 's', 'text': 't', 'duration': 'soon'}));
    expect(faults, hasLength(1));
    expect(timers.pending.single.after, const Duration(seconds: defaultPopupSeconds));
  });

  testWidgets('the stack shows at most three popups and counts the rest', (tester) async {
    for (var i = 0; i < 5; i++) {
      popups.show({'sender': 's', 'text': 'note $i', 'duration': 10, 'style': i == 0 ? 'error' : 'info'});
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: NotificationStack(popups: popups.all)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PopupCard), findsNWidgets(maxPopupsShown));
    expect(find.text('note 0'), findsOneWidget);
    expect(find.text('+2 more'), findsOneWidget);
    expect(popupColour('error'), popupStyleColours['error']);
    expect(popupColour('sparkly'), popupStyleColours['info']);
  });
}
