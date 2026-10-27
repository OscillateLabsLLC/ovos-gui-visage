/// The birth of the resting chips (docs/DESIGN.md, Motion language): one accent disc pops in, stretches into a peanut,
/// splits into two discs that land where the chips sit, and the chips' content fades in. With one chip the disc grows
/// into it. The frame is a pure function of time, so it is tested frame by frame; the painter draws circles and one
/// capsule, no blur. Under reduced motion the chips stand at once.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../frame_log.dart';
import '../theme.dart';
import 'circle.dart';

const birthPop = Duration(milliseconds: 100);
const birthStretch = Duration(milliseconds: 200);
const birthSplit = Duration(milliseconds: 100);
const birthContent = Duration(milliseconds: 100);
final birthLength = birthPop + birthStretch + birthSplit + birthContent;

/// The popped disc against the chips' mean radius; how far the peanut's halves part, and how thin its waist gets.
const _popRadius = 0.6;
const _peanutPart = 0.75;
const _peanutWaist = 0.45;

/// A chip the birth lands on: its centre's offset below the box centre, and its diameter.
typedef BirthChip = ({double dy, double size});

/// A disc of the birth: its centre's offset below the box centre, and its radius.
typedef Disc = ({double dy, double radius});

/// One frame: the discs, the width of the capsule joining two of them (0 for none), the discs' opacity and the
/// opacity of the real chips beneath.
typedef BirthFrame = ({List<Disc> discs, double waist, double discOpacity, double content});

/// [sizes] stacked top to bottom [gap] apart and centred, as a centred column lays them out.
List<BirthChip> stackedChips(List<double> sizes, double gap) {
  final height = sizes.fold(0.0, (sum, size) => sum + size) + gap * (sizes.length - 1);
  var top = -height / 2;
  final chips = <BirthChip>[];
  for (final size in sizes) {
    chips.add((dy: top + size / 2, size: size));
    top += size + gap;
  }
  return chips;
}

double _phase(Duration elapsed, Duration from, Duration length) =>
    ((elapsed - from).inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

/// The birth of [chips] (one or two, top to bottom) [elapsed] after it starts.
BirthFrame birthFrame(Duration elapsed, List<BirthChip> chips) {
  if (elapsed >= birthLength) return (discs: const [], waist: 0, discOpacity: 0, content: 1);
  final landed = [for (final chip in chips) (dy: chip.dy, radius: chip.size / 2)];
  final splitEnds = birthPop + birthStretch + birthSplit;
  if (elapsed >= splitEnds) {
    final fade = _phase(elapsed, splitEnds, birthContent);
    return (discs: landed, waist: 0, discOpacity: 1 - fade, content: fade);
  }
  final mean = landed.fold(0.0, (sum, disc) => sum + disc.radius) / landed.length;
  final centre = (landed.first.dy + landed.last.dy) / 2;
  final popped = Curves.easeOutBack.transform(_phase(elapsed, Duration.zero, birthPop)) * _popRadius * mean;
  if (elapsed < birthPop) return (discs: [(dy: centre, radius: popped)], waist: 0, discOpacity: 1, content: 0);
  final stretch = Curves.easeInOut.transform(_phase(elapsed, birthPop, birthStretch));
  final split = Curves.easeOut.transform(_phase(elapsed, birthPop + birthStretch, birthSplit));
  if (landed.length == 1) {
    final radius = lerpDouble(popped, landed.single.radius, stretch)!;
    return (discs: [(dy: centre, radius: radius)], waist: 0, discOpacity: 1, content: 0);
  }
  return _peanut(landed, centre, popped, stretch, split);
}

/// Two halves parting from [centre] as [stretch] runs, joined by a thinning waist, then flying to [landed] as [split]
/// runs while the waist lets go.
BirthFrame _peanut(List<Disc> landed, double centre, double popped, double stretch, double split) {
  final part = popped * _peanutPart * stretch;
  final half = popped * (1 - 0.1 * stretch);
  final discs = [
    for (final (i, disc) in landed.indexed)
      (dy: lerpDouble(centre + (i == 0 ? -part : part), disc.dy, split)!, radius: lerpDouble(half, disc.radius, split)!),
  ];
  final waist = 2 * half * (1 - _peanutWaist * stretch) * (1 - split);
  return (discs: discs, waist: waist, discOpacity: 1, content: 0);
}

/// [child] (the chips, as a centred column) born from one accent disc when it first builds.
class ChipBirth extends StatefulWidget {
  const ChipBirth({super.key, required this.chips, required this.child});

  final List<BirthChip> chips;
  final Widget child;

  @override
  State<ChipBirth> createState() => _ChipBirthState();
}

class _ChipBirthState extends State<ChipBirth> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: birthLength)..addStatusListener(_logEnd);
  bool _born = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionReduced(context)) {
      _clock.value = 1;
    } else if (_clock.isDismissed) {
      _clock.forward();
      _born = true;
      logMove('birth start');
    }
  }

  void _logEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed && _born) logMove('birth end');
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, child) {
        final frame = birthFrame(birthLength * _clock.value, widget.chips);
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(opacity: frame.content, child: child),
            if (frame.discs.isNotEmpty) Positioned.fill(child: CustomPaint(painter: _BirthPainter(frame))),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _BirthPainter extends CustomPainter {
  _BirthPainter(this.frame);

  final BirthFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final paint = Paint()..color = VisageColors.accent.withValues(alpha: frame.discOpacity);
    for (final disc in frame.discs) {
      canvas.drawCircle(centre + Offset(0, disc.dy), disc.radius, paint);
    }
    if (frame.waist <= 0 || frame.discs.length < 2) return;
    final neck = Rect.fromLTRB(
      centre.dx - frame.waist / 2,
      centre.dy + frame.discs.first.dy,
      centre.dx + frame.waist / 2,
      centre.dy + frame.discs.last.dy,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(neck, Radius.circular(frame.waist / 2)), paint);
  }

  @override
  bool shouldRepaint(_BirthPainter old) => old.frame != frame;
}
