/// `index` and `page_count` on GUI-1 `template` frames and snapshot entries (WIRE.md; finding F45), and what a step and a
/// touch send with and without them; legacy keeps its local paging.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/page_moves.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/gui_events.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'gui1_fixture.dart';

const _skill = 'ovos-skill-gui1-demo.oscillatelabs';

Json _frame([Json extra = const {}]) => {
  'type': 'template',
  'skill_id': _skill,
  'template': 'SYSTEM_text',
  'data': <String, dynamic>{'text': 'x'},
  'session_id': defaultSessionId,
  ...extra,
};

GuiState _showing(Gui1Entry? entry) => replayGui1([
  Gui1Template(skillId: _skill, template: 'SYSTEM_text', data: const {'text': 'x'}, sessionId: 'default', entry: entry),
]);

/// The focus requests and GUI messages a call made.
class _Sent {
  final focus = <(String, int)>[];
  final gui = <Json>[];

  bool request(String namespace, int page) {
    focus.add((namespace, page));
    return true;
  }

  bool send(Json message) {
    gui.add(message);
    return true;
  }
}

void main() {
  group('frames', () {
    test('a template carries index and page_count together, or neither', () {
      final frame = parseGui1Frame(_frame({'index': 1, 'page_count': 3})) as Gui1Template;
      expect(frame.entry, (index: 1, count: 3));
      expect((parseGui1Frame(_frame()) as Gui1Template).entry, isNull);
      for (final bad in [
        {'index': 1},
        {'page_count': 2},
        {'index': 2, 'page_count': 2},
        {'index': -1, 'page_count': 2},
      ]) {
        expect(() => parseGui1Frame(_frame(bad)), throwsA(isA<Gui1FrameException>()), reason: '$bad');
      }
    });

    test('a snapshot entry carries them too, and the state keeps them per namespace', () {
      final snapshot = parseGui1Frame({
        'type': 'snapshot',
        'session_id': defaultSessionId,
        'stack': [
          {'skill_id': _skill, 'template': 'SYSTEM_text', 'data': <String, dynamic>{}, 'index': 0, 'page_count': 2},
        ],
      });
      final state = replayGui1([snapshot]);
      expect(state.namespace(_skill).position, (index: 0, count: 2));
    });
  });

  group('GUI-1 with a known entry', () {
    test('the pager stands at the entry, a step asks for the next one and changes nothing here', () {
      final state = _showing((index: 1, count: 3));
      expect(state.namespace(_skill).position, (index: 1, count: 3));
      final sent = _Sent();
      expect(stepPage(state, 1, sent.request), isFalse);
      expect(stepPage(state, -1, sent.request), isFalse);
      expect(sent.focus, [(_skill, 2), (_skill, 0)]);
      expect(state.current(), const Target(_skill, 'SYSTEM_text', 0), reason: 'the next template frame moves it');
    });

    test('no step past either end', () {
      final sent = _Sent();
      expect(stepPage(_showing((index: 2, count: 3)), 1, sent.request), isFalse);
      expect(stepPage(_showing((index: 0, count: 3)), -1, sent.request), isFalse);
      expect(sent.focus, isEmpty);
    });

    test('a touch is a focus on the current entry, with no GUI message', () {
      final sent = _Sent();
      touchPage(_showing((index: 1, count: 3)), sent.request, sent.send);
      expect(
        [sent.focus, sent.gui],
        [
          [(_skill, 1)],
          isEmpty,
        ],
      );
    });

    test('the redispatched template with its new index moves the pager', () {
      final state = _showing((index: 0, count: 2));
      replayGui1([
        Gui1Template(skillId: _skill, template: 'SYSTEM_list', data: const {}, sessionId: 'default', entry: (index: 1, count: 2)),
      ], state: state);
      expect(state.namespace(_skill).position, (index: 1, count: 2));
      expect(state.current()!.page, 'SYSTEM_list');
    });
  });

  group('without a known entry', () {
    test('GUI-1: one page, so no step; a touch goes to GuiLink, which refuses and reports it', () {
      final state = _showing(null);
      final sent = _Sent();
      expect(stepPage(state, 1, sent.request), isFalse);
      touchPage(state, sent.request, sent.send);
      expect(
        [sent.focus, sent.gui],
        [
          isEmpty,
          [interactionMessage(_skill)],
        ],
      );
    });

    test('legacy: a step changes the page here and requests nothing', () {
      final state = GuiState()
        ..namespace(_skill).pages = ['a', 'b']
        ..active.add(_skill);
      final sent = _Sent();
      expect(stepPage(state, 1, sent.request), isTrue);
      expect(state.current(), const Target(_skill, 'b', 1));
      expect(sent.focus, isEmpty);
    });
  });
}
