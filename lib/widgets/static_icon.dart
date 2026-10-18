import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A bundled icon from assets/icons that has no motion of its own.
Widget staticIcon(String name, {double size = 64}) => SvgPicture.asset('assets/icons/$name.svg', width: size, height: size);
