import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';

const _s = 'default';
const _skill = 'ovos-skill-hello.openvoiceos';

void main() {
  test('hello is the WIRE.md first frame', () {
    expect(helloFrame(), {
      'type': 'hello',
      'protocol': 'ovos-gui-1',
      'version': 1,
      'session_id': 'default',
      'client': 'visage/$visageVersion',
    });
  });

  test('the client name carries the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: (\S+?)\+', multiLine: true).firstMatch(pubspec)?.group(1), visageVersion);
  });

  test('welcome and error parse', () {
    final w = parseGui1Frame({'type': 'welcome', 'protocol': 'ovos-gui-1', 'version': 1, 'session_id': _s, 'server': 'x/0.1'});
    expect(w, isA<Gui1Welcome>().having((f) => f.server, 'server', 'x/0.1').having((f) => f.version, 'version', 1));
    expect(parseGui1Frame({'type': 'error', 'reason': 'nope'}), isA<Gui1Error>().having((f) => f.reason, 'reason', 'nope'));
  });

  test('every server frame parses to its type with its fields', () {
    final data = {'title': 'Hi'};
    final t = parseGui1Frame({'type': 'template', 'skill_id': _skill, 'template': 'SYSTEM_text', 'data': data, 'session_id': _s});
    expect(
      t,
      isA<Gui1Template>().having((f) => [f.skillId, f.template, f.data, f.sessionId], 'fields', [
        _skill,
        'SYSTEM_text',
        data,
        _s,
      ]),
    );
    final u = parseGui1Frame({'type': 'session_update', 'skill_id': _skill, 'data': data, 'session_id': _s});
    expect(u, isA<Gui1SessionUpdate>().having((f) => f.data, 'data', data));
    expect(parseGui1Frame({'type': 'activated', 'skill_id': _skill, 'session_id': _s}), isA<Gui1Activated>());
    expect(parseGui1Frame({'type': 'deactivated', 'skill_id': _skill, 'session_id': _s}), isA<Gui1Deactivated>());
    expect(parseGui1Frame({'type': 'idle', 'session_id': _s}), isA<Gui1Idle>().having((f) => f.sessionId, 'session', _s));
    final st = parseGui1Frame({'type': 'status', 'event_name': 'speak', 'data': data, 'session_id': _s});
    expect(st, isA<Gui1Status>().having((f) => (f.eventName, f.sessionId), 'fields', ('speak', _s)));
  });

  test('a snapshot keeps the stack order and a null template', () {
    final frame = parseGui1Frame({
      'type': 'snapshot',
      'session_id': _s,
      'stack': [
        {'skill_id': 'a', 'template': 'SYSTEM_text', 'data': <String, dynamic>{}},
        {
          'skill_id': 'b',
          'template': null,
          'data': {'k': 1},
        },
      ],
    });
    final stack = (frame as Gui1Snapshot).stack;
    expect([for (final e in stack) (e.skillId, e.template)], [('a', 'SYSTEM_text'), ('b', null)]);
    expect(stack[1].data, {'k': 1});
  });

  test('a snapshot carries the adapter\'s ambient map (finding F34); one without it keeps none', () {
    final weather = {'current_temp': 21, 'condition': 'Cloudy'};
    final frame = parseGui1Frame({
      'type': 'snapshot',
      'session_id': _s,
      'stack': <Object>[],
      'ambient': {'gui.ambient.weather': weather},
    });
    expect((frame as Gui1Snapshot).ambient, {'gui.ambient.weather': weather});
    final bare = parseGui1Frame({'type': 'snapshot', 'session_id': _s, 'stack': <Object>[]});
    expect((bare as Gui1Snapshot).ambient, isEmpty);
  });

  test('a frame data map is a copy, so a later frame never aliases it', () {
    final data = <String, dynamic>{'a': 1};
    final frame = parseGui1Frame({'type': 'session_update', 'skill_id': _skill, 'data': data, 'session_id': _s});
    data['a'] = 2;
    expect((frame as Gui1SessionUpdate).data, {'a': 1});
  });

  test('an unknown type and a missing or mistyped field throw with the frame', () {
    for (final bad in [
      {'type': 'hologram'},
      {'type': 'template', 'skill_id': _skill, 'data': <String, dynamic>{}, 'session_id': _s},
      {'type': 'activated', 'skill_id': 3, 'session_id': _s},
      {'type': 'snapshot', 'session_id': _s, 'stack': 'nope'},
      {'type': 'status', 'event_name': 'speak', 'data': <String, dynamic>{}},
      {'type': 'idle'},
      {'type': 'snapshot', 'session_id': _s, 'stack': <Object>[], 'ambient': 'nope'},
    ]) {
      expect(
        () => parseGui1Frame(bad),
        throwsA(isA<Gui1FrameException>().having((e) => e.source, 'source', bad)),
        reason: '$bad',
      );
    }
  });

  group('protocol config words', () {
    test('auto, gui1, GUI-1 and legacy in any case', () {
      expect(wireProtocolFrom('auto'), WireProtocol.auto);
      expect(wireProtocolFrom('GUI-1'), WireProtocol.gui1);
      expect(wireProtocolFrom(' gui1 '), WireProtocol.gui1);
      expect(wireProtocolFrom('Legacy'), WireProtocol.legacy);
      expect(wireProtocolFrom(null), isNull);
      expect(() => wireProtocolFrom('qt5'), throwsArgumentError);
    });

    test('the menu line says what the connection speaks, or what is still being tried', () {
      expect(protocolTitle(WireProtocol.auto, ChosenProtocol.gui1), 'Protocol: GUI-1');
      expect(protocolTitle(WireProtocol.auto, ChosenProtocol.legacy), 'Protocol: legacy');
      expect(protocolTitle(WireProtocol.auto, null), 'Protocol: detecting…');
      expect(protocolTitle(WireProtocol.gui1, null), 'Protocol: GUI-1 (connecting)');
      expect(protocolTitle(WireProtocol.legacy, null), 'Protocol: legacy');
    });
  });
}
