/// What every page widget receives: the namespace's session data and the routing context (SPEC 8).
library;

import 'package:flutter/widgets.dart';

import '../json.dart';

class PageContext {
  const PageContext({required this.namespace, required this.page, required this.events});

  final String namespace;
  final String page;

  /// The namespace's last event payload by event name (`mycroft.events.triggered` other than focus).
  final Json events;
}

typedef PageBuilder = Widget Function(Json data, PageContext ctx);

/// Session values are loosely typed; these read them the way the JS view models do.
String text(Object? value) => value == null ? '' : value.toString();

double number(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? fallback;

bool truthy(Object? value) => value == true || (value is num && value != 0) || (value is String && value.isNotEmpty);
