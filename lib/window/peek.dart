/// Peek mode's timing: the widget window expands the moment the face is shown and collapses to its badge [peekHold]
/// after the face hides, unless it is shown again first. A tap on the badge expands it for [tapHold], and a hold
/// (try-on mode) keeps it open until released. Pure; the screen feeds it attention and resizes the window when
/// [expanded] changes.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

const peekHold = Duration(seconds: 3);
const tapHold = Duration(seconds: 10);

typedef TimerFactory = Timer Function(Duration after, void Function() callback);

class PeekController extends ChangeNotifier {
  PeekController({required this._enabled, TimerFactory? timer}) : _timer = timer ?? Timer.new;

  final TimerFactory _timer;
  bool _enabled;
  bool _collapsed = true;
  bool _attending = false;
  bool _held = false;
  Timer? _collapseTimer;

  bool get enabled => _enabled;

  /// The window's state: always expanded when peek is off.
  bool get expanded => !_enabled || !_collapsed;

  void setEnabled(bool on) {
    if (_enabled == on) return;
    _enabled = on;
    _cancel();
    _collapsed = !_attending && !_held;
    notifyListeners();
  }

  /// Follows Attention.shown; only the changes count.
  void attention(bool shown) {
    if (_attending == shown) return;
    _attending = shown;
    shown ? _expand() : _collapseAfter(peekHold);
  }

  void tap() {
    _expand();
    if (!_attending && !_held) _collapseAfter(tapHold);
  }

  /// Keeps the window open while something on screen needs it (try-on mode); releasing collapses after the hold
  /// unless the face is shown.
  void hold(bool on) {
    if (_held == on) return;
    _held = on;
    on ? _expand() : _collapseAfter(peekHold);
  }

  /// A one-off from the bus: expanded stays until it is collapsed or the next attention cycle ends; collapsed stays
  /// until the face is shown again.
  void setExpanded(bool value) {
    _cancel();
    value ? _expand() : _setCollapsed(true);
  }

  void _expand() {
    _cancel();
    _setCollapsed(false);
  }

  void _collapseAfter(Duration after) {
    _cancel();
    _collapseTimer = _timer(after, () {
      _collapseTimer = null;
      if (!_attending && !_held) _setCollapsed(true);
    });
  }

  void _setCollapsed(bool value) {
    if (_collapsed == value) return;
    _collapsed = value;
    if (_enabled) notifyListeners();
  }

  void _cancel() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
