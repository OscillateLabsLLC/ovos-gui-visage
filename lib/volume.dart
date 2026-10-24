/// The output volume as the PHAL volume plugin reports it, and the brief on-screen display of a change. Visage never
/// touches an audio device: it reads the generic `mycroft.volume.*` messages here and asks with them
/// (volume_controls.dart).
///
/// `mycroft.volume.get.response` is the one report of the level. ovos-PHAL-plugin-alsa sends `percent` as a fraction
/// with `muted`, and broadcasts a response after every change. ovos-phal-plugin-mac sends a whole `percent` and no
/// `muted`, answers only when asked, reports a change as `mycroft.volume.set.confirm` or `.mute.confirm`, and sends
/// nothing for a level of 0. So a confirm asks for the level, `muted` is read from either report, and a `percent` above
/// 1 is a whole percent (a Mac at exactly 1 % reads as full).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'faults.dart';
import 'json.dart';
import 'timers.dart';

const volumeReportEvent = 'mycroft.volume.get.response';
const volumeSetConfirmEvent = 'mycroft.volume.set.confirm';
const volumeMuteConfirmEvent = 'mycroft.volume.mute.confirm';

/// Requests from anyone (a voice skill, a hardware button, another GUI, this app): the report that follows shows.
const volumeRequestEvents = [
  'mycroft.volume.set',
  'mycroft.volume.increase',
  'mycroft.volume.decrease',
  'mycroft.volume.mute',
  'mycroft.volume.unmute',
  'mycroft.volume.mute.toggle',
];
const volumeEvents = [volumeReportEvent, volumeSetConfirmEvent, volumeMuteConfirmEvent, ...volumeRequestEvents];

const volumeShownFor = Duration(seconds: 2);

/// How long after a request a report counts as its answer and shows even when the level did not move (up at full).
/// Measured on the Mac plugin: a confirm 0.35 s after the request, a get answered 0.2 to 0.4 s later.
const volumeChangeWindow = Duration(milliseconds: 1500);
const volumeAnswerWithin = Duration(seconds: 3);

class VolumeModel extends ChangeNotifier {
  VolumeModel({required this.ask, OneShot? timer}) : _timer = timer ?? Timer.new;

  /// Sends `mycroft.volume.get`; false when it could not be sent.
  final bool Function() ask;
  final OneShot _timer;
  Timer? _hideTimer;
  Timer? _changeTimer;
  Timer? _answerTimer;

  /// 0 to 1; null until a plugin has reported.
  double? level;
  bool muted = false;
  bool showing = false;

  void handle(String event, Json data) {
    if (volumeRequestEvents.contains(event)) return _expectChange();
    if (event == volumeSetConfirmEvent) {
      _expectChange();
      requestLevel();
    } else if (event == volumeMuteConfirmEvent) {
      _muteConfirmed(data);
    } else if (event == volumeReportEvent) {
      _report(data);
    }
  }

  /// Asks the plugin for the level; a plugin that does not answer is reported.
  void requestLevel() {
    if (!ask()) return reportFault('volume', StateError('could not send mycroft.volume.get: the core bus is not connected'));
    _answerTimer?.cancel();
    _answerTimer = _timer(volumeAnswerWithin, _unanswered);
  }

  void _unanswered() {
    _answerTimer = null;
    reportFault('volume', TimeoutException('no PHAL volume plugin answered mycroft.volume.get', volumeAnswerWithin));
  }

  void _expectChange() {
    _changeTimer?.cancel();
    _changeTimer = _timer(volumeChangeWindow, () => _changeTimer = null);
  }

  void _muteConfirmed(Json data) {
    final reported = data['muted'];
    if (reported is! bool) return reportFault('volume', ArgumentError.value(data, volumeMuteConfirmEvent, 'no boolean muted'));
    muted = reported;
    _show();
  }

  void _report(Json data) {
    _answerTimer?.cancel();
    _answerTimer = null;
    final fraction = volumeFraction(data['percent']);
    if (fraction == null) return reportFault('volume', ArgumentError.value(data, volumeReportEvent, 'no numeric percent'));
    final reportedMuted = data['muted'];
    final known = level != null;
    final moved = fraction != level || (reportedMuted is bool && reportedMuted != muted);
    level = fraction;
    if (reportedMuted is bool) muted = reportedMuted;
    if (_changeTimer != null || (known && moved)) return _show();
    notifyListeners();
  }

  void _show() {
    showing = true;
    _hideTimer?.cancel();
    _hideTimer = _timer(volumeShownFor, _hide);
    notifyListeners();
  }

  void _hide() {
    _hideTimer = null;
    showing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in [_hideTimer, _changeTimer, _answerTimer]) {
      timer?.cancel();
    }
    super.dispose();
  }
}

/// A plugin's `percent` as 0 to 1: a fraction from the ALSA plugin, a whole percent from the Mac plugin.
double? volumeFraction(Object? percent) {
  if (percent is! num) return null;
  final fraction = percent > 1 ? percent / 100 : percent;
  return fraction.clamp(0, 1).toDouble();
}
