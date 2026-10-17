/// The face theme contract: a theme is a pair of swappable painters, one for the eyes and one for the mouth, plus the
/// geometry the attention overlay needs. The face widget owns the animation state (mode, blink, visemes) and hands
/// each painter a [FaceFrame]; painters only draw. A new look is a new [FaceTheme] with no change to the widget.
library;

import 'dart:ui';

import 'visemes.dart';

enum FaceMode { rest, listening, thinking, speaking }

/// Design frame of every page: the 480 x 800 portrait screen.
const frameWidth = 480.0;
const frameHeight = 800.0;

/// Where the face sits on the frame: the rows its drawing covers and the badge disc radius around the box centre
/// (the compact attention badge scales the whole box into a disc at the bottom of the screen).
class FaceGeometry {
  const FaceGeometry({required this.top, required this.height, required this.badgeRadius});

  final double top;
  final double height;
  final double badgeRadius;

  Offset get centre => Offset(frameWidth / 2, top + height / 2);
}

/// One animation frame's worth of state, in frame coordinates.
class FaceFrame {
  const FaceFrame({required this.mode, required this.eyeOpen, required this.eyeScale, required this.lips, required this.elapsed});

  final FaceMode mode;

  /// 1 fully open, towards 0 closed (blink, sleeping) or narrowed (thinking).
  final double eyeOpen;

  /// 1 normal, above 1 widened (the listen-start flash).
  final double eyeScale;

  /// The tweened mouth outline in the 200 x 100 viseme box ([mouthCx], [mouthCy] at its centre).
  final List<Offset> lips;

  /// Seconds since the widget started, for self-running motion such as the listening bars.
  final double elapsed;
}

abstract class EyesPainter {
  void paint(Canvas canvas, FaceFrame frame);
}

abstract class MouthPainter {
  /// Draws the mouth for [frame]; [frame.lips] is already tweened, so a painter only maps it onto the screen.
  void paint(Canvas canvas, FaceFrame frame);
}

abstract class FaceTheme {
  FaceGeometry get geometry;
  EyesPainter get eyes;
  MouthPainter get mouth;

  /// The viseme outlines this theme tweens between; a theme may rescale the open shapes.
  Map<int, List<Offset>> get mouthShapes;
}
