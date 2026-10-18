/// Reads the configuration and applies the window part of it to the native window on the desktop; the web build has no window
/// to place and keeps the defaults.
library;

export 'window_shell_stub.dart' if (dart.library.io) 'window_shell_io.dart';
