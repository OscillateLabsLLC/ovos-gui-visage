/// A weather icon from the bundled set with the motion its SVG carried in CSS (rays turn, clouds drift, drops
/// fall, flakes flutter, the bolt flashes, stars twinkle), layer by layer through [MotionIcon].
library;

import 'package:flutter/widgets.dart';

import 'motion_icon.dart';

class WeatherIcon extends StatelessWidget {
  const WeatherIcon(this.name, {super.key, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => MotionIcon(name, size: size);
}
