/// Images and animation files named in session data (SCOPE: no middle layer). The desktop reads the ovos-gui cache
/// and OCP's absolute paths from disk, since they come from skills over the GUI socket, the same trust boundary
/// ovos-visage's seen-image registry drew; the web build fetches them from the sidecar's `/res/` and `/res-abs/`.
///
/// `imageFor(value, {fit, broken})` gives a widget for an image value or null when this display cannot load it;
/// `readResource(value)` gives the bytes of a cache or host file.
library;

export 'platform_stub.dart' if (dart.library.io) 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';
