import 'dart:io';

import 'bus_endpoints.dart';

BusEndpoints endpoints() => directEndpoints(Platform.environment['OVOS_HOST'] ?? '127.0.0.1');
