/// The now-playing page's transport: previous, play or pause, stop, next, and a seek bar. The buttons send what
/// ovos-common-play's OVOSSyncPlayer.qml sends with triggerGuiEvent in OCP's namespace (`previous`, `resume`, `pause`,
/// `stop`, `next`). That page has no seek bar for audio; the one it replaced (AudioPlayer.qml, removed from
/// ovos-ocp-audio-plugin in c2a80f1) sent `seek` with `seekValue` in milliseconds, which the player's seek handler
/// (ocp/player.py `handle_seek_request`) still reads. Pure mapping first, then the widgets.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'ocp_model.dart';

const ocpPrevious = 'previous';
const ocpNext = 'next';
const ocpPause = 'pause';
const ocpResume = 'resume';
const ocpStop = 'stop';
const ocpSeek = 'seek';

/// Pause while playing, else resume; a stopped player has nothing to resume, so the button is off then.
String? playPauseEvent(PlaybackState state) => switch (state) {
  PlaybackState.playing => ocpPause,
  PlaybackState.paused => ocpResume,
  PlaybackState.stopped => null,
};

/// A track with a known length that is not a live stream can be sought.
bool canSeek(Track track) => !track.live && track.durationMs > 0;

/// The seek handler treats a `seekValue` of 0 as absent and seeks relative to the current position, so the start of
/// the track is sent as 1 ms.
Json seekParameters(double fraction, double durationMs) => {
  'seekValue': math.max(1, (fraction.clamp(0.0, 1.0) * durationMs).round()),
};

typedef OcpSend = void Function(String event, [Json parameters]);

class OcpTransport extends StatelessWidget {
  const OcpTransport({super.key, required this.track, required this.send});

  final Track track;
  final OcpSend send;

  @override
  Widget build(BuildContext context) {
    final toggle = playPauseEvent(track.state);
    final playing = track.state == PlaybackState.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 18,
      children: [
        _button(Icons.skip_previous_rounded, 'Previous', track.canPrev ? ocpPrevious : null),
        _button(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, playing ? 'Pause' : 'Play', toggle, large: true),
        _button(Icons.stop_rounded, 'Stop', track.state == PlaybackState.stopped ? null : ocpStop),
        _button(Icons.skip_next_rounded, 'Next', track.canNext ? ocpNext : null),
      ],
    );
  }

  Widget _button(IconData icon, String tooltip, String? event, {bool large = false}) => IconButton(
    tooltip: tooltip,
    iconSize: large ? 48 : 34,
    color: VisageColors.fg,
    disabledColor: VisageColors.muted.withValues(alpha: 0.4),
    style: large ? IconButton.styleFrom(backgroundColor: VisageColors.accentSoft) : null,
    onPressed: event == null ? null : () => send(event),
    icon: Icon(icon),
  );
}

/// A thin bar under the disc. Dragging shows where it will land; letting go sends the seek once.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key, required this.fraction, required this.durationMs, required this.send});

  final double fraction;
  final double durationMs;
  final OcpSend send;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: VisageColors.accent,
        inactiveTrackColor: VisageColors.accentDim,
        thumbColor: VisageColors.fg,
        overlayColor: VisageColors.accentSoft,
      ),
      child: Slider(
        value: (_dragging ?? widget.fraction).clamp(0.0, 1.0),
        onChanged: (value) => setState(() => _dragging = value),
        onChangeEnd: (value) {
          setState(() => _dragging = null);
          widget.send(ocpSeek, seekParameters(value, widget.durationMs));
        },
      ),
    );
  }
}
