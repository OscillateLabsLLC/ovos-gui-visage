import 'dart:async';

import 'package:flutter/services.dart';

import '../faults.dart';
import 'status_menu.dart';
import 'window_channel.dart';

const menuSelectedMethod = 'menuSelected';

/// The runner's status item (macos/Runner/StatusMenu.swift) on [windowChannel]. A runner without one (Linux, Windows)
/// is reported once and the app carries on without a menu.
class StatusMenuHost {
  StatusMenuHost({required this.onSelected}) {
    windowChannel.setMethodCallHandler(_onCall);
  }

  final void Function(String id) onSelected;
  bool _missingReported = false;

  void show(List<MenuEntry> items) => unawaited(_send(items));

  Future<void> _send(List<MenuEntry> items) async {
    try {
      await windowChannel.invokeMethod<void>('setMenu', [for (final item in items) item.toJson()]);
    } on MissingPluginException catch (err, stack) {
      if (_missingReported) return;
      _missingReported = true;
      reportFault('the menu bar item is not implemented by this platform runner', err, stack);
    }
  }

  Future<void> _onCall(MethodCall call) async {
    if (call.method == menuSelectedMethod && call.arguments is String) return onSelected(call.arguments as String);
    reportFault('a call from the runner on ${windowChannel.name}', ArgumentError.value('${call.method}(${call.arguments})'));
    throw MissingPluginException('${call.method} is not handled');
  }
}
