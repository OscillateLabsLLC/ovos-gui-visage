/// The face themes by configuration name.
library;

import '../faults.dart';
import 'face_theme.dart';
import 'mark1_theme.dart';
import 'visage_theme.dart';

final faceThemes = <String, FaceTheme>{'visage': const VisageTheme(), 'mark1': const Mark1Theme()};

FaceTheme faceThemeNamed(String name) {
  final theme = faceThemes[name];
  if (theme == null) {
    reportFault('face theme "$name"', ArgumentError.value(name, 'face', 'not one of ${faceThemes.keys.join(', ')}'));
  }
  return theme ?? const VisageTheme();
}
