import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/volume.dart';
import 'package:ovos_gui_visage/volume_controls.dart';
import 'package:ovos_gui_visage/window/peek.dart';

import 'corebus_fixture.dart';
import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

class _ClosedBus extends CoreBus {
  @override
  bool emit(String type, [Json? data]) => false;
}

List<Json> _outgoing() => [
  for (final line in File('test/fixtures/outgoing/volume_controls.jsonl').readAsLinesSync())
    if (line.trim().isNotEmpty) jsonDecode(line) as Json,
];

/// What CoreBus puts on the wire for an emit with no data.
Json _wireData(Json? data) => data ?? {};

void main() {
  late RecordingBus bus;
  late VolumeControls controls;

  setUp(() {
    bus = RecordingBus();
    controls = VolumeControls(bus);
  });

  test('each outgoing message matches its recorded fixture: type and data', () {
    for (final action in VolumeAction.values) {
      controls.act(action);
    }
    controls.askLevel();
    final sent = [
      for (final e in bus.emitted) [e[0], _wireData(e[1] as Json?)],
    ];
    final recorded = {for (final line in _outgoing()) line['type']: line['data']};
    expect(sent, [
      for (final type in ['mycroft.volume.increase', 'mycroft.volume.decrease', 'mycroft.volume.mute.toggle', volumeGetEvent])
        [type, recorded[type]],
    ]);
  });

  test('no outgoing message carries a percent: set is never sent, whose scale the two plugins disagree on', () {
    expect([for (final line in _outgoing()) line['type']], isNot(contains('mycroft.volume.set')));
    expect([for (final a in VolumeAction.values) a.event], isNot(contains('mycroft.volume.set')));
  });

  test('a closed bus is reported for each control', () async {
    controls = VolumeControls(_ClosedBus());
    final faults = await collectFaults(() async {
      for (final action in VolumeAction.values) {
        controls.act(action);
      }
    });
    expect(faults, hasLength(VolumeAction.values.length));
    expect('${faults.first.exception}', contains('mycroft.volume.increase'));
  });

  test('the recorded voice "turn the volume up": the skill\'s own get is not this app\'s cue; the confirm is', () {
    final timers = ManualTimers();
    var asks = 0;
    final model = VolumeModel(ask: () => ++asks > 0, timer: timers.create);
    for (final (type, data) in coreBusFixture('volume_mac_voice_up')) {
      model.handle(type, data);
    }
    expect(asks, 1);
    expect([model.level, model.showing], [0.3, true]);
  });

  test('a peeking widget stays open while a change shows, and is let go when it hides', () {
    final timers = ManualTimers();
    final peek = PeekController(enabled: true, timer: timers.create);
    final volume = ScreenVolume(bus: bus, peek: peek, timer: timers.create);
    volume.model.handle(volumeReportEvent, {'percent': 0.2});
    expect(peek.expanded, isFalse);
    volume.model.handle(volumeMuteConfirmEvent, {'muted': true});
    expect(peek.expanded, isTrue);
    timers.pending.firstWhere((t) => t.after == volumeShownFor).fire();
    timers.pending.firstWhere((t) => t.after == peekHold).fire();
    expect(peek.expanded, isFalse);
  });
}
