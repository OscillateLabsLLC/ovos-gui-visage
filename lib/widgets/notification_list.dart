/// The stored notification list: what it shows (the WidgetManager's storage), whether it is open, and what its controls
/// send on the core bus (stored_notifications.dart). The homescreen's count badge opens it; Escape or its close button
/// closes it, and it closes by itself once nothing is stored, as idle.qml closes its popup when the count reaches 0.
library;

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../protocol/core_bus.dart';
import 'notification_actions.dart';
import 'stored_notifications.dart';

class NotificationListController extends ChangeNotifier {
  NotificationListController({required this.bus, required this.storage, this.onOpenChanged}) {
    storage.addListener(_stored);
  }

  final CoreBus bus;
  final ValueListenable<List<Json>> storage;
  final void Function(bool open)? onOpenChanged;
  bool _open = false;
  bool _hadItems = false;

  bool get isOpen => _open;

  List<StoredNotification> get items => [for (final record in storage.value) StoredNotification(record)];

  /// Opens over an empty store too: on GUI-1 the badge's count comes from a producer (`gui.ambient.notifications`),
  /// so a tap can land before anything has expired into storage, and a tap that does nothing reads as broken. The
  /// panel says the store is empty.
  void open() => _set(true);

  void close() => _set(false);

  /// Escape: true when there was a list to close.
  bool dismiss() {
    if (!_open) return false;
    close();
    return true;
  }

  /// Runs the item's action, if any, then clears it; a send that fails stops there and is reported.
  void act(StoredNotification item) {
    for (final message in actMessages(item)) {
      if (!_send(message)) return;
    }
  }

  void clear(StoredNotification item) => _send(clearItemMessage(item));

  void clearAll() => _send(clearAllMessage());

  bool _send(BusMessage message) {
    if (bus.emit(message.type, message.data)) return true;
    reportFault('notification list sending ${message.type}', StateError('the core bus is not connected'));
    return false;
  }

  /// A store that empties under an open list (clear all, the last clear) closes it; a list opened over an empty
  /// store stays until the person closes it.
  void _stored() {
    if (storage.value.isEmpty && _hadItems) close();
    _hadItems = storage.value.isNotEmpty;
    notifyListeners();
  }

  void _set(bool open) {
    if (_open == open) return;
    _open = open;
    onOpenChanged?.call(open);
    notifyListeners();
  }

  @override
  void dispose() {
    storage.removeListener(_stored);
    super.dispose();
  }
}
