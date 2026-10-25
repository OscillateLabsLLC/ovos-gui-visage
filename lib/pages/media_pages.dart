/// The GUI-1 media templates ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue))
/// on the OCP pages. SYSTEM_audio_player is the now-playing view; SYSTEM_media_player chooses between now-playing,
/// search results, queue, busy and error; SYSTEM_video_player degrades to the same circular card with a play glyph, its
/// title and play state
/// ([6.5 Capability and graceful degradation](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#65-capability-and-graceful-degradation)),
/// since Visage decodes no video yet. The transport answers in OCP's namespace whichever namespace showed the page
/// ([7.1 Media transport](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#71-media-transport), finding F30).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'media_browse_model.dart';
import 'media_model.dart';
import 'now_playing_page.dart';
import 'ocp_busy_page.dart';
import 'ocp_list_page.dart';
import 'ocp_model.dart';
import 'page.dart';
import 'status_page.dart';

const _stillPx = 260.0;

/// [ctx] re-addressed to OCP, so `pause` arrives as `ovos.common_play.pause` and not as `<the app>.pause`.
PageContext ocpContext(PageContext ctx) =>
    PageContext(namespace: ocpNamespace, page: ctx.page, events: ctx.events, send: ctx.send);

class AudioPlayerPage extends StatelessWidget {
  const AudioPlayerPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => AudioPlayerPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) => NowPlayingView(data: data, send: ocpContext(ctx).trigger, model: audioTrack);
}

class VideoPlayerPage extends StatelessWidget {
  const VideoPlayerPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => VideoPlayerPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:title, :state) = videoModel(data);
    final playing = state == PlaybackState.playing;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Circle(
          size: _stillPx,
          glow: playing ? const Glow() : null,
          ring: Ring(fraction: 1, value: playing ? VisageColors.accent : VisageColors.muted),
          children: [Icon(Icons.play_arrow_rounded, size: _stillPx * 0.4, color: VisageColors.fg)],
        ),
        const SizedBox(height: 24),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VisageText.fg(28)),
        const SizedBox(height: 10),
        Text(state.name, style: VisageText.muted(15).copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text('The video itself is not shown on this display', textAlign: TextAlign.center, style: VisageText.muted(13)),
      ],
    );
  }
}

class MediaPlayerPage extends StatefulWidget {
  const MediaPlayerPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => MediaPlayerPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  MediaView? _chosen;

  @override
  Widget build(BuildContext context) {
    final views = mediaViews(widget.data);
    final view = views.contains(_chosen) ? _chosen! : views.first;
    final choices = views.where(viewLabels.containsKey).toList();
    return Column(
      children: [
        if (choices.length > 1) _ViewChoice(choices: choices, view: view, choose: (v) => setState(() => _chosen = v)),
        Expanded(child: _view(view)),
      ],
    );
  }

  Widget _view(MediaView view) => switch (view) {
    MediaView.nowPlaying => NowPlayingView(data: widget.data, send: ocpContext(widget.ctx).trigger, model: mediaTrack),
    MediaView.results => BrowseList(model: resultsModel(widget.data)),
    MediaView.queue => BrowseList(model: queueModel(widget.data)),
    MediaView.loading => OcpBusyPage(data: {'footer_text': mediaStateLabel(widget.data, view)}),
    MediaView.error => StatusPage(data: {'success': false, 'label': mediaStateLabel(widget.data, view)}),
    MediaView.empty => Center(child: Text('Nothing playing', style: VisageText.muted(20))),
  };
}

/// The plain buttons that switch between the views the data fills; they send nothing.
class _ViewChoice extends StatelessWidget {
  const _ViewChoice({required this.choices, required this.view, required this.choose});

  final List<MediaView> choices;
  final MediaView view;
  final ValueChanged<MediaView> choose;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [
      for (final choice in choices)
        TextButton(
          onPressed: choice == view ? null : () => choose(choice),
          child: Text(
            viewLabels[choice]!.toUpperCase(),
            style: VisageText.muted(13).copyWith(letterSpacing: 1, color: choice == view ? VisageColors.accent : null),
          ),
        ),
    ],
  );
}
