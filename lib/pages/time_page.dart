/// ovos-skill-date-time / time: the concept's big blue clock ring (SPEC 8.4).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';

final _trailingAmPm = RegExp(r'^(.*?)\s*([AaPp][Mm])$');

/// The skill sends "12:15 PM" with an empty `ampm_string` on 12-hour installs; the suffix belongs on its own line.
({String time, String ampm}) timeParts(Json data) {
  final time = text(data['time_string']);
  final ampm = text(data['ampm_string']);
  final match = ampm.isEmpty ? _trailingAmPm.firstMatch(time) : null;
  if (match == null) return (time: time, ampm: ampm);
  return (time: match.group(1)!, ampm: match.group(2)!.toUpperCase());
}

class TimePage extends StatelessWidget {
  const TimePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => TimePage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:time, :ampm) = timeParts(data);
    return Center(
      child: Circle(
        size: 380,
        gradient: const RadialGradient(colors: [VisageColors.clockTop, VisageColors.clockBottom], stops: [0, 0.7]),
        glow: const Glow(),
        ring: const Ring(track: VisageColors.accentSoft, stroke: 5),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time.isEmpty ? '--:--' : time,
                style: VisageText.fg(120, weight: FontWeight.w300, height: 1).copyWith(letterSpacing: -2, fontFeatures: VisageText.tabular),
              ),
              if (ampm.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(ampm, style: VisageText.base.copyWith(color: VisageColors.accent, fontSize: 22, letterSpacing: 2)),
                ),
              const SizedBox(height: 10),
              Text(text(data['date_string']), style: VisageText.fg(22)),
            ],
          ),
        ],
      ),
    );
  }
}
