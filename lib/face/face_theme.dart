/// The face theme contract: a theme is a pair of swappable painters, one for the eyes and one for the mouth, plus the
/// geometry the attention overlay needs. The face widget owns the animation state (mode, blink, visemes) and hands
/// each painter a [FaceFrame]; painters only draw. A new look is a new [FaceTheme] with no change to the widget.
library;

import 'dart:ui';

import 'face_palette.dart';
import 'visemes.dart';

export 'face_palette.dart';

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
  const FaceFrame({
    required this.mode,
    required this.eyeOpen,
    required this.eyeScale,
    required this.lips,
    required this.viseme,
    required this.elapsed,
    this.compact = false,
    this.palette = FacePalette.visage,
  });

  final FaceMode mode;

  /// The colours every style paints in.
  final FacePalette palette;

  /// The viseme code (visemes.dart) the mouth is heading for; the rest code outside speech.
  final int viseme;

  /// True inside the compact attention badge, for a theme whose full layout does not fit a disc.
  final bool compact;

  /// 1 fully open, towards 0 closed (blink, sleeping) or narrowed (thinking).
  final double eyeOpen;

  /// 1 normal, above 1 widened (the listen-start flash).
  final double eyeScale;

  /// The tweened mouth outline in the 200 x 100 viseme box ([mouthCx], [mouthCy] at its centre).
  final List<Offset> lips;

  /// Seconds since the widget started, for self-running motion such as the listening bars.
  final double elapsed;

  FaceFrame withPalette(FacePalette palette) => FaceFrame(
    mode: mode,
    eyeOpen: eyeOpen,
    eyeScale: eyeScale,
    lips: lips,
    viseme: viseme,
    elapsed: elapsed,
    compact: compact,
    palette: palette,
  );
}

abstract class EyesPainter {
  void paint(Canvas canvas, FaceFrame frame);
}

/// Where one eye goes: a style draws inside the circle, scaling its own proportions from the radius.
class EyeSlot {
  const EyeSlot(this.centre, this.radius);

  final Offset centre;
  final double radius;
}

/// Where the mouth goes: a style maps its drawing onto this box, so a bigger box is a bigger mouth.
class MouthSlot {
  const MouthSlot(this.centre, this.width, this.height);

  final Offset centre;
  final double width;
  final double height;

  MouthSlot scaled(double k) => MouthSlot(centre, width * k, height * k);
}

/// The slots a backdrop hands to the styles: a left eye, a right eye and a mouth.
class FaceLayout {
  const FaceLayout({required this.left, required this.right, required this.mouth});

  final EyeSlot left;
  final EyeSlot right;
  final MouthSlot mouth;

  List<EyeSlot> get eyes => [left, right];

  FaceLayout withMouth(MouthSlot slot) => FaceLayout(left: left, right: right, mouth: slot);
}

/// An eye look that works in any [FaceLayout]: it reads both slots, so a single-eye style can span them.
abstract class EyeStyle {
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame);
}

/// A mouth look that works in any [MouthSlot].
abstract class MouthStyle {
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame);
}

/// What sits behind the styles and decides where they go: the bare screen, or a faceplate with wells and a window.
abstract class FaceBackdrop {
  FaceGeometry get geometry;

  FaceLayout layout(bool compact);

  /// The largest mouth scale the slot can take here; a hardware window cannot grow.
  double maxMouthScale(bool compact);

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

  /// The colourway the face widget puts into every [FaceFrame].
  FacePalette get palette;

  /// The viseme outlines this theme tweens between; a theme may rescale the open shapes.
  Map<int, List<Offset>> get mouthShapes;
}
