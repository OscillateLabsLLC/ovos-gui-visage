import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/captions.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/shell_overlays.dart';
import 'package:ovos_gui_visage/turn_feed.dart';
import 'package:ovos_gui_visage/widgets/caption_strip.dart';

import 'corebus_fixture.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

Widget frame(Captions captions, {bool compact = false}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: ListenableBuilder(
        listenable: captions,
        builder: (_, _) => Stack(
          children: [CaptionStrip(captions: captions, compact: compact)],
        ),
      ),
    ),
  ),
);

double opacity(WidgetTester tester) => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  late Captions captions;

  setUp(() => captions = Captions(timer: ManualTimers().create));

  testWidgets('the recorded turn draws both lines, then fades', (tester) async {
    final turn = coreBusFixture('turn_what_time_is_it');
    await tester.pumpWidget(frame(captions));
    expect(opacity(tester), 0);
    replayUntil(turn, speakEvent, captions.handle);
    await tester.pump();
    expect(find.text('what time is it'), findsOneWidget);
    expect(find.text('It is four thirty six p.m.'), findsOneWidget);
    expect(opacity(tester), 1);
    replayUntil(turn, audioEndEvent, captions.handle);
    await tester.pump();
    expect(opacity(tester), 0);
  });

  testWidgets('on a content page the strip ends above the face badge', (tester) async {
    await tester.pumpWidget(frame(captions, compact: true));
    captions.handle(speakEvent, {'utterance': 'Two timers are running.'});
    await tester.pump();
    final reply = tester.getRect(find.byKey(const Key('caption-reply')));
    final frameTop = tester.getTopLeft(find.byType(Stack)).dy;
    expect(reply.bottom, lessThanOrEqualTo(frameTop + frameHeight - attentionStrip));
  });

  testWidgets('a long reply wraps and shrinks to fit, with every word kept', (tester) async {
    final long = List.filled(60, 'the forecast for the week ahead').join(' ');
    await tester.pumpWidget(frame(captions));
    captions.handle(speakEvent, {'utterance': long});
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('caption-reply'))).data, long);
    expect(tester.getRect(find.byType(FittedBox)).height, lessThanOrEqualTo(captionMaxHeight));
    expect(tester.takeException(), isNull);
  });

  test('the feed hands each core bus message to every sink that asked for it', () {
    final bus = RecordingBus();
    final seen = <String>[];
    bindTurnFeed(bus, {
      captions.handle: captionEvents,
      (event, _) => seen.add(event): const [handledEvent],
    });
    bus.send(speakEvent, {'utterance': 'hello'});
    bus.send(handledEvent);
    expect(captions.reply, 'hello');
    expect(seen, [handledEvent]);
  });
}
