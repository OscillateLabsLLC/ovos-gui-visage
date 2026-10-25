/// Attention state machine (port of attention.js): the face appears while OVOS listens, thinks and speaks, and
/// fades out about a second after audio output ends. Pure timing logic; the widget layer renders [shown], [compact]
/// and the controller's mode.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'face/face.dart';
import 'face/face_theme.dart';
import 'pages/template_names.dart';
import 'state/gui_state.dart';
import 'status_topics.dart';

const fadeAfterAudio = Duration(seconds: 1);
const quietAfterHandled = Duration(seconds: 4);
const stuckAfter = Duration(seconds: 20);
const visemeEvent = 'enclosure.mouth.viseme_list';
const faceTemplate = 'SYSTEM_face';
const idlePage = 'idle';

/// A page with content gets the compact badge face; idle, the face template (by any name) and the blank screen get
/// the full face.
bool isContentPage(Target? target, String idleNamespace) {
  if (target == null || target.page.isEmpty) return false;
  if (canonicalTemplate(target.page) == faceTemplate) return false;
  return !(target.namespace == idleNamespace && target.page == idlePage);
}

class Attention extends ChangeNotifier {
  Attention(this.face);

  final FaceController face;
  bool shown = false;
  bool compact = false;
  Timer? _hideTimer;

  FaceMode get mode => face.mode;

  void setCompact(bool value) {
    if (compact == value) return;
    compact = value;
    notifyListeners();
  }

  /// [event] by its gui-1.md 5.3 name or a legacy alias (status_topics.dart); a topic with no role changes nothing. A failure
  /// settles a listening or thinking face as a finished turn does; the outcome pill shows the failure itself
  /// (outcome.dart). Sleep closes the eyes until awoken, whatever the face is doing.
  void handle(String event, Map<String, dynamic> data) {
    switch (statusRole(event)) {
      case StatusRole.listenStart:
        _show(FaceMode.listening);
        face.widen();
      case StatusRole.listenEnd when mode == FaceMode.listening:
        _show(FaceMode.thinking);
      case StatusRole.thinkStart when mode != FaceMode.speaking:
        _show(FaceMode.thinking);
      case StatusRole.thinkEnd when mode == FaceMode.thinking:
        _settle(quietAfterHandled);
      case StatusRole.failed when mode == FaceMode.listening || mode == FaceMode.thinking:
        _settle(quietAfterHandled);
      case StatusRole.speakStart:
        _show(FaceMode.speaking);
      case StatusRole.speakEnd:
        _settle(fadeAfterAudio);
      case StatusRole.visemes when shown:
        face.playVisemes(data['visemes'] as List?);
      case StatusRole.sleep || StatusRole.awoken:
        face.setSleeping(statusRole(event) == StatusRole.sleep);
      case _:
        break;
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
