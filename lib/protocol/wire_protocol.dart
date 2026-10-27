/// Which GUI protocol Visage speaks (WIRE.md, Client behaviour): `auto` probes the GUI-1 adapter and falls back to
/// legacy ovos-gui, `gui1` keeps trying the adapter only, `legacy` never probes. Pure.
library;

enum WireProtocol { auto, gui1, legacy }

/// What a connection actually speaks once the probe is over.
enum ChosenProtocol {
  gui1('GUI-1'),
  legacy('legacy');

  const ChosenProtocol(this.label);

  final String label;
}

/// `auto`, `gui1`, `GUI-1` and `legacy` in any case; null for no value, and [ArgumentError] for any other word.
WireProtocol? wireProtocolFrom(Object? value) {
  if (value == null) return null;
  final key = '$value'.trim().toLowerCase().replaceAll('-', '');
  for (final protocol in WireProtocol.values) {
    if (protocol.name == key) return protocol;
  }
  throw ArgumentError.value(value, 'protocol', 'not auto, gui1 or legacy');
}

/// The menu's line: what this connection speaks, or what Visage is still trying; [lost] once that connection has
/// dropped and Visage is trying again.
String protocolTitle(WireProtocol mode, ChosenProtocol? chosen, {bool lost = false}) => switch ((chosen, mode)) {
  (final ChosenProtocol chosen?, _) when lost => 'Protocol: ${chosen.label} (reconnecting)',
  (final ChosenProtocol chosen?, _) => 'Protocol: ${chosen.label}',
  (null, WireProtocol.gui1) => 'Protocol: GUI-1 (connecting)',
  (null, WireProtocol.legacy) => 'Protocol: legacy',
  (null, WireProtocol.auto) => 'Protocol: detecting…',
};
