import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/volume.dart';

import 'corebus_fixture.dart';
import 'faults.dart';
import 'manual_timers.dart';

void main() {
  late ManualTimers timers;
  late VolumeModel model;
  late int asks;
  late List<bool> shows;

  setUp(() {
    timers = ManualTimers();
    asks = 0;
    model = VolumeModel(ask: () => ++asks > 0, timer: timers.create);
    shows = [];
    model.addListener(() => shows.add(model.showing));
  });

  void replay(String fixture) {
    for (final (type, data) in coreBusFixture(fixture)) {
      model.handle(type, data);
    }
  }

  List<ManualTimer> pendingFor(Duration after) => [
    for (final t in timers.pending)
      if (t.after == after) t,
  ];

  test('percent: a fraction from ALSA, a whole percent from the Mac, clamped; anything else is no level', () {
    expect(
      [
        for (final p in [0.38, 38, 0, 0.0, 1.0, 100, 150, -3]) volumeFraction(p),
      ],
      [0.38, 0.38, 0, 0, 1, 1, 1, 0],
    );
    expect(volumeFraction('38'), isNull);
    expect(volumeFraction(null), isNull);
  });

  test('the first report is a quiet sync: the level is known, nothing shows', () {
    model.handle(volumeReportEvent, {'percent': 38});
    expect(model.level, 0.38);
    expect(model.showing, isFalse);
  });

  test('a poll that finds the same level shows nothing; a level that moved shows', () {
    model.handle(volumeReportEvent, {'percent': 0.38, 'muted': false});
    model.handle(volumeReportEvent, {'percent': 0.38, 'muted': false});
    expect(model.showing, isFalse);
    model.handle(volumeReportEvent, {'percent': 0.38, 'muted': true});
    expect(model.showing, isTrue);
  });

  test('the recorded Mac session: each confirm asks for the level, the mute confirms set muted', () {
    replay('volume_mac_plugin');
    expect(asks, 2, reason: 'one get after each set.confirm (increase, decrease)');
    expect(model.level, 0.38);
    expect(model.muted, isFalse);
    expect(model.showing, isTrue);
  });

  test('the Mac increase shows once its level arrives, then hides after its time', () {
    model.handle(volumeReportEvent, {'percent': 38});
    for (final (type, data) in coreBusFixture('volume_mac_plugin').skip(2).take(2)) {
      model.handle(type, data);
    }
    expect(asks, 1);
    expect(model.showing, isFalse, reason: 'the Mac confirm echoes the request, so the level waits for the get');
    model.handle(volumeReportEvent, {'percent': 48});
    expect([model.level, model.showing], [0.48, true]);
    pendingFor(volumeShownFor).single.fire();
    expect(model.showing, isFalse);
  });

  test('a mute confirm shows at once, with the level already known', () {
    model.handle(volumeReportEvent, {'percent': 38});
    model.handle(volumeMuteConfirmEvent, {'muted': true});
    expect([model.level, model.muted, model.showing], [0.38, true, true]);
  });

  test('the ALSA session written from source: every change broadcasts a report, and it shows without asking', () {
    replay('volume_alsa_from_source');
    expect(asks, 0);
    expect([model.level, model.muted, model.showing], [0.5, false, true]);
    expect(shows.where((s) => s), isNotEmpty);
  });

  test('up at full still shows: a report soon after a request counts even when the level did not move', () {
    model.handle(volumeReportEvent, {'percent': 1.0, 'muted': false});
    model.handle('mycroft.volume.increase', {});
    model.handle(volumeReportEvent, {'percent': 1.0, 'muted': false});
    expect(model.showing, isTrue);
  });

  test('a report long after the request is a poll again', () {
    model.handle(volumeReportEvent, {'percent': 0.5});
    model.handle('mycroft.volume.increase', {});
    pendingFor(volumeChangeWindow).single.fire();
    model.handle(volumeReportEvent, {'percent': 0.5});
    expect(model.showing, isFalse);
  });

  test('a second change while shown restarts the timer rather than stacking', () {
    model.handle(volumeReportEvent, {'percent': 0.3});
    model.handle(volumeReportEvent, {'percent': 0.4});
    model.handle(volumeReportEvent, {'percent': 0.5});
    expect(pendingFor(volumeShownFor), hasLength(1));
  });

  test('the voice set on the Mac: the confirm echoes 0.5, the get finds 0 and is never answered, which is reported', () async {
    model.handle(volumeReportEvent, {'percent': 38});
    final faults = await collectFaults(() async {
      replay('volume_mac_voice_set');
      replay('volume_mac_get_at_zero');
      pendingFor(volumeAnswerWithin).single.fire();
    });
    expect(faults.single.exception, isA<TimeoutException>());
    expect(model.level, 0.38, reason: 'the echoed 0.5 is not taken as the level');
  });

  test('an answered get cancels the no-answer report', () async {
    final faults = await collectFaults(() async {
      model.requestLevel();
      model.handle(volumeReportEvent, {'percent': 38});
      timers.fireAll();
    });
    expect(faults, isEmpty);
  });

  test('a closed bus, a report without a number and a mute confirm without a boolean are reported', () async {
    final closed = VolumeModel(ask: () => false, timer: timers.create);
    final faults = await collectFaults(() async {
      closed.requestLevel();
      model.handle(volumeReportEvent, {'percent': 'loud'});
      model.handle(volumeMuteConfirmEvent, {});
    });
    expect(faults, hasLength(3));
    expect('${faults.first.exception}', contains('not connected'));
    expect(model.level, isNull);
    expect(model.showing, isFalse);
  });
}
