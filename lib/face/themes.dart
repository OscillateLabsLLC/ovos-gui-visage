/// A face theme from a configuration string: a preset name such as `mark1`, or `eyes+mouth` tokens (face_spec.dart).
library;

import 'face_spec.dart';
import 'face_theme.dart';

FaceTheme faceThemeNamed(String name) => FaceSpec.parse(name).theme();
