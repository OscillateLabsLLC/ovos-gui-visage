/// Attention state machine (port of attention.js): the face appears while OVOS listens, thinks and speaks, and
/// fades out about a second after audio output ends. Pure timing logic; the widget layer renders [shown], [compact]
/// and the controller's mode.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'face/face.dart';
import 'face/face_theme.dart';
import 'state/gui_state.dart';

const fadeAfterAudio = Duration(seconds: 1);
const quietAfterHandled = Duration(seconds: 4);
const stuckAfter = Duration(seconds: 20);
const visemeEvent = 'enclosure.mouth.viseme_list';
const facePage = 'SYSTEM_Face';
const idlePage = 'idle';

const _listenStart = ['recognizer_loop:wakeword', 'recognizer_loop:record_begin', 'ovos.listener.record.started'];
const _listenEnd = ['recognizer_loop:record_end', 'ovos.listener.record.ended'];
const _thinkStart = ['recognizer_loop:utterance', 'mycroft.skill.handler.start'];
const _thinkEnd = ['mycroft.skill.handler.complete', 'ovos.utterance.handled', 'complete_intent_failure', 'speak'];

/// A page with content gets the compact badge face; idle, SYSTEM_Face and the blank screen get the full face.
bool isContentPage(Target? target, String idleNamespace) {
  if (target == null || target.page.isEmpty) return false;
  if (target.page == facePage) return false;
  return !(target.namespace == idleNamespace && target.page == idlePage);
}

class Attention extends ChangeNotifier {
  Attention(this.face, {required this.now});

  final FaceController face;

  /// Monotonic clock shared with the face ticker, so viseme anchoring matches its frame times.
  final Duration Function() now;
  bool shown = false;
  bool compact = false;
  Timer? _hideTimer;

  FaceMode get mode => face.mode;

  void setCompact(bool value) {
    if (compact == value) return;
    compact = value;
    notifyListeners();
  }

  void handle(String event, Map<String, dynamic> data) {
    if (_listenStart.contains(event)) {
      _show(FaceMode.listening);
      face.widen();
    } else if (_listenEnd.contains(event) && mode == FaceMode.listening) {
      _show(FaceMode.thinking);
    } else if (_thinkStart.contains(event) && mode != FaceMode.speaking) {
      _show(FaceMode.thinking);
    } else if (_thinkEnd.contains(event) && mode == FaceMode.thinking) {
      _settle(quietAfterHandled);
    } else if (event == 'recognizer_loop:audio_output_start') {
      _show(FaceMode.speaking);
    } else if (event == 'recognizer_loop:audio_output_end') {
      _settle(fadeAfterAudio);
    } else if (event == visemeEvent && shown) {
      face.playVisemes(data['visemes'] as List?, now());
    }
  }

  void _show(FaceMode next) {
    face.setMode(next);
    shown = true;
    _cancelHide();
    if (next == FaceMode.listening || next == FaceMode.thinking) _hideAfter(stuckAfter);
    notifyListeners();
  }

  void _settle(Duration after) {
    face.setMode(FaceMode.rest);
    _cancelHide();
    _hideAfter(after);
    notifyListeners();
  }

  void hide() {
    shown = false;
    face.setMode(FaceMode.rest);
    notifyListeners();
  }

  void _hideAfter(Duration after) => _hideTimer = Timer(after, hide);

  void _cancelHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  @override
  void dispose() {
    _cancelHide();
    super.dispose();
  }
}
