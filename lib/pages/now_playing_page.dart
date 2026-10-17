/// ovos.common_play now-playing (SPEC 8.6): the cover turns like a record inside the progress ring, over a blurred
/// wash of itself; title, artist, and a status line with equaliser bars, time and a live dot. OCP shows PlayerLoader
/// with playerBackend OVOSSyncPlayer; video and web backends get the fallback.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'fallback_page.dart';
import 'ocp_model.dart';
import 'page.dart';

const _stagePx = 320.0;
const _coverInset = 24.0;
const _washInset = 56.0;
const _turnPeriod = Duration(seconds: 20);
const _settle = Duration(milliseconds: 600);
const _liveRed = Color(0xFFFF4D4D);

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => NowPlayingPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) {
    if (!isSyncPlayer(data)) return FallbackPage(data: data, ctx: ctx);
    return _Player(data: data);
  }
}

class _Player extends StatefulWidget {
  const _Player({required this.data});

  final Json data;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with SingleTickerProviderStateMixin {
  final _clock = Stopwatch()..start();
  late Track _track = trackModel(widget.data);
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
  void didUpdateWidget(_Player old) {
    super.didUpdateWidget(old);
    final previous = _track;
    _track = trackModel(widget.data, previous);
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
        const SizedBox(height: 28),
        Text(_track.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VisageText.fg(30)),
        if (_track.artist.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VisageText.muted(20)),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if (state != PlaybackState.stopped) _Equaliser(running: state == PlaybackState.playing),
            Text(parts.state.name, style: VisageText.muted(15).copyWith(letterSpacing: 0.5)),
            if (parts.live) _LiveDot(running: state == PlaybackState.playing),
            Text(parts.live ? '${parts.time} · live' : parts.time, style: VisageText.muted(15).copyWith(fontFeatures: VisageText.tabular)),
            if (parts.flags.isNotEmpty) Text(parts.flags.join('  '), style: VisageText.muted(15)),
          ],
        ),
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
    final cover = imageFor(track.cover, fit: BoxFit.cover, broken: icon('vinyl', size: _stagePx));
    final art = cover ?? Padding(padding: const EdgeInsets.all(24), child: icon('vinyl', size: _stagePx));
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
              left: -_washInset, top: -_washInset, right: -_washInset, bottom: -_washInset,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: playing ? 0.42 : (paused ? 0.2 : 0),
                child: ClipOval(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 38, sigmaY: 38), child: SizedBox.expand(child: imageFor(track.cover, fit: BoxFit.cover)))),
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

/// Four bars breathing between a quarter and full height on a 0.9 s cycle; frozen and muted on pause.
class _Equaliser extends StatefulWidget {
  const _Equaliser({required this.running});

  final bool running;

  @override
  State<_Equaliser> createState() => _EqualiserState();
}

class _EqualiserState extends State<_Equaliser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.running) _controller.repeat();
  }

  @override
  void didUpdateWidget(_Equaliser old) {
    super.didUpdateWidget(old);
    widget.running ? _controller.repeat() : _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const delays = [0.0, 0.3, 0.6, 0.45];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          for (final delay in delays)
            Container(
              width: 3,
              height: 14 * (0.25 + 0.75 * (0.5 - 0.5 * math.cos(2 * math.pi * ((_controller.value + delay) % 1)))),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: widget.running ? VisageColors.accent : VisageColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

/// The pulsing red dot of a live stream, half-dimmed and still on pause.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.running});

  final bool running;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.running ? Tween(begin: 1.0, end: 0.3).animate(_controller) : const AlwaysStoppedAnimation(0.5),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _liveRed,
          boxShadow: [BoxShadow(color: Color(0xB3FF4D4D), blurRadius: 8, spreadRadius: 1)],
        ),
      ),
    );
  }
}
