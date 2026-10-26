/// The device's own clock in the hero clock chip, ticking each second: the built-in blank page and the GUI-1
/// resting display both show it, since neither has a producer for the time (gui-1.md 6.9.1).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'home_chips.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

typedef ClockView = ({String time, String ampm, String date});

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// What a clock shows at [now]: `21:05` on a 24-hour device, `9:05` plus `PM` on a 12-hour one. The 12/24-hour choice
/// is the device's own setting (`MediaQuery.alwaysUse24HourFormat`); neither the resting display nor `SYSTEM_clock`
/// has a key for it, so every clock Visage draws reads the same setting.
ClockView clockView(DateTime now, {required bool use24Hour}) {
  final date = dateLine(now);
  if (use24Hour) return (time: '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}', ampm: '', date: date);
  final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
  return (time: '$hour:${_twoDigits(now.minute)}', ampm: now.hour < 12 ? 'AM' : 'PM', date: date);
}

String clockLine(DateTime now) => clockView(now, use24Hour: true).time;

String dateLine(DateTime now) => '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

/// [now] is the clock it reads, so a test can fix the time.
class DeviceClock extends StatefulWidget {
  const DeviceClock({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  @override
  State<DeviceClock> createState() => _DeviceClockState();
}

class _DeviceClockState extends State<DeviceClock> {
  late final Timer _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    _ticker;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = clockView(widget.now(), use24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
    return ClockChip(time: view.time, ampm: view.ampm, date: view.date);
  }
}
