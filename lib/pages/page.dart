/// What every page widget receives: the namespace's session data and the routing context (SPEC 8), and the way back
/// to the skill: [PageContext.trigger] sends an event the way a Qt page's `triggerGuiEvent` did.
library;

import 'package:flutter/widgets.dart';

import '../faults.dart';
import '../json.dart';
import '../protocol/gui_events.dart';
import '../protocol/wire_protocol.dart';

/// Sends one GUI protocol message; false when it could not leave (the socket is closed).
typedef GuiSend = bool Function(Json message);

bool _notConnected(Json message) => false;

void _noNotificationList() => reportFault('showing the stored notifications', StateError('no shell list is wired'));

class PageContext {
  const PageContext({
    required this.namespace,
    required this.page,
    required this.events,
    this.send = _notConnected,
    this.showNotifications = _noNotificationList,
    this.storedNotifications = 0,
    this.protocol,
  });

  final String namespace;
  final String page;

  /// The namespace's last event payload by event name (`mycroft.events.triggered` other than focus).
  final Json events;

  /// The GUI socket; without one (a test that does not wire it) every trigger is reported.
  final GuiSend send;

  /// Opens the shell's stored notification list, as the homescreen's notification button opened its popup; that
  /// sends nothing, so it is not a [trigger].
  final VoidCallback showNotifications;

  /// How many notifications the shell's list holds; the homescreen badge shows it.
  final int storedNotifications;

  /// What the connection speaks, null before one is chosen. GUI-1 holds a page's data to the spec's wire rules, such as
  /// no filesystem path in an image key (finding F39), where legacy keeps what the Qt pages accepted.
  final ChosenProtocol? protocol;

  bool get gui1 => protocol == ChosenProtocol.gui1;

  /// Sends [eventName] with [parameters] in this page's namespace; ovos-gui emits `<namespace>.<eventName>` on the
  /// core bus. A message that cannot leave is reported, so a button that does nothing is never silent.
  void trigger(String eventName, [Json parameters = const {}]) {
    final message = guiEvent(namespace, eventName, parameters);
    if (send(message)) return;
    reportFault('$namespace/$page sending $eventName', StateError('the GUI socket is not connected'));
  }
}

typedef PageBuilder = Widget Function(Json data, PageContext ctx);

/// Session values are loosely typed; these read them the way the JS view models do.
String text(Object? value) => value == null ? '' : value.toString();

double number(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? fallback;

bool truthy(Object? value) => value == true || (value is num && value != 0) || (value is String && value.isNotEmpty);
