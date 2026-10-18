/// Reads the configuration, writes the face back into it, and applies the window part to the native window on the
/// desktop; the web build has no file and no window to place and keeps the defaults.
library;

export 'window_shell_stub.dart' if (dart.library.io) 'window_shell_io.dart';
