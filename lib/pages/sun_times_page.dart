/// ovos-skill-weather SunriseSunset: a sunrise circle and a sunset circle, each a horizon gradient with the sun
/// rising or settling over 8 s (SPEC 8.3, skills.css .sun-time); under reduced motion the sun holds its first frame.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/weather_icon.dart';
import 'page.dart';
import 'skill_header.dart';
import 'weather_model.dart';

const _sunrise = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0D1A28), Color(0xFF1B2C44), Color(0xFF5A3A24)],
  stops: [0, 0.6, 1],
);
const _sunset = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF2A1830), Color(0xFF5A2B25), Color(0xFF0D1A28)],
  stops: [0, 0.65, 1],
);

class SunTimesPage extends StatelessWidget {
  const SunTimesPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => SunTimesPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final model = sunTimesModel(data);
    return StaggerEnter(
      mainAxisSize: MainAxisSize.max,
      children: [
        SkillHeader(heading: model.heading, location: model.location),
        _SunCircle(kind: 'sunrise', value: model.sunrise, gradient: _sunrise, rising: true),
        _SunCircle(kind: 'sunset', value: model.sunset, gradient: _sunset, rising: false),
      ],
    );
  }
}

class _SunCircle extends StatefulWidget {
  const _SunCircle({required this.kind, required this.value, required this.gradient, required this.rising});

  final String kind;
  final String value;
  final Gradient gradient;
  final bool rising;

  @override
  State<_SunCircle> createState() => _SunCircleState();
}

class _SunCircleState extends State<_SunCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
    value: widget.rising ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionReduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: 205,
      gradient: widget.gradient,
      glow: const Glow(colour: VisageColors.sunSoft, bloom: true),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) =>
                  Transform.translate(offset: Offset(0, 8 - 14 * Curves.easeInOut.transform(_controller.value)), child: child),
              child: const WeatherIcon('sun', size: 64),
            ),
            const SizedBox(height: 6),
            Text(
              widget.value,
              style: VisageText.fg(40, weight: FontWeight.w300, height: 1).copyWith(fontFeatures: VisageText.tabular),
            ),
            const SizedBox(height: 4),
            Text(widget.kind.toUpperCase(), style: VisageText.muted(16).copyWith(letterSpacing: 2)),
          ],
        ),
      ],
    );
  }
}
