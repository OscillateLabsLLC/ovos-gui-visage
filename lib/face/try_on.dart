/// Try-on mode: the face itself as the control, for a touch screen or a pointer. Long-press anywhere to enter; the
/// face comes up full and speaks a demo loop. Swipe across the eyes to cycle eye styles, across the mouth to cycle
/// mouths, swipe the mouth up or down for a large or regular mouth, and tap when done. Every change is applied,
/// remembered and announced at once through [FaceRemote], so the picker page follows along.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'face.dart';
import 'face_remote.dart';
import 'face_spec.dart';
import 'face_theme.dart';
import 'styles.dart';

const _dim = Color(0xF405070A);
const _swipeMin = 40.0;
const _loopEvery = Duration(milliseconds: 1800);

/// A short sentence's worth of visemes, replayed while trying on so the mouth is live.
const demoVisemes = <List<Object>>[
  [4, 0.1],
  [0, 0.25],
  [3, 0.4],
  [2, 0.55],
  [5, 0.7],
  [0, 0.85],
  [1, 1.0],
  [4, 1.15],
  [6, 1.3],
  [3, 1.45],
  [4, 1.6],
];

class FaceTryOn extends StatefulWidget {
  const FaceTryOn({super.key, required this.controller, required this.remote, this.enabled = true, this.onActive});

  final FaceController controller;
  final FaceRemote remote;

  /// False while the window cannot show the face (a peeking widget collapsed); an active try-on leaves then.
  final bool enabled;

  /// Told when try-on starts and ends, so a peeking window stays open while it runs.
  final void Function(bool active)? onActive;

  @override
  State<FaceTryOn> createState() => _FaceTryOnState();
}

class _FaceTryOnState extends State<FaceTryOn> {
  bool active = false;
  Timer? _loop;
  Offset _dragStart = Offset.zero;
  Offset _drag = Offset.zero;

  FaceSpec get spec => widget.remote.spec;

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(FaceTryOn old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && active) _leave();
  }

  void _enter() {
    setState(() => active = true);
    widget.onActive?.call(true);
    _speak();
    _loop = Timer.periodic(_loopEvery, (_) => _speak());
  }

  void _speak() {
    widget.controller.setMode(FaceMode.speaking);
    widget.controller.playVisemes(demoVisemes);
  }

  void _leave() {
    _loop?.cancel();
    _loop = null;
    widget.controller.setMode(FaceMode.rest);
    setState(() => active = false);
    widget.onActive?.call(false);
  }

  bool _overEyes(Offset at) => at.dy < widget.controller.theme.geometry.centre.dy;

  void _cycle(bool eyes, int step) {
    final names = (eyes ? eyeStyles : mouthStyles).keys.toList();
    final current = names.indexOf(eyes ? spec.eyes : spec.mouth);
    final next = names[(current + step + names.length) % names.length];
    _apply(eyes ? spec.copyWith(eyes: next) : spec.copyWith(mouth: next));
  }

  void _resize(bool large) {
    final size = large ? 'large' : 'regular';
    if (spec.mouthSize != size) _apply(spec.copyWith(mouthSize: size));
  }

  void _apply(FaceSpec next) {
    widget.remote.apply(next);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _drag.dx, dy = _drag.dy;
    if (dx.abs() >= _swipeMin && dx.abs() > dy.abs()) {
      _cycle(_overEyes(_dragStart), dx > 0 ? 1 : -1);
    } else if (dy.abs() >= _swipeMin && !_overEyes(_dragStart)) {
      _resize(dy < 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Positioned.fill(
        child: GestureDetector(behavior: HitTestBehavior.translucent, onLongPress: widget.enabled ? _enter : null),
      );
    }
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        onPanStart: (d) {
          _dragStart = d.localPosition;
          _drag = Offset.zero;
        },
        onPanUpdate: (d) => _drag += d.delta,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: _dim)),
            Face(controller: widget.controller),
            _label(top: 18, text: '‹  eyes · ${spec.eyes}  ›'),
            _label(bottom: 56, text: '‹  mouth · ${spec.mouth} · ${spec.mouthSize}  ›'),
            _label(bottom: 22, text: 'swipe across to change · swipe the mouth up or down for size · tap when done', muted: true),
          ],
        ),
      ),
    );
  }

  Widget _label({double? top, double? bottom, required String text, bool muted = false}) => Positioned(
    top: top,
    bottom: bottom,
    left: 0,
    right: 0,
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: muted ? VisageText.muted(13) : VisageText.fg(18, weight: FontWeight.w500),
      ),
    ),
  );
}
