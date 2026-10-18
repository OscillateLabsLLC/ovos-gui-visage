import 'package:flutter/material.dart';

/// The pill at the top of the frame while the GUI socket is down.
class OfflinePill extends StatelessWidget {
  const OfflinePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF3A1D1D), borderRadius: BorderRadius.circular(10)),
          child: const Text('GUI offline', style: TextStyle(color: Color(0xFFFFB4B4), fontSize: 12)),
        ),
      ),
    );
  }
}
