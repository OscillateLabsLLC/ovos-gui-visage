/// Notification popups, display-only, after ovos-shell's NotificationsSystem.qml and NotificationPop*.qml:
/// a `transient` notification (`ovos.notification.api.set`, the default type) stays `duration` seconds, then is
/// cleared to storage as the shell's timer does with `ovos.notification.api.pop.clear`; a `sticky` one has no timer
/// and stays until something clears it (`pop.clear` or `pop.clear.delete` for the same sender and text); the one
/// `controlled` notification is created or updated in place by `set.controlled` and removed by `remove.controlled`.
/// The shell's close buttons are left out: Visage takes no input on notifications yet.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../json.dart';
import '../timers.dart';

enum PopupKind { transient, sticky, controlled }

/// ovos-shell's NotificationsSystem column holds every popup; a 480 x 800 frame fits about this many.
const maxPopupsShown = 3;
const defaultPopupSeconds = 10;

class Popup {
  const Popup(this.id, this.kind, this.record);

  final int id;
  final PopupKind kind;
  final Json record;

  String get text => '${record['text'] ?? ''}';
  String get style => '${record['style'] ?? 'info'}';
}

bool _sameNotification(Json a, Json b) => a['sender'] == b['sender'] && a['text'] == b['text'];

class NotificationPopups extends ChangeNotifier {
  NotificationPopups({OneShot? timer, this.onExpired}) : _timer = timer ?? Timer.new;

  final OneShot _timer;

  /// Called with a transient notification's record when its time is up; the shell clears it to storage then.
  final void Function(Json record)? onExpired;
  final List<Popup> _stacked = [];
  final Map<int, Timer> _timers = {};
  Popup? controlled;
  int _nextId = 0;

  /// Oldest first, as the shell's column stacks them; the controlled popup leads.
  List<Popup> get all => [?controlled, ..._stacked];

  void show(Json record) {
    final popup = Popup(_nextId++, record['type'] == 'sticky' ? PopupKind.sticky : PopupKind.transient, record);
    _stacked.add(popup);
    if (popup.kind == PopupKind.transient) _timers[popup.id] = _timer(_durationOf(record), () => _expire(popup));
    notifyListeners();
  }

  void cleared(Json notification) {
    final gone = _stacked.where((popup) => _sameNotification(popup.record, notification)).toList();
    if (gone.isEmpty) return;
    for (final popup in gone) {
      _drop(popup);
    }
    notifyListeners();
  }

  void showControlled(Json record) {
    controlled = Popup(controlled?.id ?? _nextId++, PopupKind.controlled, record);
    notifyListeners();
  }

  void removeControlled() {
    if (controlled == null) return;
    controlled = null;
    notifyListeners();
  }

  void _expire(Popup popup) {
    _timers.remove(popup.id);
    if (!_stacked.contains(popup)) return;
    _drop(popup);
    notifyListeners();
    onExpired?.call(popup.record);
  }

  void _drop(Popup popup) {
    _stacked.remove(popup);
    _timers.remove(popup.id)?.cancel();
  }

  Duration _durationOf(Json record) {
    final seconds = record['duration'];
    if (seconds is num && seconds > 0) return Duration(milliseconds: (seconds * 1000).round());
    reportFault(
      'notification popup: duration is not a positive number, using $defaultPopupSeconds s',
      ArgumentError.value(seconds),
    );
    return const Duration(seconds: defaultPopupSeconds);
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
