import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/protocol/core_bus.dart';
import 'package:ovos_gui_visage/protocol/utterance.dart';

import 'faults.dart';
import 'recording_bus.dart';

class _ClosedBus extends CoreBus {
  @override
  bool emit(String type, [Json? data]) => false;
}

void main() {
  test('a typed command goes out as ovos-say-to sends it', () {
    final bus = RecordingBus();
    expect(sendUtterance(bus, '  what time is it ', lang: 'en-US'), isTrue);
    expect(bus.emitted.single, [
      'recognizer_loop:utterance',
      {
        'utterances': ['what time is it'],
        'lang': 'en-US',
      },
    ]);
  });

  test('the recorded command is what the app sends, and OVOS answered it in that language', () {
    final lines = [for (final l in File('test/fixtures/outgoing/typed_command.jsonl').readAsLinesSync()) jsonDecode(l) as Json];
    final sent = lines.first;
    expect(sent['type'], utteranceMessage);
    expect(sent['context_source'], 'ovos-gui-visage');
    expect(utteranceData('what time is it', lang: 'en-US'), sent['data']);
    expect(lines.last['type'], 'speak');
    expect(lines.last['data']['lang'], 'en-US');
  });

  test('without a configured language, lang is left to OVOS', () {
    expect(utteranceData('hello'), {
      'utterances': ['hello'],
    });
    expect(utteranceData('hello', lang: ''), {
      'utterances': ['hello'],
    });
  });

  test('blank text is not sent', () {
    final bus = RecordingBus();
    expect(sendUtterance(bus, '   '), isFalse);
    expect(bus.emitted, isEmpty);
  });

  test('a closed bus is reported with the text', () async {
    late bool sent;
    final faults = await collectFaults(() async => sent = sendUtterance(_ClosedBus(), 'hello'));
    expect(sent, isFalse);
    expect('${faults.single.exception}', contains('"hello" was not sent'));
  });

  test('the language comes from VISAGE_LANG over the file', () {
    expect(AppConfig.from({'lang': 'en-GB'}, {}).lang, 'en-GB');
    expect(AppConfig.from({'lang': 'en-GB'}, {'VISAGE_LANG': 'de-DE'}).lang, 'de-DE');
    expect(AppConfig.from({'lang': ' '}, {}).lang, isNull);
    expect(AppConfig.from(null, {}).lang, isNull);
  });
}
