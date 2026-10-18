/// Where the sockets are on this platform. The desktop talks to its own host (or `OVOS_HOST`); the web build talks
/// to the sidecar that served it, which proxies `/core` and `/gui` so only its port is exposed, or straight to a
/// bus named by `?bus=ws://host:8181` during development.
library;

export 'endpoints_stub.dart' if (dart.library.io) 'endpoints_io.dart' if (dart.library.js_interop) 'endpoints_web.dart';
