/// An icon from assets/icons drawn as its stack of layers (icon_layers.g.dart), each animated layer moved by its
/// motion (icon_motion.dart) exactly as the source SVG's CSS keyframes did. The globe's meridians and the reminder's
/// ticks animate shape rather than transform, so they are painted (icon_painters.dart). Motion stops when the
/// platform asks for reduced motion.
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'icon_layers.g.dart';
import 'icon_motion.dart';
import 'icon_painters.dart';
import 'motion.dart';

const viewBox = 64.0;

class MotionIcon extends StatefulWidget {
  const MotionIcon(this.name, {super.key, required this.size, this.ringing = false});

  final String name;
  final double size;

  /// The bell only: shake instead of the rest swing.
  final bool ringing;

  @override
  State<MotionIcon> createState() => _MotionIconState();
}

class _MotionIconState extends State<MotionIcon> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  List<IconLayer> get _layers => iconLayers[widget.name] ?? [IconLayer('${widget.name}.svg')];

  bool get _animated => _layers.any((layer) => layer.cls != null);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed));
    if (_animated) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = widget.size / viewBox;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(children: [for (final layer in _layers) _layer(layer, scale, still)]),
    );
  }

  Widget _layer(IconLayer layer, double scale, bool still) {
    final painter = layerPainter(widget.name, layer.cls, layer.nth, still ? null : _elapsed);
    if (painter != null) return Positioned.fill(child: CustomPaint(painter: painter));
    final image = SvgPicture.asset('assets/icons/${layer.asset}', width: widget.size, height: widget.size);
    final motion = widget.ringing && widget.name == 'bell' ? bellShake : motionFor(widget.name, layer.cls, layer.nth);
    if (motion == null || still) return image;
    final frame = motion.at(_elapsed);
    return Positioned.fill(
      child: Opacity(
        opacity: frame.opacity.clamp(0, 1),
        child: Transform(transform: _matrix(frame, motion, scale), child: image),
      ),
    );
  }

  /// translate, then rotate and scale about the pivot, in screen pixels.
  Matrix4 _matrix(Frame frame, Motion motion, double scale) {
    final px = motion.pivotX * scale, py = motion.pivotY * scale;
    return Matrix4.identity()
      ..translateByDouble(frame.dx * scale + px, frame.dy * scale + py, 0, 1)
      ..rotateZ(frame.rotate * 3.141592653589793 / 180)
      ..scaleByDouble(frame.scale, frame.scale, 1, 1)
      ..translateByDouble(-px, -py, 0, 1);
  }
}
