/// The in-window menu drawn in Visage's vocabulary (docs/DESIGN.md): plain stacked text on the scrim, no box. A level is
/// the top of the menu or one entry's children, reached by drilling in; a checked entry shows an accent dot in a ring,
/// an unchecked one the empty ring. The level model is pure, so moving the focus and drilling are tested without a tree.
library;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/circle.dart';
import 'status_menu.dart';

const menuRowPx = 44.0;
const _markPx = 18.0;
const _dotPx = 10.0;
const _markGapPx = 14.0;
const _ruleGapPx = 10.0;

/// The hairline the notification list draws between its rows.
const _rule = Color(0x24FFFFFF);

/// The first row of a level below the top: it goes back up one level.
const backEntry = MenuEntry('menu.back', 'Back');

/// The level [path] (entry ids, outermost first) reaches from [top]: its heading (null at the top) and its rows, Back
/// first below the top. A path that no longer resolves, since the items changed while the menu was open, ends early.
({String? heading, List<MenuEntry> rows}) menuLevel(List<MenuEntry> top, List<String> path) {
  var rows = top;
  String? heading;
  for (final id in path) {
    final entry = rows.where((e) => e.id == id && e.children.isNotEmpty).firstOrNull;
    if (entry == null) break;
    heading = entry.title;
    rows = entry.children;
  }
  return (heading: heading, rows: [if (heading != null) backEntry, ...rows]);
}

bool focusable(MenuEntry entry) => !entry.separator && entry.enabled;

/// The focusable row [delta] steps from [from] among [rows], wrapping; from no focus (-1), down takes the first and up
/// the last. -1 when none can take the focus.
int nextFocus(List<MenuEntry> rows, int from, int delta) {
  final start = from >= 0 ? from : (delta > 0 ? -1 : rows.length);
  for (var step = 1; step <= rows.length; step++) {
    final i = (start + delta * step) % rows.length;
    if (focusable(rows[i])) return i;
  }
  return -1;
}

/// One level as plain stacked text; [focus] is the row in the accent.
class MenuLevelView extends StatelessWidget {
  const MenuLevelView({
    super.key,
    required this.heading,
    required this.rows,
    required this.focus,
    required this.onHover,
    required this.onActivate,
  });

  final String? heading;
  final List<MenuEntry> rows;
  final int focus;
  final void Function(int row) onHover;
  final void Function(int row) onActivate;

  @override
  Widget build(BuildContext context) {
    final marked = rows.any(isCheckable);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading case final title?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: VisageText.muted(17)),
          ),
        for (final (i, entry) in rows.indexed) RiseIn(index: i, child: _row(i, entry, marked)),
      ],
    );
  }

  Widget _row(int i, MenuEntry entry, bool marked) {
    if (entry.separator) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: _ruleGapPx),
        child: SizedBox(height: 1, child: ColoredBox(color: _rule)),
      );
    }
    return MenuRow(entry: entry, marked: marked, focused: i == focus, onHover: () => onHover(i), onTap: () => onActivate(i));
  }
}

/// A row: its label 24 px, muted when it cannot be chosen or goes Back, accent under the pointer or the keyboard focus.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.entry,
    required this.marked,
    required this.focused,
    required this.onHover,
    required this.onTap,
  });

  final MenuEntry entry;

  /// The level has check marks, so every row keeps their column and the labels line up.
  final bool marked;
  final bool focused;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = focusable(entry);
    final colour = focused && active
        ? VisageColors.accent
        : (active && entry != backEntry ? VisageColors.fg : VisageColors.muted);
    return Semantics(
      container: true,
      button: true,
      enabled: active,
      checked: isCheckable(entry) ? entry.checked : null,
      label: entry.title,
      onTap: active ? onTap : null,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: active ? (_) => onHover() : null,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: active ? onTap : null, child: _content(colour)),
      ),
    );
  }

  /// The mark, when the level has marks, and the label in [colour].
  Widget _content(Color colour) => SizedBox(
    height: menuRowPx,
    child: Row(
      children: [
        if (marked) ...[
          isCheckable(entry) ? CheckMark(checked: entry.checked) : const SizedBox(width: _markPx),
          const SizedBox(width: _markGapPx),
        ],
        Expanded(
          child: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VisageText.fg(24).copyWith(color: colour),
          ),
        ),
      ],
    ),
  );
}

/// The check state at a row's left: an 18 px dim ring, with a 10 px accent dot inside when checked.
class CheckMark extends StatelessWidget {
  const CheckMark({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _markPx,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(child: Ring(fraction: 0)),
        if (checked)
          const DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.accent),
            child: SizedBox.square(dimension: _dotPx),
          ),
      ],
    ),
  );
}
