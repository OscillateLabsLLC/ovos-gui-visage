import 'dart:io';

import 'bus_endpoints.dart';

/// `OVOS_HOST` and `OVOS_PORT` name the core bus; the GUI sockets sit on the same host.
BusEndpoints endpoints() {
  final env = Platform.environment;
  return directEndpoints(env['OVOS_HOST'] ?? '127.0.0.1', port: int.tryParse(env['OVOS_PORT'] ?? '') ?? coreBusPort);
}
