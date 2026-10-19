import '../faults.dart';

/// Window plugin calls that a platform may lack. window_manager has no `setHasShadow` or `setVisibleOnAllWorkspaces`
/// on Linux, and the runner's own channel is macOS only, so each call is reported once and the rest of a window
/// setup still runs; the widget is placed and shown whatever cosmetics the platform skips.
final _reported = <String>{};

/// Runs [call]; a failure is reported once per [what] and yields null.
Future<T?> attemptPluginCall<T>(String what, Future<T> Function() call) async {
  try {
    return await call();
  } on Object catch (err, stack) {
    reportPluginFaultOnce(what, err, stack);
    return null;
  }
}

void reportPluginFaultOnce(String what, Object err, StackTrace stack) {
  if (_reported.add(what)) reportFault(what, err, stack);
}
