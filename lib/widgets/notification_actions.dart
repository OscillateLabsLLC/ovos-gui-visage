/// What a tap on a notification popup sends, after ovos-shell's NotificationPop*.qml, which use
/// MycroftController.sendRequest, so the messages go on the core bus:
///
/// - The close button of a transient or sticky popup sends `ovos.notification.api.pop.clear.delete` with the record
///   as `notification`; a controlled popup's close only hides it.
/// - A tap on a transient or sticky popup that names an `action` sends that action with the record's
///   `callback_data` as its data.
///
/// Either way the popup leaves this display at once, as the shell's `popbox.destroy()` does.
library;

import '../faults.dart';
import '../protocol/core_bus.dart';
import 'notification_popups.dart';

const popClearDelete = 'ovos.notification.api.pop.clear.delete';

typedef BusMessage = ({String type, Json data});

/// Null for a controlled popup, whose close only hides it.
BusMessage? closeMessage(Popup popup) =>
    popup.kind == PopupKind.controlled ? null : (type: popClearDelete, data: {'notification': popup.record});

/// Null when the popup names no action (or is the controlled one, which never does).
BusMessage? actionMessage(Popup popup) => popup.kind == PopupKind.controlled ? null : recordAction(popup.record);

/// The record's `action` with its `callback_data`, as the shell's `sendRequest(action, callback_data)`; null without one.
BusMessage? recordAction(Json record) {
  final action = '${record['action'] ?? ''}';
  if (action.isEmpty) return null;
  final callback = record['callback_data'];
  return (type: action, data: callback is Json ? callback : <String, dynamic>{});
}

class NotificationActions {
  NotificationActions({required this.bus, required this.popups});

  final CoreBus bus;
  final NotificationPopups popups;

  void close(Popup popup) => _send(popup, closeMessage(popup));

  /// A popup without an action ignores the tap, as the shell's does.
  void act(Popup popup) {
    final message = actionMessage(popup);
    if (message != null) _send(popup, message);
  }

  void _send(Popup popup, BusMessage? message) {
    if (message != null && !bus.emit(message.type, message.data)) {
      reportFault('notification popup sending ${message.type}', StateError('the core bus is not connected'));
      return;
    }
    popups.dismiss(popup);
  }
}
