import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/captions.dart';

import 'corebus_fixture.dart';
import 'faults.dart';
import 'manual_timers.dart';

void main() {
  late ManualTimers timers;
  late Captions captions;

  setUp(() {
    timers = ManualTimers();
    captions = Captions(timer: timers.create);
  });

  final turn = coreBusFixture('turn_what_time_is_it');

  test('the recorded turn shows the heard line, then the reply under it', () {
    replayUntil(turn, heardEvent, captions.handle);
    expect((captions.visible, captions.heard, captions.reply), (true, 'what time is it', ''));
    replayUntil(turn, speakEvent, captions.handle);
    expect(captions.reply, 'It is four thirty six p.m.');
    expect(captions.heard, 'what time is it');
  });

  test('the reply stays through handled and audio start, and fades when audio output ends', () {
    replayUntil(turn, 'recognizer_loop:audio_output_start', captions.handle);
    expect(captions.visible, isTrue);
    for (final (type, data) in turn) {
      captions.handle(type, data);
    }
    expect(captions.visible, isFalse);
    expect(captions.reply, 'It is four thirty six p.m.', reason: 'the text stays set while the strip fades');
    expect(timers.pending, isEmpty);
  });

  test('a new utterance replaces the reply at once', () {
    replayUntil(turn, speakEvent, captions.handle);
    captions.handle(heardEvent, {
      'utterances': ['and the date'],
    });
    expect((captions.heard, captions.reply), ('and the date', ''));
  });

  test('replies spoken back to back queue, one per audio output end', () {
    captions.handle(speakEvent, {'utterance': 'first'});
    captions.handle(speakEvent, {'utterance': 'second'});
    expect(captions.reply, 'first');
    captions.handle(audioEndEvent, {});
    expect((captions.visible, captions.reply), (true, 'second'));
    captions.handle(audioEndEvent, {});
    expect(captions.visible, isFalse);
  });

  test('a turn that ends without speech holds the heard line, then clears', () {
    replayUntil(coreBusFixture('turn_cancelled'), handledEvent, captions.handle);
    expect(captions.visible, isTrue);
    expect(timers.pending.single.after, heardHoldWithoutReply);
    timers.fireAll();
    expect(captions.visible, isFalse);
  });

  test('a caption whose audio never ends clears after the maximum age', () {
    captions.handle(speakEvent, {'utterance': 'stuck'});
    expect(timers.pending.single.after, captionMaxAge);
    timers.fireAll();
    expect(captions.visible, isFalse);
  });

  test('audio output end with nothing queued changes nothing', () {
    var changes = 0;
    captions.addListener(() => changes++);
    captions.handle(audioEndEvent, {});
    expect(changes, 0);
  });

  test('malformed messages are reported and show nothing', () async {
    final faults = await collectFaults(() async {
      captions.handle(heardEvent, {'utterances': []});
      captions.handle(speakEvent, {'utterance': 42});
    });
    expect(faults, hasLength(2));
    expect(captions.visible, isFalse);
  });
}
