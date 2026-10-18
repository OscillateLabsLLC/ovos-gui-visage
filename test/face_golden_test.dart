import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/themes.dart';
import 'package:ovos_gui_visage/face/visemes.dart';

/// Fixed frames of the shipped faces, compared against goldens so a refactor of the painters is checked in pixels.
/// Canvas rasterisation differs between platforms, so the goldens are macOS only (CI runs Linux).
void main() {
  final frames = <String, FaceFrame Function(FaceTheme)>{
    'rest': (t) => _frame(t, FaceMode.rest, eyeOpen: 1, viseme: restCode),
    'thinking': (t) => _frame(t, FaceMode.thinking, eyeOpen: 0.62, viseme: restCode, elapsed: 0.5),
    'listening': (t) => _frame(t, FaceMode.listening, eyeOpen: 1, eyeScale: 1.1, viseme: restCode, elapsed: 0.1),
    'speaking-0': (t) => _frame(t, FaceMode.speaking, eyeOpen: 1, viseme: 0),
    'speaking-2': (t) => _frame(t, FaceMode.speaking, eyeOpen: 1, viseme: 2),
    'blink': (t) => _frame(t, FaceMode.rest, eyeOpen: 0.08, viseme: restCode),
    'compact-speaking': (t) => _frame(t, FaceMode.speaking, eyeOpen: 1, viseme: 3, compact: true),
  };
  for (final name in ['visage', 'mark1']) {
    for (final entry in frames.entries) {
      testWidgets('$name ${entry.key}', (tester) async {
        final theme = faceThemeNamed(name);
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              child: ColoredBox(
                color: Colors.black,
                child: CustomPaint(size: const Size(frameWidth, frameHeight), painter: FacePainter(theme, entry.value(theme))),
              ),
            ),
          ),
        );
        await expectLater(find.byType(CustomPaint), matchesGoldenFile('goldens/face_${name}_${entry.key}.png'));
      }, skip: !Platform.isMacOS);
    }
  }
}

FaceFrame _frame(
  FaceTheme theme,
  FaceMode mode, {
  required double eyeOpen,
  required int viseme,
  double eyeScale = 1,
  double elapsed = 0,
  bool compact = false,
}) => FaceFrame(
  mode: mode,
  eyeOpen: eyeOpen,
  eyeScale: eyeScale,
  lips: theme.mouthShapes[viseme]!,
  viseme: viseme,
  elapsed: elapsed,
  compact: compact,
);
