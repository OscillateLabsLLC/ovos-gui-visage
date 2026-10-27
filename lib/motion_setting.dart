/// The motion switch (`VISAGE_MOTION`, `motion` in the config file): `full`, the default, or `cut` for slow hardware.
/// With `cut` every move cuts to its final frame, as under the platform's reduce-motion setting: the app's root
/// MediaQuery reports animations disabled, so every widget that reads `motionReduced` obeys without a change.
library;

import 'package:flutter/widgets.dart';

enum MotionSetting { full, cut }

/// [value] as a setting; null when unset, an ArgumentError for anything else.
MotionSetting? motionSettingFrom(Object? value) {
  if (value == null) return null;
  final word = '$value'.trim().toLowerCase();
  for (final setting in MotionSetting.values) {
    if (setting.name == word) return setting;
  }
  throw ArgumentError.value(value, 'motion', 'not full or cut');
}

/// The MaterialApp builder for [setting]: under `cut`, everything beneath it, every route included, sees
/// `disableAnimations`.
TransitionBuilder motionBuilder(MotionSetting setting) => (context, child) {
  final app = child ?? const SizedBox.shrink();
  if (setting == MotionSetting.full) return app;
  return MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: app);
};
