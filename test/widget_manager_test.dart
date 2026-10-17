// Port of tests/test_widgets.py against a recording bus.
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/widgets/widget_manager.dart';

class RecordingBus extends CoreBus {
  final Map<String, BusHandler> handlers = {};
  /// [type, data] pairs; lists so the matchers compare them structurally (records would compare maps by identity).
  final List<List<Object?>> emitted = [];

  List<String> get types => [for (final e in emitted) e[0] as String];

  Json? data(int index) => emitted[index][1] as Json?;

  @override
  void on(String type, BusHandler handler) => handlers[type] = handler;

  @override
  bool emit(String type, [Json? data]) {
    emitted.add([type, data]);
    return true;
  }

  void send(String type, [Json? data]) => handlers[type]!({'type': type, 'data': data ?? {}});
}

void main() {
  late RecordingBus bus;
  late List<String> logged;

  setUp(() {
    bus = RecordingBus();
    logged = [];
    WidgetManager(bus, clock: () => 1.0, log: logged.add);
  });

  for (final (kind, typed) in const [('timer', 'timer'), ('alarm', 'alarm'), ('audio', 'media')]) {
    test('$kind widget messages are translated to $typed ones', () {
      final widget = {'count': 1, 'action': 'ovos.gui.show.pending.${kind}s'};
      bus.send('ovos.widgets.display', {'type': kind, 'data': widget});
      bus.send('ovos.widgets.update', {'type': kind, 'data': widget});
      bus.send('ovos.widgets.remove', {'type': kind, 'data': widget});
      expect(bus.emitted, [
        ['ovos.widgets.$typed.display', {'widget': widget}],
        ['ovos.widgets.$typed.update', {'widget': widget}],
        ['ovos.widgets.$typed.remove', null],
      ]);
    });
  }

  test('unknown widget type is logged, not emitted', () {
    bus.send('ovos.widgets.update', {'type': 'weather', 'data': {}});
    expect(bus.emitted, isEmpty);
    expect(logged.single, contains('unknown widget type'));
  });

  test('notification set emits immediately and dedupes', () {
    final note = {'sender': 'alerts', 'text': 'Missed timer', 'duration': 5};
    bus.send('ovos.notification.api.set', note);
    bus.send('ovos.notification.api.set', note);
    expect(bus.types, [
      'ovos.notification.update_counter',
      'ovos.notification.notification_data',
      'ovos.notification.show',
    ]);
    expect(bus.data(0), {'notification_counter': 1});
    final record = bus.data(1)!['notification'] as Json;
    expect(record['style'], 'info');
    expect(record['callback_data'], isEmpty);
    expect(record['timestamp'], 1.0);
  });

  test('pop.clear moves to storage and the storage ops work', () {
    final note = {'sender': 'alerts', 'text': 'Missed timer'};
    bus.send('ovos.notification.api.set', note);
    bus.send('ovos.notification.api.pop.clear', {'notification': note});
    bus.send('ovos.notification.api.pop.clear', {'notification': note});
    bus.send('ovos.notification.api.request.storage.model');
    final models = [
      for (final e in bus.emitted)
        if (e[0] == 'ovos.notification.update_storage_model') e[1] as Json,
    ];
    expect(models.length, 2);
    expect(models.last['notification_model'], {'storedmodel': [note], 'count': 1});
    bus.send('ovos.notification.api.storage.clear.item', {'notification': note});
    expect((bus.data(bus.emitted.length - 1)!['notification_model'] as Json)['count'], 0);
    bus.send('ovos.notification.api.storage.clear');
    expect(bus.data(bus.emitted.length - 1)!['notification_model'], {'storedmodel': [], 'count': 0});
  });

  test('pop.clear.delete and controlled notifications', () {
    final note = {'sender': 's', 'text': 't'};
    bus.send('ovos.notification.api.set', note);
    bus.send('ovos.notification.api.pop.clear.delete', {'notification': note});
    bus.send('ovos.notification.api.pop.clear.delete', {});
    bus.send('ovos.notification.api.storage.clear.item', {});
    bus.send('ovos.notification.api.set', note);
    expect(bus.emitted[bus.emitted.length - 3], ['ovos.notification.update_counter', {'notification_counter': 1}]);
    bus.send('ovos.notification.api.set.controlled', {'sender': 's', 'text': 'busy'});
    bus.send('ovos.notification.api.remove.controlled');
    expect(bus.types[bus.types.length - 2], 'ovos.notification.controlled.type.show');
    expect(bus.emitted.last, ['ovos.notification.controlled.type.remove', null]);
  });
}
