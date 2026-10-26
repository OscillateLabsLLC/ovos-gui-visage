/// ovos-skill-alerts.openvoiceos / ListView (SPEC 8.5): a hero chip (ticking reminder icon in a glowing gradient
/// circle, item count inside) with the header beneath it, then the {main, secondary} items as plain stacked rows.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/motion_icon.dart';
import 'alarms_page.dart' show AlertsHeader;
import 'alerts_model.dart';
import 'page.dart';

class AlertListPage extends StatelessWidget {
  const AlertListPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => AlertListPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final model = listModel(data);
    return StaggerEnter(
      gap: 16,
      children: [
        Circle(
          size: 180,
          gradient: gradientFill,
          glow: const Glow(bloom: true),
          ring: const Ring(),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MotionIcon('reminder', size: 104),
                const SizedBox(height: 4),
                Text(
                  '${model.items.length}',
                  style: VisageText.fg(28, weight: FontWeight.w300, height: 1).copyWith(fontFeatures: VisageText.tabular),
                ),
              ],
            ),
          ],
        ),
        AlertsHeader(model.header),
        for (final item in model.items)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.main, textAlign: TextAlign.center, style: VisageText.fg(24)),
              if (item.secondary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item.secondary, style: VisageText.muted(15)),
                ),
            ],
          ),
      ],
    );
  }
}
