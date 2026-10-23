import 'package:flutter/foundation.dart';

const _faultFrames = 8;

/// Reports a fault the display survives by showing a fallback, so that it is never silent: FlutterError.onError
/// prints it with the stack, and a test can install its own handler.
void reportFault(String context, Object error, [StackTrace? stack]) => FlutterError.reportError(
  FlutterErrorDetails(exception: error, stack: stack, library: 'ovos-gui-visage', context: ErrorDescription(context)),
);

/// Release and profile builds print the first error's exception without its context, and every later one as
/// `Instance of 'DiagnosticsProperty<void>'` (measured on Linux, v1.1.0), so what failed never reached the log. There,
/// every error prints one line with its context, then the top of its stack. Debug builds keep Flutter's own report.
void logFaultsPlainly() {
  if (kDebugMode) return;
  FlutterError.onError = (details) =>
      debugPrintStack(stackTrace: details.stack, label: faultLine(details), maxFrames: _faultFrames);
}

String faultLine(FlutterErrorDetails details) {
  final context = details.context?.toDescription();
  final where = context == null || context.isEmpty ? '' : ' in $context';
  return '${details.library}: fault$where: ${details.exceptionAsString()}';
}
