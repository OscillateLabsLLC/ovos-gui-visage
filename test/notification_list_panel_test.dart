import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/widgets/notification_list.dart';
import 'package:ovos_gui_visage/widgets/notification_list_panel.dart';
import 'package:ovos_gui_visage/widgets/notification_popups.dart';
import 'package:ovos_gui_visage/widgets/notification_stack.dart';
import 'package:ovos_gui_visage/widgets/stored_notifications.dart';
import 'package:ovos_gui_visage/widgets/widget_manager.dart';

import 'corebus_fixture.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

const _first = 'Visage test: tap to run my action';
const _plain = 'Visage test: battery low, no action';

void main() {
  late RecordingBus bus;
  late NotificationListController list;
  final surface = FocusNode(debugLabel: 'window surface');

  setUp(() {
    bus = RecordingBus();
    final timers = ManualTimers();
    late final WidgetManager manager;
    final popups = NotificationPopups(timer: timers.create, onExpired: (record) => manager.popClear(record));
    manager = WidgetManager(bus, clock: () => 1.0, popups: popups);
    for (final (type, data) in coreBusFixture('notifications_stored').take(3)) {
      bus.send(type, data);
    }
    timers.fireAll();
    bus.emitted.clear();
    list = NotificationListController(bus: bus, storage: manager.stored)..open();
  });

  /// The panel over a page, inside a focus node that stands in for the window surface.
  Widget frame({bool open = true}) => MaterialApp(
    home: Material(
      child: Focus(
        focusNode: surface,
        autofocus: true,
        child: SizedBox(
          width: 480,
          height: 600,
          child: Stack(
            children: [if (open) NotificationListPanel(items: list.items, controller: list)],
          ),
        ),
      ),
    ),
  );

  /// As in the app: the window surface holds the focus before the badge opens the list.
  Future<void> pumpOpen(WidgetTester tester) async {
    await tester.pumpWidget(frame(open: false));
    await tester.pump();
    expect(surface.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(frame());
    await tester.pump();
  }

  testWidgets('each item shows its sender, text and style dot, in storage order', (tester) async {
    await pumpOpen(tester);
    expect(find.text(listTitle), findsOneWidget);
    expect(find.text('visage-test'), findsNWidgets(3));
    final top = [
      for (final t in [_first, _plain, 'Visage test: update installed']) tester.getTopLeft(find.text(t)).dy,
    ];
    expect(top, orderedEquals([...top]..sort()));
    final dots = tester.widgetList<Container>(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 12));
    expect(
      [for (final d in dots) (d.decoration! as BoxDecoration).color],
      [popupColour('info'), popupColour('warning'), popupColour('success')],
    );
  });

  testWidgets('a tap on actionable text acts; plain text is not a button; the clear and clear-all buttons clear', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.text(_first));
    await tester.tap(find.text(_plain));
    expect(bus.types, ['visage.test.notification.action', storageClearItem]);
    await tester.tap(find.byTooltip('Clear notification').at(1));
    await tester.tap(find.text('Clear all'));
    expect(bus.types.skip(2), [storageClearItem, storageClear]);
    expect(bus.data(2), {'notification': list.items[1].record});
  });

  testWidgets('the close button closes the list and sends nothing', (tester) async {
    await pumpOpen(tester);
    await tester.tap(find.byTooltip('Close notifications'));
    expect(list.isOpen, isFalse);
    expect(bus.emitted, isEmpty);
  });

  testWidgets('the first item has the focus on open; Enter acts on it', (tester) async {
    await pumpOpen(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(bus.types, ['visage.test.notification.action', storageClearItem]);
  });

  testWidgets('the arrow keys move between controls: right to the clear button, down to the next row', (tester) async {
    await pumpOpen(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(bus.emitted.single, [
      storageClearItem,
      {'notification': list.items[0].record},
    ]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(bus.data(1), {'notification': list.items[1].record});
  });

  testWidgets('Escape closes the list, and the focus goes back to the window surface', (tester) async {
    await pumpOpen(tester);
    expect(surface.hasPrimaryFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(list.isOpen, isFalse);
    await tester.pumpWidget(frame(open: false));
    await tester.pump();
    expect(surface.hasPrimaryFocus, isTrue);
  });

  testWidgets('over an empty store the list opens and says so, with the close button still there', (tester) async {
    bus.send('ovos.notification.api.storage.clear', <String, dynamic>{});
    expect(list.items, isEmpty);
    list.open();
    await pumpOpen(tester);
    expect([
      find.text(emptyListText),
      find.text(emptyListHint),
      find.byTooltip('Close notifications'),
    ], everyElement(findsOneWidget));
    expect(find.byType(StoredRow), findsNothing);
    await tester.tap(find.byTooltip('Close notifications'));
    await tester.pump();
    expect(list.isOpen, isFalse);
  });
}
