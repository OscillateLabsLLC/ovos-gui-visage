/// SYSTEM_map (gui-1.md §3.4): a card with the label, a static pin where a map would be, and the coordinates. No map
/// provider and no network: which provider, and what to show offline, are open (docs/BACKLOG.md, GUI-1 templates).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'data_faults.dart';
import 'map_card_model.dart';
import 'page.dart';
import 'skill_header.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => MapPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final card = mapCard(data);
    final nothingToShow = card.label.isEmpty && card.coordinates.isEmpty;
    return ReportsDataFaults(
      template: 'SYSTEM_map',
      problems: card.problems,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 28,
        children: [
          SkillHeader(heading: nothingToShow ? noLocation : card.label, location: ''),
          const Circle(
            size: 270,
            gradient: gradientFill,
            ring: Ring(),
            children: [Icon(Icons.place, size: 120, color: VisageColors.accent)],
          ),
          if (card.coordinates.isNotEmpty)
            Text(card.coordinates, style: VisageText.muted(18).copyWith(fontFeatures: VisageText.tabular)),
        ],
      ),
    );
  }
}
