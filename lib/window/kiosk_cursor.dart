/// Kiosk mode hides the mouse pointer [cursorHideAfter] without movement and shows it again on the next movement.
/// Pure; window_surface.dart feeds it hover events and swaps the cursor when [hidden] changes.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'peek.dart';

const cursorHideAfter = Duration(seconds: 5);

class CursorHider extends ChangeNotifier {
  CursorHider({TimerFactory? timer}) : _timer = timer ?? Timer.new;

  final TimerFactory _timer;
  bool _enabled = false;
  bool _hidden = false;
  Timer? _hideTimer;

  bool get enabled => _enabled;

  /// Whether the pointer is hidden now; never while disabled.
  bool get hidden => _hidden;

  /// On: the countdown starts at once. Off: the pointer shows and stays.
  void setEnabled(bool on) {
    if (_enabled == on) return;
    _enabled = on;
    on ? _restart() : _show();
  }

  /// The pointer moved: show it and count down again.
  void moved() {
    if (!_enabled) return;
    _setHidden(false);
    _restart();
  }

  void _restart() {
    _hideTimer?.cancel();
    _hideTimer = _timer(cursorHideAfter, () {
      _hideTimer = null;
      _setHidden(true);
    });
  }

  void _show() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _setHidden(false);
  }

  void _setHidden(bool value) {
    if (_hidden == value) return;
    _hidden = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
