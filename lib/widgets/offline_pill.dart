import 'package:flutter/material.dart';

/// A small rounded label at the top of the frame; [TopStatus] stacks them.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.colour, required this.background, this.icon});

  final String label;
  final Color colour;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) Icon(icon, size: 14, color: colour),
          Text(
            label,
            style: TextStyle(color: colour, fontSize: 12, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
}

/// Shown while the GUI socket is down.
class OfflinePill extends StatelessWidget {
  const OfflinePill({super.key});

  @override
  Widget build(BuildContext context) =>
      const StatusPill(label: 'GUI offline', colour: Color(0xFFFFB4B4), background: Color(0xFF3A1D1D));
}

/// The pills at the top centre of the frame, one under the other, and under them [interactive] (the notification
/// popups), which takes taps; the pills let them through to the page.
class TopStatus extends StatelessWidget {
  const TopStatus({super.key, required this.children, this.interactive});

  final List<Widget> children;
  final Widget? interactive;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          IgnorePointer(
            child: Column(mainAxisSize: MainAxisSize.min, spacing: 6, children: children),
          ),
          ?interactive,
        ],
      ),
    );
  }
}
