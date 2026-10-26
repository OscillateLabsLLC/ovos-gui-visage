/// The collapse to a dot of docs/DESIGN.md, Motion language: when listening ends, the face shrinks to one dot at its
/// centre before the answer bursts out of it. The dot ends where a page's line (page_switch.dart) starts, and in the
/// same frame: the collapse takes 300 ms, the line's squash and hold 320 ms. Under reduced motion it is a cut.
library;

import 'package:flutter/widgets.dart';

import 'circle.dart';

const dotCollapse = Duration(milliseconds: 300);

/// The scale the face holds at the end: a dot.
const dotScale = 0.02;

/// [child] shrinking to a dot at [centre] (in its own box) when [collapsed] turns true, and whole again at once when it
/// turns false.
class DotCollapse extends StatefulWidget {
  const DotCollapse({super.key, required this.collapsed, required this.centre, required this.child});

  final bool collapsed;
  final Offset centre;
  final Widget child;

  @override
  State<DotCollapse> createState() => _DotCollapseState();
}

class _DotCollapseState extends State<DotCollapse> with SingleTickerProviderStateMixin {
  late final AnimationController _shrink = AnimationController(
    vsync: this,
    duration: dotCollapse,
    value: widget.collapsed ? 1 : 0,
  );

  @override
  void didUpdateWidget(DotCollapse old) {
    super.didUpdateWidget(old);
    if (old.collapsed == widget.collapsed) return;
    if (!widget.collapsed) {
      _shrink.value = 0;
    } else if (motionReduced(context)) {
      _shrink.value = 1;
    } else {
      _shrink.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shrink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shrink,
      builder: (context, child) {
        final scale = 1 - (1 - dotScale) * Curves.easeIn.transform(_shrink.value);
        final c = widget.centre;
        final transform = Matrix4.translationValues(c.dx, c.dy, 0)
          ..scaleByDouble(scale, scale, 1, 1)
          ..translateByDouble(-c.dx, -c.dy, 0, 1);
        return Transform(transform: transform, child: child);
      },
      child: widget.child,
    );
  }
}
