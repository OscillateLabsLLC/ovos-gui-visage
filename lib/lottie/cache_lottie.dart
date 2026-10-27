/// Plays one of OVOS's own Lottie files, named by its `/res/...` path in the ovos-gui cache. A one-shot plays its
/// live segment once and holds the last frame; a missing or unreadable file is reported and shows [fallback] instead. With [fitRing] the animation is placed so
/// its main ring lands on the chip's ring (fit.dart) instead of filling the box.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../faults.dart';
import '../resources/resources.dart';
import 'fit.dart';
import 'segment.dart';

class CacheLottie extends StatefulWidget {
  const CacheLottie({super.key, required this.resource, required this.loop, required this.fallback, this.fitRing = false});

  final String resource;
  final bool loop;
  final Widget fallback;
  final bool fitRing;

  @override
  State<CacheLottie> createState() => _CacheLottieState();
}

class _CacheLottieState extends State<CacheLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Future<_Loaded?> _loaded = _load();

  Future<_Loaded?> _load() async {
    try {
      final bytes = await readResource(widget.resource);
      final composition = await LottieComposition.fromBytes(bytes);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return _Loaded(composition, liveSegment(json), widget.fitRing ? ringFit(json) : null);
    } on Object catch (err, stack) {
      reportFault('loading ${widget.resource}', err, stack);
      return null;
    }
  }

  /// Under reduced motion a loop holds its first frame and a one-shot jumps to the frame it would hold.
  void _start(_Loaded loaded, {required bool still}) {
    _controller.duration = loaded.composition.duration;
    if (widget.loop) {
      if (!still) _controller.repeat();
      return;
    }
    final frames = loaded.composition.endFrame - loaded.composition.startFrame;
    final end = ((loaded.segment.end - loaded.composition.startFrame) / frames).clamp(0.0, 1.0);
    still ? _controller.value = end : _controller.animateTo(end);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Loaded?>(
      future: _loaded,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) return snapshot.connectionState == ConnectionState.done ? widget.fallback : const SizedBox();
        if (!_controller.isAnimating && _controller.value == 0) {
          _start(loaded, still: MediaQuery.maybeDisableAnimationsOf(context) ?? false);
        }
        final lottie = Lottie(composition: loaded.composition, controller: _controller, fit: BoxFit.contain);
        final fit = loaded.fit;
        if (fit == null) return lottie;
        return LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: fit.left * side,
                  top: fit.top * side,
                  width: fit.width * side,
                  height: fit.height * side,
                  child: lottie,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Loaded {
  _Loaded(this.composition, this.segment, this.fit);

  final LottieComposition composition;
  final ({double start, double end}) segment;
  final ({double width, double height, double left, double top})? fit;
}
