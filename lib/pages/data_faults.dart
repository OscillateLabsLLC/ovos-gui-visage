/// Session data that breaks a template's key list (gui-1.md §3.3, §3.4): a required key missing, a key of the wrong
/// type, a value out of range. The page still renders the nearest useful presentation (§6.5); this reports each problem
/// when it first appears, not on every rebuild.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../faults.dart';
import 'page.dart';

/// The problem when a required string key is absent or not a string; null when it is fine.
String? requiredString(Object? value, String key) => value is String ? null : _typeProblem(key, 'a string', value);

/// The problem when an optional string key is present and not a string; null when it is absent or fine.
String? optionalString(Object? value, String key) =>
    value == null || value is String ? null : _typeProblem(key, 'a string', value);

/// The problem when a required number key is absent or not a finite number; null when it is fine.
String? requiredNumber(Object? value, String key) => _isFinite(value) ? null : _typeProblem(key, 'a finite number', value);

/// The problem when an optional number key is present and not a finite number; null when it is absent or fine.
String? optionalNumber(Object? value, String key) => value == null ? null : requiredNumber(value, key);

/// The problem when an optional boolean key is present and not a boolean; null when it is absent or fine.
String? optionalBool(Object? value, String key) => value == null || value is bool ? null : _typeProblem(key, 'a boolean', value);

/// [value] as a double when it is a finite number, else null.
double? finite(Object? value) => _isFinite(value) ? (value as num).toDouble() : null;

/// An optional string key as text, or '' when it is absent or of the wrong type (reported by [optionalString]).
String optionalText(Object? value) => value is String ? value : '';

bool _isFinite(Object? value) => value is num && value.isFinite;

String _typeProblem(String key, String expected, Object? value) =>
    value == null ? '$key is required' : '$key must be $expected, got ${value.runtimeType} ${text(value)}';

/// Reports [problems] for [template] through `reportFault`, again only when the list changes, and shows [child].
class ReportsDataFaults extends StatefulWidget {
  const ReportsDataFaults({super.key, required this.template, required this.problems, required this.child});

  final String template;
  final List<String> problems;
  final Widget child;

  @override
  State<ReportsDataFaults> createState() => _ReportsDataFaultsState();
}

class _ReportsDataFaultsState extends State<ReportsDataFaults> {
  @override
  void initState() {
    super.initState();
    _report();
  }

  @override
  void didUpdateWidget(ReportsDataFaults old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.problems, widget.problems)) _report();
  }

  void _report() {
    for (final problem in widget.problems) {
      reportFault('${widget.template} data', FormatException(problem));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
