/// SYSTEM_clock ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)):
/// no session data; the time comes from the device clock and the page ticks by itself.
/// The 12/24-hour choice is the device's own setting (`MediaQuery.alwaysUse24HourFormat`), since the template has no
/// key for it; `clockView` in `widgets/device_clock.dart` reads it for this page and the resting display alike.
/// Same ring as the date-time skill's time page.
library;

import 'package:flutter/widgets.dart';

import '../json.dart';
import '../widgets/device_clock.dart' show clockView;
import 'every_second.dart';
import 'page.dart';
import 'time_page.dart';

export '../widgets/device_clock.dart' show ClockView, clockView;

class ClockPage extends StatefulWidget {
  const ClockPage({super.key, this.now = DateTime.now});

  static Widget page(Json data, PageContext ctx) => const ClockPage();

  final Now now;

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> with EverySecond {
  @override
  Widget build(BuildContext context) {
    final view = clockView(widget.now(), use24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
    return ClockRing(time: view.time, ampm: view.ampm, date: view.date);
  }
}
