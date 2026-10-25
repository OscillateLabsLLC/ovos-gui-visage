/// SYSTEM_timer ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)):
/// one ring, the alerts skill's, ticking from the device clock with no producer polling.
/// The template holds one timer and offers no reply leg, so there is no cancel button (finding F8 for several timers).
library;

import 'package:flutter/widgets.dart';

import '../json.dart';
import 'alerts_model.dart';
import 'data_faults.dart';
import 'every_second.dart';
import 'page.dart';
import 'system_timer_model.dart';
import 'timer_page.dart';

class SystemTimerPage extends StatefulWidget {
  const SystemTimerPage({super.key, required this.data, this.now = DateTime.now});

  static Widget page(Json data, PageContext ctx) => SystemTimerPage(data: data);

  final Json data;
  final Now now;

  @override
  State<SystemTimerPage> createState() => _SystemTimerPageState();
}

class _SystemTimerPageState extends State<SystemTimerPage> with EverySecond {
  final _longest = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final spec = timerSpec(widget.data);
    final view = timerAt(spec, widget.now(), _longest);
    return ReportsDataFaults(
      template: 'SYSTEM_timer',
      problems: spec.problems,
      child: Center(
        child: TimerRing(key: ValueKey(view.id), timer: view, size: timerSizes.first),
      ),
    );
  }
}
