import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/media_keys.dart';
import 'package:ovos_gui_visage/pages/now_playing_status.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/circle.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

/// The page area of the 480 x 800 frame with the attention strip showing (`ScreenFrame._page`), the tightest it gets.
const pageArea = Size(432, 650);

/// The corner widget: the same frame, scaled down by the shell's FittedBox.
const cornerWidget = Size(240, 400);

Json fixtureData(String name) => loadGui1Fixture(name).whereType<Gui1Template>().first.data;

Widget pageFor(String skill, String template, Json data) {
  final state = GuiState();
  applyGui1Frame(state, Gui1Template(skillId: skill, template: template, data: data, sessionId: defaultSessionId));
  final target = state.current()!;
  final ctx = PageContext(namespace: target.namespace, page: target.page, events: const {}, send: (_) => true);
  return resolve(target, gaps: TemplateGaps())(state.namespace(target.namespace).data, ctx);
}

Widget framed(Widget page, {bool still = false, Size surface = pageArea}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Material(
      child: Center(
        child: SizedBox.fromSize(
          size: surface,
          child: FittedBox(
            child: SizedBox.fromSize(size: pageArea, child: page),
          ),
        ),
      ),
    ),
  ),
);

Widget audio() => pageFor(hello, 'SYSTEM_audio_player', fixtureData('system_audio_player'));

Widget media([Json extra = const {}]) =>
    pageFor('ovos.common_play', 'SYSTEM_media_player', {...fixtureData('system_media_player'), ...extra});

Widget video() => pageFor(hello, 'SYSTEM_video_player', fixtureData('system_video_player'));

/// Whether anything on screen is turned: a rotation has a sine term where a translation or scale has 0.
bool anythingRotated(WidgetTester tester) =>
    tester.widgetList<Transform>(find.byType(Transform)).any((t) => t.transform.storage[1].abs() > 1e-6);

/// The busy view's turning arc.
bool busyMoving(WidgetTester tester) => anythingRotated(tester);

/// The busy view draws at once: its ring is there on the first frame.
Future<void> untilBusyArrives(WidgetTester tester) async {
  await tester.pump();
  expect(find.byType(Ring), findsWidgets, reason: 'the busy view\'s ring');
}

List<double> barHeights(WidgetTester tester) => [
  for (final bar in find.descendant(of: find.byType(Equaliser), matching: find.byType(Container)).evaluate()) bar.size!.height,
];

double liveDotOpacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(find.descendant(of: find.byType(LiveDot), matching: find.byType(FadeTransition))).opacity.value;

void main() {
  setUp(forgetMediaFaults);

  for (final (name, page) in [('audio', audio), ('media', media)]) {
    testWidgets('$name player: the cover turns and the bars move, unless reduced motion holds them still', (tester) async {
      await tester.pumpWidget(framed(page()));
      final moving = barHeights(tester);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(anythingRotated(tester), isTrue);
      expect(barHeights(tester), isNot(moving));

      await tester.pumpWidget(framed(page(), still: true));
      final held = barHeights(tester);
      await tester.pump(const Duration(milliseconds: 1300));
      expect(anythingRotated(tester), isFalse);
      expect(barHeights(tester), held);
    });
  }

  testWidgets('a live stream: the dot pulses, and is steady under reduced motion', (tester) async {
    await tester.pumpWidget(framed(media({'media_duration': -1})));
    await tester.pump(const Duration(milliseconds: 400));
    expect(liveDotOpacity(tester), lessThan(1));
    await tester.pumpWidget(framed(media({'media_duration': -1}), still: true));
    await tester.pump(const Duration(milliseconds: 400));
    expect(liveDotOpacity(tester), 1);
  });

  testWidgets('media player loading: the busy animation runs, and holds its first frame under reduced motion', (tester) async {
    final loading = {'media_playback_state': 'loading'};
    final faults = await collectFaults(() async {
      for (final still in [false, true]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(framed(media(loading), still: still));
        await untilBusyArrives(tester);
        await tester.pump(const Duration(milliseconds: 500));
        expect(busyMoving(tester), !still, reason: 'still: $still');
      }
    });
    expect(faults.map((f) => '${f.context}'), everyElement(contains('installing.json')));
  });

  testWidgets('under reduced motion the progress ring still follows the position while the cover holds', (tester) async {
    final data = fixtureData('system_audio_player');
    await tester.pumpWidget(framed(pageFor(hello, 'SYSTEM_audio_player', data), still: true));
    expect(tester.widget<Ring>(find.byType(Ring)).fraction, closeTo(0.3, 0.01));
    await tester.pumpWidget(framed(pageFor(hello, 'SYSTEM_audio_player', {...data, 'position': 150000}), still: true));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Ring>(find.byType(Ring)).fraction, closeTo(0.5, 0.01));
    expect(anythingRotated(tester), isFalse);
  });

  testWidgets('media player error: the failure view holds a still frame under reduced motion', (tester) async {
    final faults = await collectFaults(() async {
      await tester.pumpWidget(framed(media({'media_playback_state': 'error'}), still: true));
      await untilBusyArrives(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Could not play Blue in Green'), findsOneWidget);
      expect(busyMoving(tester), isFalse);
    });
    expect(faults.map((f) => '${f.context}'), everyElement(contains('status-fail.json')));
  });

  testWidgets('every control is at least 48 x 48 in the 480 x 800 frame', (tester) async {
    for (final page in [audio(), media()]) {
      await tester.pumpWidget(framed(page));
      final controls = [...find.byType(IconButton).evaluate(), ...find.byType(TextButton).evaluate()];
      expect(controls, isNotEmpty);
      for (final control in controls) {
        expect(control.size!.width, greaterThanOrEqualTo(48), reason: '${control.widget}');
        expect(control.size!.height, greaterThanOrEqualTo(48), reason: '${control.widget}');
      }
    }
  });

  testWidgets('video still: a defined frame under reduced motion', (tester) async {
    await tester.pumpWidget(framed(video(), still: true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(anythingRotated(tester), isFalse);
  });

  for (final surface in [pageArea, cornerWidget]) {
    testWidgets('every media page fits ${surface.width.toInt()} x ${surface.height.toInt()} without overflow', (tester) async {
      for (final (page, title) in [(audio(), 'Morning Briefing'), (video(), 'Big Buck Bunny'), (media(), 'Blue in Green')]) {
        await tester.pumpWidget(framed(page, surface: surface));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull, reason: title);
      }
      await tester.pumpWidget(framed(media(), surface: surface));
      await tester.tap(find.text('QUEUE'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('So What'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'queue');
    });
  }
}
