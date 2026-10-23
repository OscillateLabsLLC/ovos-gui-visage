import 'dart:async';

/// Starts a one-shot timer; tests pass a factory they fire by hand (test/manual_timers.dart).
typedef OneShot = Timer Function(Duration after, void Function() callback);
