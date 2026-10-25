/// SYSTEM_clock (gui-1.md §3.4): no session data; the time comes from the device clock and the page ticks by itself.
/// The 12/24-hour choice is the device's own setting (`MediaQuery.alwaysUse24HourFormat`), since the template has no
/// key for it. Same ring as the date-time skill's time page.
library;

import 'package:flutter/widgets.dart';

import '../json.dart';
import 'blank_page.dart' show dateLine;
import 'every_second.dart';
import 'page.dart';
import 'time_page.dart';

typedef ClockView = ({String time, String ampm, String date});

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// What the clock shows at [now]: `21:05` on a 24-hour device, `9:05` plus `PM` on a 12-hour one.
ClockView clockView(DateTime now, {required bool use24Hour}) {
  final date = dateLine(now);
  if (use24Hour) return (time: '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}', ampm: '', date: date);
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  return (time: '$hour:${_twoDigits(now.minute)}', ampm: now.hour < 12 ? 'AM' : 'PM', date: date);
}

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
