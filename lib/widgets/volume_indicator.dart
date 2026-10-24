/// The brief volume display in the status row: ten dots that light in the face's accent, as ovos-shell's
/// SliderControl meter, with a speaker glyph and the level. A part-lit dot shows the remainder; muted keeps the level
/// in grey without the glow.
library;

import 'package:flutter/material.dart';

import '../face/face_palette.dart';
import '../face/face_scope.dart';
import '../theme.dart';

const volumeFade = Duration(milliseconds: 250);
const volumeDots = 10;
const _dot = 7.0;

/// Room for "100%", so the pill does not jitter as the level changes; "Muted" may widen it.
const _labelWidth = 34.0;
const _pillBackground = Color(0xE6141B24);

/// How lit dot [index] is for [level] (0 to 1): 0.38 lights three dots and most of the fourth.
double dotLight(double level, int index) => (level * volumeDots - index).clamp(0, 1).toDouble();

String volumeLabel(double? level, {required bool muted}) {
  if (muted) return 'Muted';
  return level == null ? 'Volume' : '${(level * 100).round()}%';
}

class VolumeIndicator extends StatelessWidget {
  const VolumeIndicator({super.key, required this.showing, required this.level, required this.muted});

  final bool showing;
  final double? level;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = FaceScope.maybeOf(context)?.theme.palette ?? FacePalette.visage;
    return AnimatedSwitcher(
      duration: volumeFade,
      child: showing
          ? _Meter(
              key: const ValueKey('volume'),
              level: level ?? 0,
              muted: muted,
              label: volumeLabel(level, muted: muted),
              lit: palette.accent,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({super.key, required this.level, required this.muted, required this.label, required this.lit});

  final double level;
  final bool muted;
  final String label;
  final Color lit;

  Color get _colour => muted ? VisageColors.muted : VisageColors.fg;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: muted ? 'Volume muted' : 'Volume $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: _pillBackground, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 14, color: _colour),
            _dots(),
            _label(),
          ],
        ),
      ),
    );
  }

  Widget _dots() => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      for (var i = 0; i < volumeDots; i++) _Dot(light: dotLight(level, i), lit: muted ? VisageColors.muted : lit, glow: !muted),
    ],
  );

  Widget _label() => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _labelWidth),
    child: Text(
      label,
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.end,
      style: VisageText.fg(12).copyWith(color: _colour, fontFeatures: VisageText.tabular),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.light, required this.lit, required this.glow});

  final double light;
  final Color lit;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(VisageColors.accentDim.withValues(alpha: 0.6), lit, light)!;
    return AnimatedContainer(
      duration: volumeFade,
      width: _dot,
      height: _dot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        boxShadow: [if (glow && light > 0) BoxShadow(color: lit.withValues(alpha: 0.6 * light), blurRadius: 6)],
      ),
    );
  }
}
