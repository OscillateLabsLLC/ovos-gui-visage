import '../faults.dart';

/// The web build is a page already, and the sidecar serves the picker beside it at /faces.html.
Future<void> openFacePicker(Uri bus) async => reportFault(
  'opening the face picker',
  UnsupportedError('the web build has no picker to open: the sidecar serves it at /faces.html'),
);
