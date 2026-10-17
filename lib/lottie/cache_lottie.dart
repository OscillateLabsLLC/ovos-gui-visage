/// Plays one of OVOS's own Lottie files from the ovos-gui cache. A one-shot plays its live segment once and holds
/// the last frame; a missing or unreadable file shows [fallback] instead.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'segment.dart';

class CacheLottie extends StatefulWidget {
  const CacheLottie({super.key, required this.file, required this.loop, required this.fallback});

  final File file;
  final bool loop;
  final Widget fallback;

  @override
  State<CacheLottie> createState() => _CacheLottieState();
}

class _CacheLottieState extends State<CacheLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Future<_Loaded?> _loaded = _load();

  Future<_Loaded?> _load() async {
    try {
      final bytes = await widget.file.readAsBytes();
      final composition = await LottieComposition.fromBytes(bytes);
      final segment = liveSegment(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      return _Loaded(composition, segment);
    } on Object {
      return null;
    }
  }

  void _start(_Loaded loaded) {
    _controller.duration = loaded.composition.duration;
    if (widget.loop) {
      _controller.repeat();
      return;
    }
    final frames = loaded.composition.endFrame - loaded.composition.startFrame;
    final end = (loaded.segment.end - loaded.composition.startFrame) / frames;
    _controller.animateTo(end.clamp(0, 1));
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
        if (!_controller.isAnimating && _controller.value == 0) _start(loaded);
        return Lottie(composition: loaded.composition, controller: _controller, fit: BoxFit.contain);
      },
    );
  }
}

class _Loaded {
  _Loaded(this.composition, this.segment);

  final LottieComposition composition;
  final ({double start, double end}) segment;
}
