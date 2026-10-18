/// The palettes: every eye style, mouth style and backdrop by name, and the named presets (docs/FACE_PALETTES.md).
library;

import 'composed_theme.dart';
import 'face_theme.dart';
import 'mark1_theme.dart';
import 'styles/aperture_eyes.dart';
import 'styles/grille_mouth.dart';
import 'styles/lens_eyes.dart';
import 'styles/line_mouths.dart';
import 'styles/matrix_mouth.dart';
import 'styles/outline_mouth.dart';
import 'styles/ring_eyes.dart';
import 'styles/shape_eyes.dart';

const eyeStyles = <String, EyeStyle>{
  'lens': LensEyes(),
  'ring': RingEyes(),
  'block': BlockEyes(),
  'visor': VisorEyes(),
  'aperture': ApertureEyes(),
  'mono': ApertureEyes(single: true),
  'oval': OvalEyes(),
  'pixel': PixelEyes(),
  'dot': DotEyes(),
};

const mouthStyles = <String, MouthStyle>{
  'outline': OutlineMouth(),
  'solid': SolidMouth(),
  'matrix': MatrixMouth(),
  'waveform': WaveformMouth(),
  'bars': BarsMouth(),
  'grille': GrilleMouth(),
  'orb': OrbMouth(),
  'none': NoMouth(),
};

const backdrops = <String, FaceBackdrop>{'none': PlainBackdrop(), 'mark1': PlateBackdrop()};

/// Mouth size names and the slot scale each means.
const mouthSizes = <String, double>{'regular': 1, 'large': 1.4};

/// A named pairing: eyes, mouth and, where they are part of the look, the backdrop and the colourway.
class FacePreset {
  const FacePreset(this.eyes, this.mouth, {this.backdrop = 'none', this.colours = FacePalette.visage});

  final String eyes;
  final String mouth;
  final String backdrop;
  final FacePalette colours;
}

const facePresets = <String, FacePreset>{
  'visage': FacePreset('lens', 'outline'),
  'mark1': FacePreset('ring', 'matrix', backdrop: 'mark1', colours: FacePalette.mark1),
  'scanner': FacePreset('visor', 'matrix'),
  'robot': FacePreset('block', 'solid'),
  'retro': FacePreset('ring', 'waveform'),
  'hybrid': FacePreset('lens', 'matrix'),
  'camera': FacePreset('aperture', 'grille'),
  'pod': FacePreset('oval', 'none'),
  'led': FacePreset('pixel', 'matrix'),
  'orbit': FacePreset('mono', 'orb'),
  'buddy': FacePreset('dot', 'bars'),
};
