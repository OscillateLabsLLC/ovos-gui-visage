import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/widgets/notification_actions.dart';
import 'package:ovos_gui_visage/widgets/notification_popups.dart';
import 'package:ovos_gui_visage/widgets/notification_stack.dart';
import 'package:ovos_gui_visage/widgets/offline_pill.dart';

import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

class _ClosedBus extends CoreBus {
  @override
  bool emit(String type, [Json? data]) => false;
}

const withAction = {
  'sender': 'some.skill',
  'text': 'Tap me',
  'action': 'some.skill.do_it',
  'callback_data': {'n': 1},
  'type': 'sticky',
  'style': 'info',
};
const plain = {'sender': 'some.skill', 'text': 'Just news', 'action': '', 'type': 'transient', 'duration': 30, 'style': 'info'};

void main() {
  late NotificationPopups popups;
  late RecordingBus bus;
  late NotificationActions actions;
  late ManualTimers timers;

  setUp(() {
    timers = ManualTimers();
    popups = NotificationPopups(timer: timers.create);
    bus = RecordingBus();
    actions = NotificationActions(bus: bus, popups: popups);
  });

  test('close sends pop.clear.delete with the record and takes the popup off the display', () {
    popups.show(withAction);
    actions.close(popups.all.single);
    expect(bus.emitted.single, [
      'ovos.notification.api.pop.clear.delete',
      {'notification': withAction},
    ]);
    expect(popups.all, isEmpty);
  });

  test('a tap sends the action with its callback data; a popup without one ignores the tap', () {
    popups.show(withAction);
    popups.show(plain);
    actions.act(popups.all.last);
    expect(bus.emitted, isEmpty);
    expect(popups.all, hasLength(2));
    actions.act(popups.all.first);
    expect(bus.emitted.single, [
      'some.skill.do_it',
      {'n': 1},
    ]);
    expect(popups.all.single.text, 'Just news');
  });

  test('a dismissed transient popup does not expire to storage afterwards', () {
    final expired = <Json>[];
    popups = NotificationPopups(timer: timers.create, onExpired: expired.add);
    actions = NotificationActions(bus: bus, popups: popups);
    popups.show(plain);
    actions.close(popups.all.single);
    timers.fireAll();
    expect(expired, isEmpty);
  });

  test('the controlled popup only hides; nothing is sent', () {
    popups.showControlled({'sender': 'x', 'text': 'Working', 'style': 'info'});
    final popup = popups.all.single;
    actions.act(popup);
    expect(popups.controlled, isNotNull, reason: 'a tap on the controlled popup does nothing');
    actions.close(popup);
    expect(bus.emitted, isEmpty);
    expect(popups.controlled, isNull);
  });

  test('a closed bus is reported and the popup stays', () async {
    actions = NotificationActions(bus: _ClosedBus(), popups: popups);
    popups.show(withAction);
    final faults = await collectFaults(() async => actions.close(popups.all.single));
    expect('${faults.single.exception}', contains('not connected'));
    expect(popups.all, hasLength(1));
  });

  testWidgets('the card has a close button and its text takes the tap', (tester) async {
    popups.show(withAction);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: NotificationStack(popups: popups.all, onTap: actions.act, onClose: actions.close),
        ),
      ),
    );
    await tester.pump(popupSlide);
    await tester.tap(find.text('Tap me'));
    expect(bus.types, ['some.skill.do_it']);
    popups.show(withAction);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: NotificationStack(popups: popups.all, onTap: actions.act, onClose: actions.close),
        ),
      ),
    );
    await tester.pump(popupSlide);
    await tester.tap(find.byTooltip('Close notification'));
    expect(bus.types, ['some.skill.do_it', 'ovos.notification.api.pop.clear.delete']);
  });

  testWidgets('in the frame status row the popups take taps; the pills above them do not', (tester) async {
    popups.show(withAction);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Stack(
            children: [
              TopStatus(
                interactive: NotificationStack(popups: popups.all, onTap: actions.act, onClose: actions.close),
                children: const [OfflinePill()],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(popupSlide);
    await tester.tap(find.byTooltip('Close notification'));
    expect(bus.types, ['ovos.notification.api.pop.clear.delete']);
    expect(
      tester
          .widget<IgnorePointer>(find.ancestor(of: find.byType(OfflinePill), matching: find.byType(IgnorePointer)).first)
          .ignoring,
      isTrue,
    );
  });

  test('the recorded close and action are what the app builds from the same records', () {
    final lines = [
      for (final line in File('test/fixtures/outgoing/notification_controls.jsonl').readAsLinesSync()) jsonDecode(line) as Json,
    ];
    final closed = lines.firstWhere((l) => l['type'] == popClearDelete);
    final record = closed['data']['notification'] as Json;
    final close = closeMessage(Popup(0, PopupKind.sticky, record))!;
    expect([close.type, close.data], [closed['type'], closed['data']]);
    final acted = lines.firstWhere((l) => l['type'] != popClearDelete);
    final action = actionMessage(Popup(1, PopupKind.sticky, {...withAction, 'action': acted['type']}))!;
    expect([action.type, action.data], [acted['type'], acted['data']]);
  });
}
