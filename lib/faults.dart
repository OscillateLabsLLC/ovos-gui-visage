import 'package:flutter/foundation.dart';

const _faultFrames = 8;

/// Reports a fault the display survives by showing a fallback, so that it is never silent: FlutterError.onError
/// prints it with the stack, and a test can install its own handler.
void reportFault(String context, Object error, [StackTrace? stack]) => FlutterError.reportError(
  FlutterErrorDetails(exception: error, stack: stack, library: 'ovos-gui-visage', context: ErrorDescription(context)),
);

/// Every build prints each error as one line with its context, then the top of its stack, so what failed reaches the
/// log of a running app. Release and profile builds print the first error's exception without its context, and every
/// later one as `Instance of 'DiagnosticsProperty<void>'` (measured on Linux, v1.1.0). A debug build off the web prints
/// nothing at all: the widget inspector turns on structured errors, which only post a `Flutter.Error` event to the VM
/// service; `flutter run` prints it, a directly launched app does not (finding F36). Debug builds still hand Flutter its
/// own report, for the IDE.
void logFaultsPlainly() {
  FlutterError.onError = (details) {
    debugPrintStack(stackTrace: details.stack, label: faultLine(details), maxFrames: _faultFrames);
    if (kDebugMode) FlutterError.presentError(details);
  };
}

String faultLine(FlutterErrorDetails details) {
  final context = details.context?.toDescription();
  final where = context == null || context.isEmpty ? '' : ' in $context';
  return '${details.library}: fault$where: ${details.exceptionAsString()}';
}
