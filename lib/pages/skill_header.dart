/// The heading and location lines above a skill page (skills.css .skill-header), and the details line below.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class SkillHeader extends StatelessWidget {
  const SkillHeader({super.key, required this.heading, required this.location});

  final String heading;
  final String location;

  @override
  Widget build(BuildContext context) {
    if (heading.isEmpty && location.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heading.isNotEmpty) Text(heading, textAlign: TextAlign.center, style: VisageText.fg(22, weight: FontWeight.w500, height: 1.3)),
        if (location.isNotEmpty) Text(location, textAlign: TextAlign.center, style: VisageText.muted(15).copyWith(height: 1.3)),
      ],
    );
  }
}

class SkillDetails extends StatelessWidget {
  const SkillDetails(this.details, {super.key});

  final String details;

  @override
  Widget build(BuildContext context) =>
      details.isEmpty ? const SizedBox.shrink() : Text(details, textAlign: TextAlign.center, style: VisageText.muted(16));
}
