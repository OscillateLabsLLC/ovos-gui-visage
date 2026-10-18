import 'package:flutter/foundation.dart';

/// Reports a fault the display survives by showing a fallback, so that it is never silent: FlutterError.onError
/// prints it with the stack, and a test can install its own handler.
void reportFault(String context, Object error, [StackTrace? stack]) => FlutterError.reportError(
  FlutterErrorDetails(exception: error, stack: stack, library: 'ovos-gui-visage', context: ErrorDescription(context)),
);
