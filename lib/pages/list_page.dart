/// SYSTEM_list (gui-1.md §3.4, line 229): the muted title, then rows that scroll, each a round thumbnail (when the
/// item has a usable image) with the title and the muted subtitle beside it, rising in one after another, as the OCP
/// suggestion rows do.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'content_models.dart';
import 'page.dart';
import 'template_text.dart';

const emptyList = 'Nothing to show';
const listThumbPx = 56.0;

class ListPage extends StatelessWidget {
  const ListPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => ListPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:title, :items) = listModel(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[TemplateTitle(title), const SizedBox(height: 14)],
        if (items.isEmpty) const Expanded(child: Center(child: TemplateHint(emptyList))),
        if (items.isNotEmpty)
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => RiseIn(index: i.clamp(0, 5), child: ListRow(items[i])),
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
      spacing: 16,
      children: [
        if (image != null)
          SizedBox(
            width: listThumbPx,
            height: listThumbPx,
            child: ClipOval(
              child: ColoredBox(color: VisageColors.card, child: image),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: VisageText.fg(20)),
              if (item.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: VisageText.muted(14)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
