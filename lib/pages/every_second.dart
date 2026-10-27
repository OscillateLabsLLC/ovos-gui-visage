/// Rebuilds a page once a second, for the templates that derive what they show from the device clock, so the producer
/// never polls: `SYSTEM_clock` and `SYSTEM_timer` in
/// [gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue).
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
