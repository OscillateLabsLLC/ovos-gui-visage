/// SYSTEM_grid (gui-1.md §3.4, line 230): the muted title, then equal square tiles that scroll, the image filling
/// each rounded tile and the title beneath. The column count follows the width (`gridColumns`). A tile without a
/// usable image shows its title on the plain card colour instead.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'content_models.dart';
import 'list_page.dart' show emptyList;
import 'page.dart';
import 'template_text.dart';

const gridGapPx = 16.0;
const _tileTitlePx = 30.0;

class GridPage extends StatelessWidget {
  const GridPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => GridPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:title, :tiles) = gridModel(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[TemplateTitle(title), const SizedBox(height: 14)],
        Expanded(child: tiles.isEmpty ? const Center(child: TemplateHint(emptyList)) : _grid(tiles)),
      ],
    );
  }

  Widget _grid(List<GridItem> tiles) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = gridColumns(constraints.maxWidth, gap: gridGapPx);
      final side = (constraints.maxWidth - gridGapPx * (columns - 1)) / columns;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: gridGapPx,
          crossAxisSpacing: gridGapPx,
          childAspectRatio: side / (side + _tileTitlePx),
        ),
        itemCount: tiles.length,
        itemBuilder: (_, i) => RiseIn(index: i.clamp(0, 5), child: GridItemView(tiles[i])),
      );
    },
  );
}

class GridItemView extends StatelessWidget {
  const GridItemView(this.tile, {super.key});

  final GridItem tile;

  @override
  Widget build(BuildContext context) {
    final image = imageFor(tile.image, fit: BoxFit.cover);
    final lone = image == null && tile.title.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: VisageColors.card,
              child:
                  image ??
                  Center(
                    child: Text(lone ? tile.title : '', textAlign: TextAlign.center, style: VisageText.fg(18)),
                  ),
            ),
          ),
        ),
        if (!lone && tile.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tile.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: VisageText.muted(15),
            ),
          ),
      ],
    );
  }
}
