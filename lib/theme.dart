/// Colour tokens (ovos-visage SPEC 9, visage.css :root): near-black, white text, one blue accent, yellow sun.
library;

import 'package:flutter/material.dart';

abstract final class VisageColors {
  static const bg = Color(0xFF0B0F14);
  static const pageBg = Color(0xFF05070A);

  /// The dim over the page under the full attention face and the in-window menu.
  static const scrim = Color(0xEB05070A);
  static const fg = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A96A8);
  static const accent = Color(0xFF1E9BFF);
  static const accentDim = Color(0xFF0F4C80);
  static const accentSoft = Color(0x2E1E9BFF);
  static const sun = Color(0xFFFFC93C);
  static const sunSoft = Color(0x52FFC93C);
  static const ok = Color(0xFF3DDC84);
  static const bad = Color(0xFFFF5C5C);
  static const card = Color(0xFF141B24);
  static const gradientTop = Color(0xFF1A2533);
  static const clockTop = Color(0xFF0D1A28);
  static const clockBottom = Color(0xFF070B10);
}

/// Text styles used across pages; every page is designed at 480 x 800 so sizes are plain pixels.
abstract final class VisageText {
  static const base = TextStyle(color: VisageColors.fg, fontSize: 16, height: 1.2, decoration: TextDecoration.none);
  static TextStyle muted(double size) => base.copyWith(color: VisageColors.muted, fontSize: size);
  static TextStyle fg(double size, {FontWeight weight = FontWeight.w400, double? height}) =>
      base.copyWith(fontSize: size, fontWeight: weight, height: height);
  static const tabular = [FontFeature.tabularFigures()];
}
