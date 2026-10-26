/// Reduced motion for the template pages: when the platform asks for no animation, a page draws its still frame, as
/// MotionIcon does. StaggerEnter and RiseIn stand still by themselves; these wrappers also leave them out of the tree,
/// which the template pages' still-frame test checks.
library;

import 'package:flutter/widgets.dart';

import '../widgets/circle.dart';

bool reducedMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// [StaggerEnter], or the same centred column standing still.
class StaggerOrStill extends StatelessWidget {
  const StaggerOrStill({super.key, required this.children, this.gap = 28});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!reducedMotion(context)) return StaggerEnter(gap: gap, children: children);
    return Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, spacing: gap, children: children);
  }
}

/// [RiseIn] for the item at [index] (capped like StaggerEnter's delay), or the item standing still.
class RiseOrStill extends StatelessWidget {
  const RiseOrStill({super.key, required this.index, required this.child});

  static const maxDelayIndex = 5;

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      reducedMotion(context) ? child : RiseIn(index: index.clamp(0, maxDelayIndex), child: child);
}
