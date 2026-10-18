/// The two sockets the app holds: the core bus, and the GUI socket on the port ovos-gui names (SPEC 5.1).
class BusEndpoints {
  const BusEndpoints({required this.core, required this.gui});

  final Uri core;
  final Uri Function(int port) gui;
}

const coreBusPort = 8181;

/// Straight to ovos-core and ovos-gui on [host], the same-host display case.
BusEndpoints directEndpoints(String host, {int port = coreBusPort}) => BusEndpoints(
  core: Uri(scheme: 'ws', host: host, port: port, path: '/core'),
  gui: (guiPort) => Uri(scheme: 'ws', host: host, port: guiPort, path: '/gui'),
);
