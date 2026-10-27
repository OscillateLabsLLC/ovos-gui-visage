/// SYSTEM_grid (gui-1.md 3.4 Catalogue): the template title, then equal round tiles that scroll, the image filling each
/// circle and the title beneath, rising in one after another after the title. The column count follows the width (`gridColumns`). A
/// tile without a usable image is a gradient circle with its title inside instead.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'content_models.dart';
import 'image_frame_page.dart' show unavailable;
import 'list_page.dart' show emptyList;
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';

const gridGapPx = 16.0;
const _tileTitlePx = 34.0;
const _titleGapPx = 14.0;
const _loneTitlePadding = 0.14;

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
        if (title.isNotEmpty) ...[RiseOrStill(index: 0, child: TemplateTitle(title)), const SizedBox(height: _titleGapPx)],
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
        itemBuilder: (_, i) => RiseOrStill(
          index: i + 1,
          child: GridItemView(tiles[i], side: side),
        ),
      );
    },
  );
}

class GridItemView extends StatelessWidget {
  const GridItemView(this.tile, {super.key, required this.side});

  final GridItem tile;
  final double side;

  @override
  Widget build(BuildContext context) {
    final image = imageFor(tile.image, fit: BoxFit.cover, broken: _loneTitle());
    return Column(
      children: [
        Circle(
          size: side,
          gradient: gradientFill,
          children: [
            image == null
                ? _loneTitle()
                : ClipOval(
                    child: SizedBox.square(dimension: side, child: image),
                  ),
          ],
        ),
        if (image != null && tile.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tile.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: VisageText.fg(18),
            ),
          ),
      ],
    );
  }

  /// The tile without its image: the title inside the circle, or the image page's hint when it has none.
  Widget _loneTitle() => Padding(
    padding: EdgeInsets.all(side * _loneTitlePadding),
    child: Text(
      tile.title.isEmpty ? unavailable : tile.title,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: VisageText.fg(20),
    ),
  );
}
