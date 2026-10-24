/// The sockets the app holds: the core bus, and either the GUI socket on the port ovos-gui names (SPEC 5.1) or the
/// GUI-1 adapter's (WIRE.md).
class BusEndpoints {
  const BusEndpoints({required this.core, required this.gui, required this.gui1});

  final Uri core;
  final Uri Function(int port) gui;
  final Uri gui1;
}

const coreBusPort = 8181;
const gui1AdapterPort = 18182;

/// Straight to ovos-core and ovos-gui on [host], the same-host display case.
BusEndpoints directEndpoints(String host, {int port = coreBusPort}) => BusEndpoints(
  core: Uri(scheme: 'ws', host: host, port: port, path: '/core'),
  gui: (guiPort) => Uri(scheme: 'ws', host: host, port: guiPort, path: '/gui'),
  gui1: Uri(scheme: 'ws', host: host, port: gui1AdapterPort, path: '/gui1'),
);
