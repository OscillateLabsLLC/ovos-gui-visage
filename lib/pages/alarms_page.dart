/// ovos-skill-alerts.openvoiceos / AlarmsOverviewCard (SPEC 8.5): gradient ring chips with a bell for one or two
/// alarms; beyond that a two-by-two grid of gradient circles, "+n more" past four. A ringing (expired) alarm is the
/// loudest thing on screen: shaking bell, red bloom on a loop. Otherwise only the next to fire glows.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'alerts_model.dart';
import 'page.dart';

const ringing = 'Ringing';
const _ringingGlow = Color(0x61FF5C5C);
const _maxChips = 2;

class AlarmsPage extends StatelessWidget {
  const AlarmsPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => AlarmsPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final alarms = alarmsModel(data);
    final next = nextToFire(alarms);
    final two = alarms.length == _maxChips;
    return StaggerEnter(
      gap: 22,
      children: [
        const AlertsHeader('Alarms'),
        if (alarms.isEmpty) Text('No alarms', style: VisageText.muted(18)),
        if (alarms.length > _maxChips)
          _grid(alarms)
        else
          for (final alarm in alarms) _AlarmChip(alarm: alarm, isNext: alarm.id == next, small: two),
      ],
    );
  }

  Widget _grid(List<AlarmView> alarms) {
    final (:shown, :more, :next) = alarmGrid(alarms);
    final cells = [
      for (final alarm in shown) _AlarmCell(alarm: alarm, isNext: alarm.id == next),
      if (more > 0)
        Circle(
          size: 170,
          gradient: gradientFill,
          children: [Text('+$more more', style: VisageText.muted(22).copyWith(fontWeight: FontWeight.w300))],
        ),
    ];
    return Wrap(
      spacing: 22,
      runSpacing: 18,
      alignment: WrapAlignment.center,
      children: [for (final cell in cells) SizedBox(width: 170, child: Center(child: cell))],
    );
  }
}

class AlertsHeader extends StatelessWidget {
  const AlertsHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), textAlign: TextAlign.center, style: VisageText.muted(15).copyWith(letterSpacing: 1));
}

Widget _timeText(AlarmView alarm, double px) {
  return Text.rich(
    TextSpan(
      text: alarm.time,
      children: [
        if (alarm.ampm.isNotEmpty)
          TextSpan(
            text: '  ${alarm.ampm}',
            style: TextStyle(fontSize: px * 0.35, color: VisageColors.muted),
          ),
      ],
    ),
    maxLines: 1,
    style: VisageText.fg(px, weight: FontWeight.w300, height: 1).copyWith(fontFeatures: VisageText.tabular),
  );
}

class _AlarmChip extends StatelessWidget {
  const _AlarmChip({required this.alarm, required this.isNext, required this.small});

  final AlarmView alarm;
  final bool isNext;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 210.0 : 260.0;
    return Circle(
      size: size,
      gradient: gradientFill,
      glow: alarm.expired ? const Glow(colour: _ringingGlow, loop: true) : (isNext ? const Glow() : null),
      ring: Ring(value: alarm.expired ? VisageColors.bad : VisageColors.accent),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Bell(size: small ? 52 : 72, shaking: alarm.expired),
            SizedBox(height: small ? 2 : 4),
            _timeText(alarm, small ? 44 : 56),
            SizedBox(height: small ? 4 : 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size * 0.8),
              child: Text(alarm.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(small ? 16 : 18)),
            ),
            const SizedBox(height: 2),
            if (alarm.expired) const _Label(ringing) else Text(alarm.repeat, style: VisageText.muted(14)),
          ],
        ),
      ],
    );
  }
}

class _AlarmCell extends StatelessWidget {
  const _AlarmCell({required this.alarm, required this.isNext});

  final AlarmView alarm;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: 170,
      gradient: gradientFill,
      glow: alarm.expired ? const Glow(colour: _ringingGlow, loop: true) : (isNext ? const Glow() : null),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Bell(size: 34, shaking: alarm.expired),
            const SizedBox(height: 2),
            _timeText(alarm, 44),
            const SizedBox(height: 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 128),
              child: Text(alarm.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(15)),
            ),
            if (alarm.expired) const Padding(padding: EdgeInsets.only(top: 2), child: _Label(ringing, px: 11)),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.px = 13});

  final String text;
  final double px;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: VisageText.fg(px).copyWith(letterSpacing: 1));
}

/// The bell icon, pivoting at its hanger (bell.svg's transform-origin, 9 of 64 from the top). At rest it swings
/// once every 3.2 s as the SVG's CSS did (still for 70 % of the cycle, then 14, -11, 6, -3 degrees); a ringing
/// alarm shakes it 14 degrees either way every 0.45 s.
class Bell extends StatefulWidget {
  const Bell({super.key, required this.size, required this.shaking});

  final double size;
  final bool shaking;

  @override
  State<Bell> createState() => _BellState();
}

const _swingCycle = Duration(milliseconds: 3200);
const _shakeCycle = Duration(milliseconds: 450);
const _pivot = Alignment(0, -0.72);
// (cycle fraction, degrees) keyframes of the rest swing.
const _swingKeys = [(0.0, 0.0), (0.7, 0.0), (0.76, 14.0), (0.84, -11.0), (0.91, 6.0), (0.96, -3.0), (1.0, 0.0)];

double swingDegrees(double t) {
  for (var i = 1; i < _swingKeys.length; i++) {
    final (t0, a0) = _swingKeys[i - 1];
    final (t1, a1) = _swingKeys[i];
    if (t <= t1) return a0 + (a1 - a0) * Curves.easeInOut.transform((t - t0) / (t1 - t0));
  }
  return 0;
}

class _BellState extends State<Bell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: _cycle)..repeat();

  Duration get _cycle => widget.shaking ? _shakeCycle : _swingCycle;

  @override
  void didUpdateWidget(Bell old) {
    super.didUpdateWidget(old);
    if (old.shaking != widget.shaking) {
      _controller
        ..duration = _cycle
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _degrees(double t) => widget.shaking ? -14 * math.sin(2 * math.pi * t) : swingDegrees(t);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.rotate(angle: _degrees(_controller.value) * math.pi / 180, alignment: _pivot, child: child),
      child: icon('bell', size: widget.size),
    );
  }
}
