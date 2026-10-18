/// Hands the app's face controller down to pages that draw the face themselves (SYSTEM_Face), so they follow the
/// configured and remotely switched look rather than a default of their own.
library;

import 'package:flutter/widgets.dart';

import 'face.dart';

class FaceScope extends InheritedNotifier<FaceController> {
  const FaceScope({super.key, required FaceController controller, required super.child}) : super(notifier: controller);

  /// The app's controller, or null outside the shell (tests that pump a page alone).
  static FaceController? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FaceScope>()?.notifier;
}
