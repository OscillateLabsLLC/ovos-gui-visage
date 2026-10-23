/// Outcome of a voice turn, shown briefly when the turn ends: success, failure or cancelled, as ovos-shell's
/// StatusIndicator and the htmx client do. Pure state on core bus events; widgets/outcome_pill.dart renders it.
///
/// ovos-core ends every utterance with exactly one `ovos.utterance.handled`, after the turn's own signals, so the
/// verdict is collected during the turn and shown on that end marker: a failure or a cancel earlier in the turn wins
/// over a later handler completion.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'json.dart';
import 'timers.dart';

enum Outcome { success, cancelled, failure }

const outcomeShownFor = Duration(milliseconds: 1500);

const turnStartEvent = 'recognizer_loop:utterance';
const handlerCompleteEvent = 'mycroft.skill.handler.complete';
const cancelledEvent = 'ovos.utterance.cancelled';
const turnEndEvent = 'ovos.utterance.handled';

/// `complete_intent_failure` and its spec name `ovos.intent.unmatched` (both reach the bus through ovos-bus-client's
/// compatibility twin), and the skill framework's handler error signal, which carries `exception`.
const failureEvents = ['complete_intent_failure', 'ovos.intent.unmatched', 'mycroft.skill.handler.error'];
const outcomeEvents = [turnStartEvent, handlerCompleteEvent, cancelledEvent, turnEndEvent, ...failureEvents];

class OutcomeModel extends ChangeNotifier {
  OutcomeModel({OneShot? timer}) : _timer = timer ?? Timer.new;

  final OneShot _timer;
  Outcome? _verdict;
  Timer? _hideTimer;

  /// The outcome on screen, or null.
  Outcome? showing;

  void handle(String event, Json data) {
    if (event == turnStartEvent) {
      _verdict = null;
    } else if (event == handlerCompleteEvent) {
      _note(data['exception'] == null ? Outcome.success : Outcome.failure);
    } else if (failureEvents.contains(event)) {
      _note(Outcome.failure);
    } else if (event == cancelledEvent) {
      _note(Outcome.cancelled);
    } else if (event == turnEndEvent) {
      _show(_verdict ?? Outcome.success);
    }
  }

  /// Within a turn the stronger signal wins: failure over cancelled over success.
  void _note(Outcome outcome) {
    final current = _verdict;
    if (current == null || outcome.index > current.index) _verdict = outcome;
  }

  void _show(Outcome outcome) {
    _verdict = null;
    showing = outcome;
    _hideTimer?.cancel();
    _hideTimer = _timer(outcomeShownFor, _hide);
    notifyListeners();
  }

  void _hide() {
    _hideTimer = null;
    showing = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }
}
