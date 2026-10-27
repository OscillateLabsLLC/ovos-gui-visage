/// SYSTEM_list (gui-1.md 3.4 Catalogue): the template title, then plain stacked rows that scroll, each a round
/// thumbnail (when the item has a usable image) with the title and the muted subtitle beside it, rising in one after
/// another after the title, as the alerts and OCP lists do. Long text ends in an ellipsis; it never shrinks.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../widgets/circle.dart';
import '../theme.dart';
import 'content_models.dart';
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';

const emptyList = 'Nothing to show';
const listThumbPx = 64.0;
const _rowGapPx = 18.0;
const _titleGapPx = 14.0;

class ListPage extends StatelessWidget {
  const ListPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => ListPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:title, :items) = systemListModel(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[RiseOrStill(index: 0, child: TemplateTitle(title)), const SizedBox(height: _titleGapPx)],
        Expanded(
          child: items.isEmpty
              ? const Center(child: TemplateHint(emptyList))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: _rowGapPx),
                  itemBuilder: (_, i) => RiseOrStill(index: i + 1, child: ListRow(items[i])),
                ),
        ),
      ],
    );
  }
}

class ListRow extends StatelessWidget {
  const ListRow(this.item, {super.key});

  final ListItem item;

  @override
  Widget build(BuildContext context) {
    final image = imageFor(item.image, fit: BoxFit.cover);
    return Row(
      spacing: 18,
      children: [
        if (image != null)
          Circle(
            size: listThumbPx,
            gradient: gradientFill,
            children: [
              ClipOval(
                child: SizedBox.square(dimension: listThumbPx, child: image),
              ),
            ],
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: VisageText.fg(24)),
              if (item.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: VisageText.muted(16)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
