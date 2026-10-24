/// The stored notifications, after ovos-skill-homescreen's idle.qml and NotificationDelegate.qml. The Qt list showed
/// the homescreen's `notification_model.storedmodel` session value; this one shows this display's own WidgetManager
/// storage, in its order, oldest first. Every client's WidgetManager answers `request.storage.model` and the homescreen
/// keeps the last answer, so with several clients on one OVOS the session value changes with whichever answered last.
/// Opening and closing the list sends nothing.
///
/// - A tap on an item's text runs its `action` with `callback_data`, then clears it with
///   `ovos.notification.api.storage.clear.item` `{"notification": record}`, as the delegate's text does.
/// - The item's clear button sends only `storage.clear.item`. The delegate's trash button also runs the action; here
///   clearing and acting stay apart, as they do on the popups.
/// - Clear all sends `ovos.notification.api.storage.clear` `{}`. The homescreen's Clear first runs every item's action;
///   here it does not, for the same reason.
library;

import '../json.dart';
import 'notification_actions.dart';

const storageClearItem = 'ovos.notification.api.storage.clear.item';
const storageClear = 'ovos.notification.api.storage.clear';

class StoredNotification {
  const StoredNotification(this.record);

  /// Sent back whole, as the delegate sends `modelData`; every WidgetManager matches it by sender and text.
  final Json record;

  String get sender => '${record['sender'] ?? ''}';
  String get text => '${record['text'] ?? ''}';
  String get style => '${record['style'] ?? 'info'}';
  bool get hasAction => recordAction(record) != null;
}

BusMessage clearItemMessage(StoredNotification item) => (type: storageClearItem, data: {'notification': item.record});

BusMessage clearAllMessage() => (type: storageClear, data: <String, dynamic>{});

/// What a tap on the item's text sends, in order: its action when it has one, then the clear.
List<BusMessage> actMessages(StoredNotification item) => [?recordAction(item.record), clearItemMessage(item)];
