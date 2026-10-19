/// The desktop-only shell pieces: the Linux tray item and drag-to-corner. The web build has neither.
library;

export 'desktop_extras_stub.dart' if (dart.library.io) 'desktop_extras_io.dart';
