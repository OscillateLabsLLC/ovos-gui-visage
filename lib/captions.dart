/// Captions: the heard utterance and the spoken reply as on-screen text, as ovos-shell's transcript and the htmx
/// client's caption show them. Pure state on core bus events; the strip in widgets/caption_strip.dart renders it.
/// A reply stays until its audio output ends or a new utterance arrives; replies spoken back to back queue, one per
/// `recognizer_loop:audio_output_end`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'faults.dart';
import 'json.dart';
import 'timers.dart';

const heardEvent = 'recognizer_loop:utterance';
const speakEvent = 'speak';
const audioEndEvent = 'recognizer_loop:audio_output_end';
const handledEvent = 'ovos.utterance.handled';
const captionEvents = [heardEvent, speakEvent, audioEndEvent, handledEvent];

/// A turn that ends without speech keeps the heard line up this long.
const heardHoldWithoutReply = Duration(seconds: 4);

/// Nothing stays on screen longer than this without a new event, in case audio output never reports its end.
const captionMaxAge = Duration(seconds: 60);

class Captions extends ChangeNotifier {
  Captions({OneShot? timer}) : _timer = timer ?? Timer.new;

  final OneShot _timer;
  final List<String> _replies = [];
  Timer? _clearTimer;

  /// The last text shown; it stays set while the strip fades out, so the fade shows the words leaving.
  String heard = '';
  String reply = '';
  bool visible = false;

  void handle(String event, Json data) {
    switch (event) {
      case heardEvent:
        _onHeard(data);
      case speakEvent:
        _onSpeak(data);
      case audioEndEvent:
        _onAudioEnd();
      case handledEvent:
        if (_replies.isEmpty && visible) _clearAfter(heardHoldWithoutReply);
    }
  }

  void _onHeard(Json data) {
    final utterances = data['utterances'];
    final first = utterances is List && utterances.isNotEmpty ? utterances.first : null;
    if (first is! String) {
      reportFault('captions: $heardEvent without utterances', ArgumentError.value(data, 'data'));
      return;
    }
    _replies.clear();
    _show(heard: first, reply: '');
  }

  void _onSpeak(Json data) {
    final text = data['utterance'];
    if (text is! String) {
      reportFault('captions: $speakEvent without an utterance', ArgumentError.value(data, 'data'));
      return;
    }
    _replies.add(text);
    if (_replies.length == 1) _show(heard: heard, reply: text);
  }

  void _onAudioEnd() {
    if (_replies.isEmpty) return;
    _replies.removeAt(0);
    if (_replies.isEmpty) return clear();
    _show(heard: heard, reply: _replies.first);
  }

  void _show({required String heard, required String reply}) {
    this.heard = heard;
    this.reply = reply;
    visible = true;
    _clearAfter(captionMaxAge);
    notifyListeners();
  }

  void clear() {
    _cancel();
    _replies.clear();
    if (!visible) return;
    visible = false;
    notifyListeners();
  }

  void _clearAfter(Duration after) {
    _cancel();
    _clearTimer = _timer(after, clear);
  }

  void _cancel() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
