import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/gui1_client.dart';
import 'package:ovos_gui_visage/protocol/gui_events.dart';
import 'package:ovos_gui_visage/protocol/gui_link.dart';
import 'package:ovos_gui_visage/screen_link.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'gui1_client_test.dart' show FakeLegacy, FakeSocket;
import 'gui1_fixture.dart';

const _welcome = {'type': 'welcome', 'protocol': 'ovos-gui-1', 'version': 1, 'session_id': 'default', 'server': 'fake/1'};

Future<GuiLink> _link(WireProtocol mode, FakeSocket socket, FakeLegacy legacy) async {
  final link = GuiLink(
    mode: mode,
    legacy: legacy,
    gui1: Gui1Client(url: Uri.parse('ws://127.0.0.1:1/gui1'), connector: (_) => socket, onFrame: (_) {}, onStatus: (_) {}),
  )..start();
  await pumpEventQueue();
  socket.serve(_welcome);
  await pumpEventQueue();
  return link;
}

/// What the screen announces while [frames] arrive: each frame applied, then the current target handed over, as
/// main.dart's refresh does.
void _drive(FocusAnnouncer focus, List<Gui1Frame> frames) {
  final state = GuiState();
  for (final frame in frames) {
    replayGui1([frame], state: state);
    focus.update(state.current());
  }
}

/// The live clear-then-show of demo-skill.gui1 (2026-10-24): the same page leaves and comes back.
final _clearThenShow = <Gui1Frame>[
  template(hello, 'SYSTEM_text', {'text': 'Hello'}),
  const Gui1Deactivated(skillId: hello, sessionId: defaultSessionId),
  template(hello, 'SYSTEM_text', {'text': 'Hello again'}),
];

void main() {
  test('on GUI-1 the announcer sends nothing: focus there is a request, and the service knows what it dispatched', () async {
    final socket = FakeSocket();
    final legacy = FakeLegacy();
    final link = await _link(WireProtocol.gui1, socket, legacy);
    _drive(FocusAnnouncer(link), _clearThenShow);
    expect([socket.sent, legacy.sends], [hasLength(1), isEmpty], reason: 'only the hello');
    await link.stop();
  });

  test('on legacy a target that does not change is announced once', () async {
    final legacy = FakeLegacy();
    final link = await _link(WireProtocol.legacy, FakeSocket(), legacy);
    final focus = FocusAnnouncer(link)
      ..update(const Target(hello, 'SYSTEM_text', 0))
      ..update(const Target(hello, 'SYSTEM_text', 0));
    focus.update(const Target(alerts, 'SYSTEM_text', 0));
    expect(legacy.sends, [focusMessage(hello, 0), focusMessage(alerts, 0)]);
  });

  test('legacy keeps announcing a page once, even across an empty screen, and only on the GUI socket', () async {
    final socket = FakeSocket();
    final legacy = FakeLegacy();
    final link = await _link(WireProtocol.legacy, socket, legacy);
    _drive(FocusAnnouncer(link), _clearThenShow);
    expect(legacy.sends, [focusMessage(hello, 0)]);
    expect(socket.sent, isEmpty);
  });
}
