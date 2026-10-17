/// A weather icon from the bundled set with the motion its SVG used to carry in CSS: the sun turns once in 20 s,
/// cloud icons drift a few pixels on a 7 s breath. First pass: whole-icon motion (SCOPE: per-part motion later).
library;

import 'package:flutter/material.dart';

import '../resources.dart';

const _spinning = {'sun'};
const _drifting = {'partial_clouds', 'clouds', 'fog', 'rain', 'snow', 'storm', 'night'};

class WeatherIcon extends StatefulWidget {
  const WeatherIcon(this.name, {super.key, required this.size});

  final String name;
  final double size;

  @override
  State<WeatherIcon> createState() => _WeatherIconState();
}

class _WeatherIconState extends State<WeatherIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: _period)
    ..repeat(reverse: _drifting.contains(widget.name));

  Duration get _period => _spinning.contains(widget.name) ? const Duration(seconds: 20) : const Duration(seconds: 7);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = icon(widget.name, size: widget.size);
    if (_spinning.contains(widget.name)) return RotationTransition(turns: _controller, child: image);
    if (!_drifting.contains(widget.name)) return image;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset((-2 + 5 * Curves.easeInOut.transform(_controller.value)) * widget.size / 64, 0),
        child: child,
      ),
      child: image,
    );
  }
}
