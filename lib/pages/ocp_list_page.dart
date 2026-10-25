/// ovos.common_play / SuggestionsView and Home (SPEC 8.6). Rows: a round thumbnail with the title and source beside
/// it, the playing entry ringed in the accent. Home's skills: gradient chips with the skill icon inside, the name
/// beneath. No cards; every surface is a circle or plain text on black. Items rise in one after another.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import '../widgets/static_icon.dart';
import '../widgets/circle.dart';
import 'ocp_browse_model.dart';
import 'page.dart';

const _thumbPx = 56.0;
const _discPx = 124.0;
const _thumbFill = RadialGradient(
  center: Alignment(-0.3, -0.4),
  colors: [Color(0xFF1D2A3A), Color(0xFF0B1118)],
  stops: [0, 0.75],
);

class OcpListPage extends StatelessWidget {
  const OcpListPage({super.key, required this.data, required this.ctx});

  static Widget build_(Json data, PageContext ctx) => OcpListPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) => BrowseList(
    model: ctx.page == 'Home' ? homeModel(data) : suggestionsModel(data),
    onPlay: (play) => ctx.trigger(play.event, play.parameters),
  );
}

/// A browse model's heading and rows or chips; a row with a [RowPlay] calls [onPlay] when tapped, and with no
/// [onPlay] no row can be tapped.
class BrowseList extends StatelessWidget {
  const BrowseList({super.key, required this.model, this.onPlay});

  final BrowseModel model;
  final void Function(RowPlay play)? onPlay;

  @override
  Widget build(BuildContext context) {
    final chips = model.layout == BrowseLayout.chips;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(model.heading.toUpperCase(), textAlign: TextAlign.center, style: VisageText.muted(15).copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        if (chips)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            runSpacing: 22,
            children: [for (final (i, row) in model.rows.indexed) RiseIn(index: i, child: _SkillChip(row))],
          )
        else
          for (final (i, row) in model.rows.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            RiseIn(
              index: i,
              child: _Row(row, onTap: _player(row.play)),
            ),
          ],
        if (model.hidden > 0) ...[
          const SizedBox(height: 12),
          Text('+${model.hidden} more', textAlign: TextAlign.center, style: VisageText.muted(14)),
        ],
        if (model.rows.isEmpty) Text('Nothing here yet', textAlign: TextAlign.center, style: VisageText.muted(14)),
      ],
    );
  }

  VoidCallback? _player(RowPlay? play) {
    final onPlay = this.onPlay;
    return play == null || onPlay == null ? null : () => onPlay(play);
  }
}

/// A round thumbnail: the cover when it loads, else the vinyl glyph on a dark gradient.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.cover, required this.size, this.ringed = false});

  final String? cover;
  final double size;
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final vinyl = Padding(
      padding: EdgeInsets.all(size * 0.07),
      child: staticIcon('vinyl', size: size),
    );
    final image = imageFor(cover, fit: BoxFit.cover, broken: vinyl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _thumbFill,
        boxShadow: ringed
            ? const [
                BoxShadow(color: VisageColors.accent, spreadRadius: 3),
                BoxShadow(color: VisageColors.accentSoft, blurRadius: 22, spreadRadius: 4),
              ]
            : null,
      ),
      child: ClipOval(child: image ?? vinyl),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.row, {this.onTap});

  final BrowseRow row;

  /// Plays the entry, as a tap on a Qt row did.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final line = Row(
      spacing: 16,
      children: [
        _Thumb(cover: row.cover, size: _thumbPx, ringed: row.current),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VisageText.fg(20).copyWith(color: row.current ? VisageColors.accent : VisageColors.fg),
              ),
              if (row.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(row.subtitle, style: VisageText.muted(14)),
                ),
            ],
          ),
        ),
      ],
    );
    final tappable = InkWell(onTap: onTap, borderRadius: BorderRadius.circular(_thumbPx / 2), child: line);
    final section = row.section;
    if (section == null) return tappable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Text(section.toUpperCase(), style: VisageText.muted(13).copyWith(letterSpacing: 1)),
        ),
        tappable,
      ],
    );
  }
}

/// A skill as a gradient disc in its own hue with its icon inside, name and media types beneath.
class _SkillChip extends StatelessWidget {
  const _SkillChip(this.row);

  final BrowseRow row;

  @override
  Widget build(BuildContext context) {
    final hue = (row.hue ?? 0).toDouble();
    final light = HSLColor.fromAHSL(1, hue, 0.7, 0.42).toColor();
    final dark = HSLColor.fromAHSL(1, hue, 0.6, 0.16).toColor();
    final glow = HSLColor.fromAHSL(0.28, hue, 0.8, 0.5).toColor();
    final image = imageFor(row.cover, fit: BoxFit.contain);
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          Container(
            width: _discPx,
            height: _discPx,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [light, dark], stops: const [0, 0.72]),
              boxShadow: [BoxShadow(color: glow, blurRadius: 30, spreadRadius: 2)],
            ),
            child: Center(
              child: SizedBox(
                width: _discPx * 0.58,
                height: _discPx * 0.58,
                child: image ?? staticIcon('vinyl', size: _discPx * 0.58),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: VisageText.fg(19)),
          if (row.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(row.subtitle, textAlign: TextAlign.center, style: VisageText.muted(13)),
            ),
        ],
      ),
    );
  }
}
