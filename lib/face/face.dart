/// The face widget: owns mode, blink, widen and viseme timing, tweens the mouth, and paints through a [FaceTheme].
/// Port of face.js. The widget paints in 480 x 800 frame coordinates; the parent sizes and positions it.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'face_theme.dart';
import 'visage_theme.dart';
import 'visemes.dart';

const _easeMs = 45.0;
const _eyeEaseMs = 120.0;
const _blinkMin = Duration(seconds: 3);
const _blinkMax = Duration(seconds: 7);
const _blinkFor = Duration(milliseconds: 150);
const _widenFor = Duration(milliseconds: 600);
const _closedEye = 0.08;
const _thinkingEye = 0.62;
const _wideEye = 1.18;

/// Drives a [Face] from outside: the attention overlay and the SYSTEM_Face page call these.
class FaceController extends ChangeNotifier {
  // ignore: prefer_initializing_formals, the public name is `theme` and the field backs its setter
  FaceController({FaceTheme theme = const VisageTheme()}) : _theme = theme;

  FaceTheme _theme;

  /// The look every [Face] on this controller paints with; settable while running, the faces repaint.
  FaceTheme get theme => _theme;

  set theme(FaceTheme value) {
    if (identical(value, _theme)) return;
    _theme = value;
    notifyListeners();
  }

  /// Monotonic clock for viseme timing, shared by the widget's ticker and whoever anchors a viseme list.
  final Stopwatch clock = Stopwatch()..start();
  FaceMode _mode = FaceMode.rest;
  bool _sleeping = false;
  bool _blinking = false;
  bool _wide = false;
  List<dynamic>? _visemes;
  final _flashes = <Timer>{};
  Duration _anchor = Duration.zero;

  FaceMode get mode => _mode;
  bool get sleeping => _sleeping;
  bool get blinking => _blinking;
  bool get wide => _wide;

  void setMode(FaceMode mode) {
    _mode = mode;
    if (mode != FaceMode.speaking) _visemes = null;
    notifyListeners();
  }

  void setSleeping(bool sleeping) {
    _sleeping = sleeping;
    notifyListeners();
  }

  /// Visemes are timed from speech start on the producing machine; same-host assumption: anchor on arrival.
  void playVisemes(List<dynamic>? visemes, {Duration? at}) {
    _visemes = visemes;
    _anchor = at ?? clock.elapsed;
  }

  void widen() => _flash((v) => _wide = v, _widenFor);

  void blink() => _flash((v) => _blinking = v, _blinkFor);

  int targetCode(Duration now) {
    final visemes = _visemes;
    if (_mode != FaceMode.speaking || visemes == null) return restCode;
    return visemeAt(visemes, (now - _anchor).inMicroseconds / 1e6) ?? restCode;
  }

  double get targetEyeOpen {
    if (_blinking || _sleeping) return _closedEye;
    return _mode == FaceMode.thinking ? _thinkingEye : 1;
  }

  double get targetEyeScale => _wide ? _wideEye : 1;

  /// A blink or widen still running is cancelled by [dispose], so it never notifies a disposed controller.
  void _flash(void Function(bool) set, Duration length) {
    set(true);
    notifyListeners();
    late final Timer timer;
    timer = Timer(length, () {
      _flashes.remove(timer);
      set(false);
      notifyListeners();
    });
    _flashes.add(timer);
  }

  @override
  void dispose() {
    for (final timer in _flashes) {
      timer.cancel();
    }
    _flashes.clear();
    super.dispose();
  }
}

class Face extends StatefulWidget {
  const Face({super.key, required this.controller, this.compact = false});

  final FaceController controller;
  final bool compact;

  FaceTheme get theme => controller.theme;

  @override
  State<Face> createState() => _FaceState();
}

class _FaceState extends State<Face> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<Offset> _lips = widget.theme.mouthShapes[restCode]!;
  int _viseme = restCode;
  double _eyeOpen = 1;
  double _eyeScale = 1;
  Duration _now = Duration.zero;
  Duration _last = Duration.zero;
  Duration _nextBlink = Duration.zero;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _scheduleBlink() {
    final span = _blinkMax - _blinkMin;
    _nextBlink = _now + _blinkMin + Duration(milliseconds: _random.nextInt(span.inMilliseconds));
  }

  double _ease(Duration dt, double ms) => 1 - math.exp(-dt.inMicroseconds / 1000 / ms);

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    _now = elapsed;
    if (elapsed >= _nextBlink) {
      widget.controller.blink();
      _scheduleBlink();
    }
    final c = widget.controller;
    final k = _ease(dt, _easeMs);
    final kEye = _ease(dt, _eyeEaseMs);
    setState(() {
      final shapes = widget.theme.mouthShapes;
      _viseme = c.targetCode(c.clock.elapsed);
      _lips = lerpPoints(_lips, shapes[_viseme] ?? shapes[restCode]!, k);
      _eyeOpen += (c.targetEyeOpen - _eyeOpen) * kEye;
      _eyeScale += (c.targetEyeScale - _eyeScale) * kEye;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frame = FaceFrame(
      mode: widget.controller.mode,
      eyeOpen: _eyeOpen,
      eyeScale: _eyeScale,
      lips: _lips,
      viseme: _viseme,
      elapsed: _now.inMicroseconds / 1e6,
      compact: widget.compact,
      palette: widget.theme.palette,
    );
    return CustomPaint(size: const Size(frameWidth, frameHeight), painter: FacePainter(widget.theme, frame));
  }
}

/// Paints one [FaceFrame] through a theme; public so goldens can paint a fixed frame without the ticker.
class FacePainter extends CustomPainter {
  FacePainter(this.theme, this.frame);

  final FaceTheme theme;
  final FaceFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    theme.eyes.paint(canvas, frame);
    theme.mouth.paint(canvas, frame);
  }

  @override
  bool shouldRepaint(FacePainter old) => true;
}
