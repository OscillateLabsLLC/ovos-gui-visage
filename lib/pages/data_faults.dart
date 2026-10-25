/// Reports session data that breaks a template's key list (spec_keys.dart): a required key missing, a key of the wrong
/// type, a value out of range. The page still renders the nearest useful presentation
/// ([gui-1.md 6.5 Capability and graceful degradation](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#65-capability-and-graceful-degradation));
/// each problem is reported when it first appears, not on every rebuild.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../faults.dart';

export 'spec_keys.dart';

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
