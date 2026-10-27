/// The adapter's recordings with `index` and `page_count` on the wire (WIRE.md; finding F45): a legacy skill page
/// through its skill route, and a two-entry namespace the pager ([stepPage], [touchPage]) walks.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/page_moves.dart';
import 'package:ovos_gui_visage/pages/time_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const _dateTime = 'ovos-skill-date-time.openvoiceos';
const _probe = 'gui1-focus-probe.oscillatelabs';

/// The focus requests a step or a touch made, and any GUI message a touch sent instead.
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
  test('the recorded directory holds the adapter recordings at 67fbaca, each parsing', () {
    final files = Directory('test/fixtures/gui1/recorded').listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'));
    expect(files, hasLength(8));
    for (final file in files) {
      expect(loadRecorded(file.uri.pathSegments.last.replaceAll('.jsonl', '')), isNotEmpty, reason: file.path);
    }
  });

  group('legacy_time_page', () {
    testWidgets('the time template routes to TimePage through the skill route, at entry 0 of 1, with no fault', (tester) async {
      final gaps = freshGaps();
      late GuiState state;
      final faults = await collectFaults(() async {
        state = replayGui1(loadRecorded('legacy_time_page'), gaps: gaps);
        await tester.pumpWidget(host(pageOf(state, gaps: gaps.templates)));
      });
      expect(state.current(), const Target(_dateTime, 'time', 0));
      expect(state.namespace(_dateTime).position, (index: 0, count: 1));
      expect([find.byType(TimePage), find.text('3:29'), find.text('PM')], everyElement(findsOneWidget));
      expect(faults, isEmpty);
    });

    test('its snapshot gives the same state and entry as the stream', () {
      final streamed = replayGui1(loadRecorded('legacy_time_page'));
      final joined = replayGui1(loadRecorded('legacy_time_page_snapshot'));
      expect(joined.snapshot(), equals(streamed.snapshot()));
      expect(joined.namespace(_dateTime).position, streamed.namespace(_dateTime).position);
    });
  });

  group('focus_two_entries', () {
    test('after the first template the pager stands at 0 of 2, after the redispatched one at 1 of 2', () {
      final frames = loadRecorded('focus_two_entries');
      expect(frames, hasLength(4));
      final state = replayGui1(frames.take(3).toList());
      expect((state.current()!.page, state.namespace(_probe).position), ('SYSTEM_text', (index: 0, count: 2)));
      replayGui1(frames.skip(3).toList(), state: state);
      expect((state.current()!.page, state.namespace(_probe).position), ('SYSTEM_image', (index: 1, count: 2)));
    });

    test('at 1 of 2 a step on sends nothing past the end, a step back asks for 0, a touch focuses 1', () {
      final state = replayGui1(loadRecorded('focus_two_entries'));
      final sent = _Sent();
      expect(stepPage(state, 1, sent.request), isFalse);
      expect(sent.focus, isEmpty, reason: 'no frame past the end');
      expect(stepPage(state, -1, sent.request), isFalse);
      touchPage(state, sent.request, sent.send);
      expect(sent.focus, [(_probe, 0), (_probe, 1)]);
      expect(sent.gui, isEmpty, reason: 'a known entry touches with focus, not the legacy use report');
    });

    test('its snapshot gives the same state and entry as the stream', () {
      final streamed = replayGui1(loadRecorded('focus_two_entries'));
      final joined = replayGui1(loadRecorded('focus_two_entries_snapshot'));
      expect(joined.snapshot(), equals(streamed.snapshot()));
      expect(joined.namespace(_probe).position, (index: 1, count: 2));
    });
  });
}
