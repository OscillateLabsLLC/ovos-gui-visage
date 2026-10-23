/// A two-finger tap on a touch screen, the touch twin of a right-click: exactly two fingers down, neither moving more
/// than [slop], all lifted within [within] of the first touch. Pure; the window surface feeds it raw touch pointers,
/// since Flutter has no recognizer for it and a long press already belongs to try-on mode.
library;

import 'dart:ui';

const twoFingerTapWithin = Duration(milliseconds: 400);
const twoFingerTapSlop = 24.0;

class TwoFingerTap {
  TwoFingerTap({required this.onTap, this.within = twoFingerTapWithin, this.slop = twoFingerTapSlop});

  /// Gets the midpoint of the two touches, in the coordinates the positions were given in.
  final void Function(Offset at) onTap;
  final Duration within;
  final double slop;
  final Map<int, Offset> _origins = {};
  final List<Offset> _touches = [];
  Duration _started = Duration.zero;
  int _peak = 0;
  bool _spoiled = false;

  void down(int pointer, Offset at, Duration time) {
    if (_origins.isEmpty) _reset(time);
    _origins[pointer] = at;
    _touches.add(at);
    if (_origins.length > _peak) _peak = _origins.length;
  }

  void move(int pointer, Offset at) {
    final origin = _origins[pointer];
    if (origin != null && (at - origin).distance > slop) _spoiled = true;
  }

  void up(int pointer, Duration time) {
    if (_origins.remove(pointer) == null || _origins.isNotEmpty) return;
    final quick = time - _started <= within;
    if (_peak == 2 && !_spoiled && quick) onTap((_touches[0] + _touches[1]) / 2);
  }

  void cancel(int pointer) {
    _spoiled = true;
    _origins.remove(pointer);
  }

  void _reset(Duration time) {
    _started = time;
    _touches.clear();
    _peak = 0;
    _spoiled = false;
  }
}
