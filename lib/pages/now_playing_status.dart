/// The now-playing status line's motion: the equaliser bars and the live dot.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

const _liveRed = Color(0xFFFF4D4D);

/// Four bars breathing between a quarter and full height on a 0.9 s cycle; frozen and muted on pause.
class Equaliser extends StatefulWidget {
  const Equaliser({super.key, required this.running});

  final bool running;

  @override
  State<Equaliser> createState() => _EqualiserState();
}

class _EqualiserState extends State<Equaliser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Equaliser old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Runs while playing; under reduced motion the bars hold the staggered shape of the cycle's start.
  void _sync() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 0;
    } else if (widget.running) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const delays = [0.0, 0.3, 0.6, 0.45];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          for (final delay in delays)
            Container(
              width: 3,
              height: 14 * (0.25 + 0.75 * (0.5 - 0.5 * math.cos(2 * math.pi * ((_controller.value + delay) % 1)))),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: widget.running ? VisageColors.accent : VisageColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// The pulsing red dot of a live stream, half-dimmed and still on pause.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.running});

  final bool running;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _still = false;

  /// Pulses unless reduced motion is on; then the dot is steady, full while playing.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _still ? _controller.stop() : _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steady = AlwaysStoppedAnimation(widget.running ? 1.0 : 0.5);
    return FadeTransition(
      opacity: widget.running && !_still ? Tween(begin: 1.0, end: 0.3).animate(_controller) : steady,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _liveRed,
          boxShadow: [BoxShadow(color: Color(0xB3FF4D4D), blurRadius: 8, spreadRadius: 1)],
        ),
      ),
    );
  }
}
