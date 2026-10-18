/// The visage face (ovos-visage SPEC 9, face.js VISAGE_FACE): lens eyes and the hollow outline mouth on the bare
/// screen. Eyes, strokes and the rest smile are the measured 2018 Kickstarter face; the spacing and the open mouth
/// deviate on purpose so the face reads round and the viseme motion stays visible.
library;

import 'composed_theme.dart';
import 'styles/lens_eyes.dart';
import 'styles/outline_mouth.dart';

export 'composed_theme.dart' show composedMouthShapes;

class VisageTheme extends ComposedTheme {
  const VisageTheme() : super(backdrop: const PlainBackdrop(), eyeStyle: const LensEyes(), mouthStyle: const OutlineMouth());
}
