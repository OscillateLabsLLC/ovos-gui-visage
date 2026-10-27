/// ovos-skill-alerts.openvoiceos / Timer: one ring per timer, stacked (SPEC 8.5, Kickstarter "1 min" frame).
/// Rings are keyed per alertId so the ring animation spans the skill's one-second updates; `longest` remembers the
/// largest delta seen per timer for the progress fallback (alerts_model.dart).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'alert_controls.dart';
import 'alerts_model.dart';
import 'page.dart';

const finished = "Time's up";
const _ringToEm = 18.0;

Color toneColour(TimerTone tone) => switch (tone) {
  TimerTone.calm => VisageColors.accent,
  TimerTone.warm => VisageColors.sun,
  TimerTone.hot || TimerTone.done => VisageColors.bad,
};

Color toneGlow(TimerTone tone) => switch (tone) {
  TimerTone.calm => VisageColors.accentSoft,
  TimerTone.warm => VisageColors.sunSoft,
  TimerTone.hot || TimerTone.done => const Color(0x61FF5C5C),
};

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.data, this.ctx});

  static Widget page(Json data, PageContext ctx) => TimerPage(data: data, ctx: ctx);

  final Json data;

  /// Where the cancel buttons send; none without one (a preview).
  final PageContext? ctx;

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  final longest = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final model = timerModel(widget.data, longest);
    return StaggerEnter(gap: 22, children: [for (final timer in model.timers) _withCancel(timer, model.size)]);
  }

  Widget _withCancel(TimerView timer, double size) {
    final ring = TimerRing(key: ValueKey(timer.id), timer: timer, size: size);
    final ctx = widget.ctx;
    if (ctx == null) return ring;
    void cancel() => sendAlertEvent(ctx, cancelTimer, cancelTimerParameters(widget.data, timer.id));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ring,
        Positioned(
          right: 0,
          top: 0,
          child: TimerCancelButton(expired: timer.expired, onPressed: cancel, size: size < 200 ? 36 : 44),
        ),
      ],
    );
  }
}

class TimerRing extends StatelessWidget {
  const TimerRing({super.key, required this.timer, required this.size});

  final TimerView timer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final em = size / _ringToEm;
    final ring = Ring(fraction: timer.fraction, value: toneColour(timer.tone));
    return Circle(
      size: size,
      gradient: gradientFill,
      glow: Glow(colour: toneGlow(timer.tone), loop: timer.expired, bloom: true),
      ring: timer.expired ? _Pulse(child: ring) : ring,
      children: [
        Padding(
          padding: EdgeInsets.all(size * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timer.expired ? finished : timer.delta,
                maxLines: 1,
                style: VisageText.fg(
                  timer.expired ? 2.9 * em : 3.6 * em,
                  weight: timer.expired ? FontWeight.w400 : FontWeight.w300,
                  height: 1,
                ).copyWith(fontFeatures: VisageText.tabular),
              ),
              SizedBox(height: 0.45 * em),
              Text(
                timer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VisageText.muted(1.1 * em < 11 ? 11 : 1.1 * em),
              ),
              if (timer.expired) ...[
                SizedBox(height: 0.2 * em),
                Text(timer.delta, style: VisageText.muted(em < 11 ? 11 : em).copyWith(fontFeatures: VisageText.tabular)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// An expired timer's ring breathes between full and a third opacity once a second; under reduced motion it holds full.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
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
    if (_still) return widget.child;
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
