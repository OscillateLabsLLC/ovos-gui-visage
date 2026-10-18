import 'dart:async';

/// Timers the test fires by hand, so nothing sleeps.
class ManualTimers {
  final List<ManualTimer> all = [];

  Timer create(Duration after, void Function() callback) => ManualTimer(after, callback)..addTo(all);

  List<ManualTimer> get pending => [
    for (final t in all)
      if (t.isActive) t,
  ];

  void fireAll() {
    for (final timer in pending) {
      timer.fire();
    }
  }
}

class ManualTimer implements Timer {
  ManualTimer(this.after, this.callback);

  final Duration after;
  final void Function() callback;
  bool _active = true;

  void addTo(List<ManualTimer> list) => list.add(this);

  void fire() {
    _active = false;
    callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
