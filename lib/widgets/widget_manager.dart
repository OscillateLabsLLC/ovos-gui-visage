/// Widget and notification translator (ovos-visage SPEC 7.2), ported from ovos-gui-plugin-shell-companion's
/// WidgetManager via widgets.py. The alerts skill emits generic `ovos.widgets.*` messages and the homescreen listens
/// for typed ones; with the `generic` gui extension nobody translates, so this does, attached to the core bus.
library;

import 'dart:convert';

import '../protocol/core_bus.dart';

const widgetTypes = {'timer': 'timer', 'alarm': 'alarm', 'audio': 'media'};
const notificationDefaults = <String, Object>{
  'duration': 10,
  'sender': '',
  'text': '',
  'action': '',
  'type': '',
  'style': 'info',
};

bool _sameNotification(Json a, Json b) => a['sender'] == b['sender'] && a['text'] == b['text'];

/// Structural equality, as Python's `record in list` compares dicts.
bool _contains(List<Json> items, Json record) {
  final wanted = jsonEncode(record);
  return items.any((item) => jsonEncode(item) == wanted);
}

class WidgetManager {
  WidgetManager(this.bus, {double Function()? clock, this.log}) : _clock = clock ?? _epochSeconds {
    for (final verb in const ['display', 'update', 'remove']) {
      bus.on('ovos.widgets.$verb', (m) => _widget(verb, m));
    }
    final handlers = <String, BusHandler>{
      'request.storage.model': (_) => emitStorageModel(),
      'set': _onSet,
      'pop.clear': _onPopClear,
      'pop.clear.delete': _onPopClearDelete,
      'storage.clear': (_) => _onStorageClear(),
      'storage.clear.item': _onStorageClearItem,
      'set.controlled': _onSetControlled,
      'remove.controlled': (_) => bus.emit('ovos.notification.controlled.type.remove'),
    };
    handlers.forEach((suffix, handler) => bus.on('ovos.notification.api.$suffix', handler));
  }

  final CoreBus bus;
  final void Function(String)? log;
  final double Function() _clock;
  final List<Json> notifications = [];
  List<Json> storage = [];

  static double _epochSeconds() => DateTime.now().millisecondsSinceEpoch / 1000;

  static Json _data(Json message) => (message['data'] ?? <String, dynamic>{}) as Json;

  void _widget(String verb, Json message) {
    final data = _data(message);
    final widget = widgetTypes[data['type'] ?? ''];
    if (widget == null) {
      log?.call('unknown widget type in $message');
      return;
    }
    bus.emit('ovos.widgets.$widget.$verb', verb == 'remove' ? null : {'widget': data['data'] ?? ''});
  }

  void emitStorageModel() {
    final model = {'storedmodel': storage, 'count': storage.length};
    bus.emit('ovos.notification.update_storage_model', {'notification_model': model});
  }

  void _onSet(Json message) {
    final data = _data(message);
    final record = {for (final e in notificationDefaults.entries) e.key: data[e.key] ?? e.value};
    record['callback_data'] = data['callback_data'] ?? <String, dynamic>{};
    record['timestamp'] = _clock();
    if (_contains(notifications, record)) return;
    notifications.add(record);
    bus.emit('ovos.notification.update_counter', {'notification_counter': notifications.length});
    bus.emit('ovos.notification.notification_data', {'notification': record});
    bus.emit('ovos.notification.show');
  }

  void _dropPending(Json notification) {
    final index = notifications.indexWhere((pending) => _sameNotification(pending, notification));
    if (index >= 0) notifications.removeAt(index);
  }

  Json? _notificationOf(Json message) {
    final notification = _data(message)['notification'];
    return notification is Json && notification.isNotEmpty ? notification : null;
  }

  void _onPopClear(Json message) {
    final notification = _notificationOf(message);
    if (notification == null || _contains(storage, notification)) return;
    storage.add(notification);
    _dropPending(notification);
    emitStorageModel();
    bus.emit('ovos.notification.notification_data', {'notification': <String, dynamic>{}});
  }

  void _onPopClearDelete(Json message) {
    final notification = _notificationOf(message);
    if (notification != null) _dropPending(notification);
  }

  void _onStorageClear() {
    storage = [];
    emitStorageModel();
  }

  void _onStorageClearItem(Json message) {
    final notification = _notificationOf(message);
    if (notification == null) return;
    storage = [
      for (final item in storage)
        if (!_sameNotification(item, notification)) item,
    ];
    emitStorageModel();
  }

  void _onSetControlled(Json message) {
    final data = _data(message);
    final record = {
      'sender': data['sender'] ?? '',
      'text': data['text'] ?? '',
      'style': data['style'] ?? 'info',
      'timestamp': _clock(),
    };
    bus.emit('ovos.notification.controlled.type.show', {'notification': record});
  }
}
