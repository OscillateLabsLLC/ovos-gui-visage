import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../faults.dart';
import 'tray_watch.dart';

/// Watches the session bus for [trayWatcherName] through the bus daemon only (NameHasOwner and NameOwnerChanged),
/// never by calling the watcher itself, which could start a service by D-Bus activation.
class TrayWatcherProbe {
  TrayWatcherProbe({void Function(String line)? log}) : log = log ?? debugPrint;

  final void Function(String line) log;
  final TrayWatch _watch = TrayWatch();
  DBusClient? _bus;
  StreamSubscription<DBusNameOwnerChangedEvent>? _changes;

  /// Subscribes before it asks, so a watcher that starts in between is not missed. A bus that cannot be reached is
  /// reported, and the tray is set up as before.
  Future<void> start() async {
    try {
      final bus = _bus = DBusClient.session();
      _changes = bus.nameOwnerChanged.where((e) => e.name == trayWatcherName).listen((e) => _observe(e.newOwner != null));
      _observe(await bus.nameHasOwner(trayWatcherName));
    } on Object catch (err, stack) {
      reportFault('checking the session bus for $trayWatcherName', err, stack);
    }
  }

  void _observe(bool present) {
    switch (_watch.observe(present: present)) {
      case TrayWatchStep.reportMissing:
        reportFault(trayWatcherFault, StateError('$trayWatcherName has no owner'));
      case TrayWatchStep.appeared:
        log('tray: $trayWatcherName appeared; the tray item registers with it');
      case TrayWatchStep.none:
        break;
    }
  }

  Future<void> dispose() async {
    await _changes?.cancel();
    await _bus?.close();
  }
}
