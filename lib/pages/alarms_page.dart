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
      if (more > 0) Circle(size: 170, gradient: gradientFill, children: [Text('+$more more', style: VisageText.muted(22).copyWith(fontWeight: FontWeight.w300))]),
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
      children: [if (alarm.ampm.isNotEmpty) TextSpan(text: '  ${alarm.ampm}', style: TextStyle(fontSize: px * 0.35, color: VisageColors.muted))],
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

/// The bell icon; a ringing alarm swings it 14 degrees either way every 0.45 s.
class Bell extends StatefulWidget {
  const Bell({super.key, required this.size, required this.shaking});

  final double size;
  final bool shaking;

  @override
  State<Bell> createState() => _BellState();
}

class _BellState extends State<Bell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    if (widget.shaking) _controller.repeat();
  }

  @override
  void didUpdateWidget(Bell old) {
    super.didUpdateWidget(old);
    if (widget.shaking && !_controller.isAnimating) _controller.repeat();
    if (!widget.shaking && _controller.isAnimating) _controller.animateTo(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(angle: -14 * math.pi / 180 * math.sin(2 * math.pi * _controller.value), child: child),
      child: icon('bell', size: widget.size),
    );
  }
}
