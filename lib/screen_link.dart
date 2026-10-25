/// The screen's GUI connection and what its traffic does: either protocol fills the same [GuiState], and the system
/// events of each (legacy `mycroft.events.triggered` in `system`, GUI-1 `status`) drive [Attention].
library;

import 'app_config.dart';
import 'attention.dart';
import 'protocol/bus_endpoints.dart';
import 'protocol/core_bus.dart';
import 'protocol/gui1_client.dart';
import 'protocol/gui_client.dart';
import 'protocol/gui_link.dart';
import 'state/gui1_apply.dart';
import 'state/gui_state.dart';

GuiLink screenLink({
  required AppConfig config,
  required BusEndpoints sockets,
  required CoreBus bus,
  required GuiState state,
  required Attention attention,
  required void Function() onChanged,
  required GuiStatusHandler onStatus,
  required void Function(String) log,
}) => GuiLink(
  mode: config.protocol,
  legacy: GuiClient(
    bus: bus,
    guiUrlOverride: sockets.gui,
    guiId: 'ovos-gui-visage-${DateTime.now().millisecondsSinceEpoch % 100000}',
    onMessage: (message) {
      applyLegacyMessage(state, attention, message, log);
      onChanged();
    },
    onStatus: onStatus,
    log: log,
  ),
  gui1: Gui1Client(
    url: config.gui1Url ?? sockets.gui1,
    onFrame: (frame) {
      applyGui1(state, attention, frame);
      onChanged();
    },
    onStatus: onStatus,
    log: log,
  ),
  log: log,
);

void applyLegacyMessage(GuiState state, Attention attention, Json message, void Function(String) log) {
  if (!state.apply(message)) log('unknown GUI message $message');
  if (message['type'] == 'mycroft.events.triggered' && message['namespace'] == systemNamespace) {
    attention.handle(message['event_name'] as String, (message['data'] ?? <String, dynamic>{}) as Json);
  }
}

void applyGui1(GuiState state, Attention attention, Gui1Frame frame, {Gui1Gaps? gaps}) {
  if (frame case Gui1Status(:final eventName, :final data)) attention.handle(eventName, data);
  applyGui1Frame(state, frame, gaps: gaps);
}

/// Tells legacy ovos-gui which page the screen shows, once per change (`page_gained_focus`, as the Qt GUI did); the
/// memory survives an empty screen, as it always has, since ovos-gui announces a page it shows again itself. On GUI-1
/// it says nothing: `focus` there is a request that changes the active entry, and the service already knows the entry
/// it dispatched (WIRE.md, Client → server frames). A swipe asks through `GuiLink.requestFocus` instead.
class FocusAnnouncer {
  FocusAnnouncer(this.link);

  final GuiLink link;
  Target? _last;

  void update(Target? target) {
    if (link.chosen == ChosenProtocol.gui1) {
      _last = null;
      return;
    }
    if (target == null) return;
    if (target == _last) return;
    _last = target;
    link.send(focusMessage(target.namespace, target.index));
  }

  void reset() => _last = null;
}
