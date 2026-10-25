/// Rebuilds a page once a second, for the templates that derive what they show from the device clock (gui-1.md §3.4:
/// `SYSTEM_clock`, `SYSTEM_timer`), so the producer never polls.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// The device clock; tests pass their own.
typedef Now = DateTime Function();

const _tick = Duration(seconds: 1);

mixin EverySecond<T extends StatefulWidget> on State<T> {
  late final Timer _ticker = Timer.periodic(_tick, (_) => setState(() {}));

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
}
