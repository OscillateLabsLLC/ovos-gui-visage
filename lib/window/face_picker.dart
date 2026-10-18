/// Opens the face picker page (docs/face-palettes.html) in the default browser, connected to this display's bus. The
/// web build has the page at /faces.html already and opens nothing.
library;

export 'face_picker_stub.dart' if (dart.library.io) 'face_picker_io.dart';
