import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/widgets/notification_list.dart';
import 'package:ovos_gui_visage/widgets/notification_popups.dart';
import 'package:ovos_gui_visage/widgets/stored_notifications.dart';
import 'package:ovos_gui_visage/widgets/widget_manager.dart';

import 'corebus_fixture.dart';
import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

class _ClosedBus extends CoreBus {
  @override
  bool emit(String type, [Json? data]) => false;
}

const _texts = ['Visage test: tap to run my action', 'Visage test: battery low, no action', 'Visage test: update installed'];

void main() {
  late RecordingBus bus;
  late ManualTimers timers;
  late WidgetManager manager;
  late NotificationListController list;

  setUp(() {
    bus = RecordingBus();
    timers = ManualTimers();
    final popups = NotificationPopups(timer: timers.create, onExpired: (record) => manager.popClear(record));
    manager = WidgetManager(bus, clock: () => 1.0, popups: popups);
    list = NotificationListController(bus: bus, storage: manager.stored);
  });

  /// The three recorded notifications pop up and expire to storage, as they did on the live display.
  void storeThree() {
    for (final (type, data) in coreBusFixture('notifications_stored').take(3)) {
      bus.send(type, data);
    }
    timers.fireAll();
    bus.emitted.clear();
  }

  List<String> texts() => [for (final item in list.items) item.text];

  test('the list shows what expired to storage, oldest first, with sender, style and whether it acts', () {
    storeThree();
    expect(texts(), _texts);
    expect([for (final i in list.items) i.style], ['info', 'warning', 'success']);
    expect([for (final i in list.items) i.hasAction], [true, false, true]);
    expect(list.items.first.sender, 'visage-test');
  });

  test('a clear from another client (the alerts skill sends sender and text only) removes the item', () {
    storeThree();
    final (type, data) = coreBusFixture('notifications_stored').last;
    bus.send(type, data);
    expect(texts(), [_texts[0], _texts[2]]);
  });

  test('it opens over an empty store too (the badge count can be a producer\'s), and closes once a filled store empties', () {
    list.open();
    expect(list.isOpen, isTrue, reason: 'a tap on the badge always shows the list, empty or not');
    list.close();
    storeThree();
    list.open();
    expect(list.isOpen, isTrue);
    bus.send(storageClear);
    expect(list.isOpen, isFalse);
  });

  test('Escape closes an open list and reports whether there was one', () {
    storeThree();
    expect(list.dismiss(), isFalse);
    list.open();
    expect(list.dismiss(), isTrue);
    expect(list.isOpen, isFalse);
  });

  test('opening and closing tells the shell, which holds a peeking widget open meanwhile', () {
    final changes = <bool>[];
    list = NotificationListController(bus: bus, storage: manager.stored, onOpenChanged: changes.add);
    storeThree();
    list.open();
    list.open();
    list.close();
    expect(changes, [true, false]);
  });

  test('a tap on the text runs the action, then clears the item', () {
    storeThree();
    list.act(list.items.first);
    expect(bus.emitted, [
      [
        'visage.test.notification.action',
        {'n': 1},
      ],
      [
        storageClearItem,
        {'notification': list.items.first.record},
      ],
    ]);
  });

  test('without an action a tap only clears; the clear button never runs the action; clear all clears all', () {
    storeThree();
    final [acting, plain, _] = list.items;
    list.act(plain);
    list.clear(acting);
    list.clearAll();
    expect(bus.types, [storageClearItem, storageClearItem, storageClear]);
    expect(bus.data(1), {'notification': acting.record});
    expect(bus.data(2), <String, dynamic>{});
  });

  test('a closed bus is reported, and an action that could not leave is not followed by its clear', () async {
    final records = ValueNotifier<List<Json>>([
      {'sender': 's', 'text': 't', 'action': 'some.action', 'callback_data': {}},
    ]);
    list = NotificationListController(bus: _ClosedBus(), storage: records);
    final faults = await collectFaults(() async => list.act(list.items.single));
    expect(faults.single.context!.toDescription(), contains('some.action'));
    expect('${faults.single.exception}', contains('not connected'));
  });

  test('the recorded outgoing messages are what the list builds from the same records', () {
    final lines = [
      for (final line in File('test/fixtures/outgoing/notification_list.jsonl').readAsLinesSync())
        if (line.trim().isNotEmpty) jsonDecode(line) as Json,
    ];
    final cleared = [for (final l in lines.where((l) => l['type'] == storageClearItem)) l['data']['notification'] as Json];
    final acting = StoredNotification(cleared.first);
    expect([for (final m in actMessages(acting)) m.type], [lines[0]['type'], storageClearItem]);
    expect([for (final m in actMessages(acting)) m.data], [lines[0]['data'], lines[1]['data']]);
    final plain = clearItemMessage(StoredNotification(cleared[1]));
    expect([plain.type, plain.data], [lines[2]['type'], lines[2]['data']]);
    final all = clearAllMessage();
    expect([all.type, all.data], [lines[3]['type'], lines[3]['data']]);
  });
}
