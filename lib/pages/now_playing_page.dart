/// ovos.common_play now-playing (SPEC 8.6): the cover turns like a record inside the progress ring, over a blurred
/// wash of itself; title, artist, a status line with equaliser bars, time and a live dot, a seek bar and the transport
/// (ocp_transport.dart). OCP shows PlayerLoader with playerBackend OVOSSyncPlayer; video and web backends get the
/// fallback.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import '../widgets/static_icon.dart';
import '../widgets/circle.dart';
import 'fallback_page.dart';
import 'now_playing_status.dart';
import 'ocp_model.dart';
import 'ocp_transport.dart';
import 'page.dart';

const _stagePx = 320.0;
const _coverInset = 24.0;
const _washInset = 56.0;
const _turnPeriod = Duration(seconds: 20);
const _settle = Duration(milliseconds: 600);

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => NowPlayingPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) {
    if (!isSyncPlayer(data)) return FallbackPage(data: data, ctx: ctx);
    return NowPlayingView(data: data, send: ctx.trigger);
  }
}

/// Reads a page's data into the [Track] the view shows; [previous] is the last one, for models that compare.
typedef TrackModel = Track Function(Json data, [Track? previous]);

/// The player itself, for any data a [model] can read: OCP's session keys by default, or a GUI-1 template's.
class NowPlayingView extends StatefulWidget {
  const NowPlayingView({super.key, required this.data, required this.send, this.model = trackModel});

  final Json data;
  final OcpSend send;
  final TrackModel model;

  @override
  State<NowPlayingView> createState() => _NowPlayingViewState();
}

class _NowPlayingViewState extends State<NowPlayingView> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late Track _track = widget.model(widget.data);
  late Anchor _anchor = anchorFor(null, _track, _nowMs);
  late final AnimationController _turn = AnimationController(vsync: this, lowerBound: 0, upperBound: 360);
  Timer? _ticker;

  double get _nowMs => _clock.elapsedMicroseconds / 1000;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    _paint(previousId: null, wasPlaying: false);
  }

  @override
  void didUpdateWidget(NowPlayingView old) {
    super.didUpdateWidget(old);
    final previous = _track;
    _track = widget.model(widget.data, previous);
    _anchor = anchorFor(_anchor, _track, _nowMs);
    _paint(previousId: previous.id, wasPlaying: previous.state == PlaybackState.playing);
  }

  /// Playing (or a new track while playing) starts the record turn from upright; leaving playing eases it back
  /// upright from wherever it stopped, so a paused logo never sits upside down.
  void _paint({required String? previousId, required bool wasPlaying}) {
    final playing = _track.state == PlaybackState.playing;
    if (playing && (!wasPlaying || previousId != _track.id)) {
      _turn.repeat(min: 0, max: 360, period: _turnPeriod);
    } else if (!playing && (wasPlaying || _turn.isAnimating)) {
      _turn.stop();
      _turn.animateTo(uprightTarget(_turn.value), duration: _settle, curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = progressAt(_track.withPosition(_anchor.positionMs), _nowMs - _anchor.at);
    final parts = statusParts(_track, progress);
    final state = _track.state;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stage(track: _track, progress: progress, turn: _turn),
        const SizedBox(height: 20),
        Text(_track.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VisageText.fg(30)),
        if (_track.artist.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: VisageText.muted(20),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if (state != PlaybackState.stopped) Equaliser(running: state == PlaybackState.playing),
            Text(parts.state.name, style: VisageText.muted(15).copyWith(letterSpacing: 0.5)),
            if (parts.live) LiveDot(running: state == PlaybackState.playing),
            Text(
              parts.live ? '${parts.time} · live' : parts.time,
              style: VisageText.muted(15).copyWith(fontFeatures: VisageText.tabular),
            ),
            if (parts.flags.isNotEmpty) Text(parts.flags.join('  '), style: VisageText.muted(15)),
          ],
        ),
        if (canSeek(_track)) SeekBar(fraction: progress.fraction, durationMs: _track.durationMs, send: widget.send),
        const SizedBox(height: 4),
        OcpTransport(track: _track, send: widget.send),
      ],
    );
  }
}

/// The disc: blurred wash, glow while playing, the turning cover, the progress ring.
class _Stage extends StatelessWidget {
  const _Stage({required this.track, required this.progress, required this.turn});

  final Track track;
  final Progress progress;
  final Animation<double> turn;

  @override
  Widget build(BuildContext context) {
    final playing = track.state == PlaybackState.playing;
    final paused = track.state == PlaybackState.paused;
    final cover = imageFor(
      track.cover,
      fit: BoxFit.cover,
      broken: staticIcon('vinyl', size: _stagePx),
    );
    final art =
        cover ??
        Padding(
          padding: const EdgeInsets.all(24),
          child: staticIcon('vinyl', size: _stagePx),
        );
    final ringColour = switch (track.state) {
      PlaybackState.playing => VisageColors.accent,
      PlaybackState.paused => VisageColors.muted,
      PlaybackState.stopped => Colors.transparent,
    };
    return SizedBox(
      width: _stagePx,
      height: _stagePx,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (cover != null)
            Positioned(
              left: -_washInset,
              top: -_washInset,
              right: -_washInset,
              bottom: -_washInset,
              child: ClipOval(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: playing ? 0.42 : (paused ? 0.2 : 0),
                    child: SizedBox.expand(child: imageFor(track.cover, fit: BoxFit.cover)),
                  ),
                ),
              ),
            ),
          Circle(
            size: _stagePx,
            glow: playing ? const Glow() : null,
            ring: Ring(fraction: progress.fraction, value: ringColour),
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: paused ? 0.45 : 1,
                child: AnimatedBuilder(
                  animation: turn,
                  builder: (context, child) => Transform.rotate(angle: turn.value * math.pi / 180, child: child),
                  child: SizedBox(
                    width: _stagePx - 2 * _coverInset,
                    height: _stagePx - 2 * _coverInset,
                    child: ClipOval(child: art),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
