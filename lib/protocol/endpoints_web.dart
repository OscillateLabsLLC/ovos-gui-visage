import 'bus_endpoints.dart';

BusEndpoints endpoints() {
  final bus = Uri.base.queryParameters['bus'];
  if (bus != null) {
    final direct = Uri.parse(bus);
    return directEndpoints(direct.host, port: direct.hasPort ? direct.port : coreBusPort);
  }
  final page = Uri.base;
  final origin = Uri(scheme: page.scheme == 'https' ? 'wss' : 'ws', host: page.host, port: page.port, path: page.path);
  return BusEndpoints(core: origin.resolve('core'), gui: (_) => origin.resolve('gui'), gui1: origin.resolve('gui1'));
}
