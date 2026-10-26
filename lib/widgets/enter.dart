/// The item cadence of docs/DESIGN.md, Motion language: items arrive one after another, each a sharp pop that rises
/// and overshoots a little, never a drift. Under reduced motion they stand in place at full opacity.
library;

import 'package:flutter/material.dart';

import 'circle.dart' show motionReduced;

/// One item's pop.
const enterDuration = Duration(milliseconds: 200);

/// The gap between one item's start and the next.
const enterGap = Duration(milliseconds: 100);

/// Items past this index start with it, so a long list does not keep the last rows waiting.
const enterMaxIndex = 5;

/// How far an item rises, and the scale it pops from.
const enterRise = 16.0;
const enterScaleFrom = 0.9;

/// When the item at [index] starts, counted from its build.
Duration enterDelay(int index) => enterGap * index.clamp(0, enterMaxIndex);

/// How the items of an arriving page enter (page_switch.dart): after [delay], once the page has finished its own
/// arrival, or not at all when the page arrives [whole], as a page that slides in does.
class EnterCue extends InheritedWidget {
  const EnterCue({super.key, this.delay = Duration.zero, this.whole = false, required super.child});

  final Duration delay;
  final bool whole;

  static EnterCue? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<EnterCue>();

  @override
  bool updateShouldNotify(EnterCue oldWidget) => oldWidget.delay != delay || oldWidget.whole != whole;
}

/// A column whose children pop in one after another (visage.css .stagger-enter, retimed to the campaign video).
class StaggerEnter extends StatelessWidget {
  const StaggerEnter({super.key, required this.children, this.gap = 28, this.mainAxisSize = MainAxisSize.min});

  final List<Widget> children;
  final double gap;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _Enter(delay: enterDelay(i), child: children[i]),
        ],
      ],
    );
  }
}

/// One item popping in at its place in a list that is not a plain column (StaggerEnter does columns).
class RiseIn extends StatelessWidget {
  const RiseIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Enter(delay: enterDelay(index), child: child);
}

class _Enter extends StatelessWidget {
  const _Enter({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cue = EnterCue.maybeOf(context);
    if (motionReduced(context) || (cue?.whole ?? false)) return child;
    final start = delay + (cue?.delay ?? Duration.zero);
    final total = enterDuration + start;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start.inMicroseconds / total.inMicroseconds, 1),
      builder: (context, t, child) => _pop(t, child!),
      child: child,
    );
  }

  /// The item [t] of the way in: it shows within the first half and pops up from below with a little overshoot.
  static Widget _pop(double t, Widget child) {
    final pop = Curves.easeOutBack.transform(t);
    return Opacity(
      opacity: (2 * t).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, enterRise * (1 - pop)),
        child: Transform.scale(scale: enterScaleFrom + (1 - enterScaleFrom) * pop, child: child),
      ),
    );
  }
}
