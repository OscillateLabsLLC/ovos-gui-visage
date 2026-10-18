import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Runs [body] collecting what the app reports through lib/faults.dart, instead of the test runner failing on the
/// first report. The caller asserts on the faults: a fixture whose files are not on this machine must report each
/// one, and nothing else.
Future<List<FlutterErrorDetails>> collectFaults(Future<void> Function() body) async {
  final faults = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = faults.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return faults;
}

/// An image the test runner cannot load: a recorded path absent on this machine, or an http image, since the runner's
/// HTTP client answers every request with 400.
bool isUnloadableImage(FlutterErrorDetails fault) {
  final exception = fault.exception;
  if (exception is StateError) return '$exception'.contains('no such file');
  return exception is NetworkImageLoadException;
}
