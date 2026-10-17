import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/widgets/icon_layers.g.dart';
import 'package:ovos_gui_visage/widgets/icon_motion.dart';
import 'package:ovos_gui_visage/widgets/icon_painters.dart';
import 'package:ovos_gui_visage/widgets/motion.dart';

const _unit = {
  Prop.dx: [(0.0, 0.0), (1.0, 1.0)],
};

void main() {
  test('keyframes interpolate per interval with the curve, and hold outside', () {
    const m = Motion(tracks: swing, period: Duration(milliseconds: 3200), curve: Curves.easeInOut);
    expect(m.frameAt(0).rotate, 0);
    expect(m.frameAt(0.5).rotate, 0, reason: 'still until 70 %');
    expect(m.frameAt(0.76).rotate, 14);
    expect(m.frameAt(0.84).rotate, -11);
    expect(m.frameAt(0.73).rotate, closeTo(7, 1e-9), reason: 'easeInOut is symmetric at the midpoint');
    expect(m.frameAt(1).rotate, 0);
  });

  test('phase follows the period, negative delays advance it, alternate bounces', () {
    const period = Duration(seconds: 2);
    const normal = Motion(tracks: _unit, period: period);
    expect(normal.phase(const Duration(milliseconds: 500)), 0.25);
    expect(normal.phase(const Duration(milliseconds: 2500)), 0.25);
    const advanced = Motion(tracks: _unit, period: period, delay: Duration(milliseconds: -500));
    expect(advanced.phase(Duration.zero), 0.25);
    const later = Motion(tracks: _unit, period: period, delay: Duration(milliseconds: 500));
    expect(later.phase(Duration.zero), 0, reason: 'a positive delay holds the first keyframe until it starts');
    expect(later.phase(const Duration(seconds: 1)), 0.25);
    const bounce = Motion(tracks: _unit, period: period, direction: Direction.alternate);
    expect(bounce.phase(const Duration(seconds: 1)), 0.5);
    expect(bounce.phase(const Duration(seconds: 3)), 0.5);
    expect(bounce.phase(const Duration(milliseconds: 3500)), 0.25);
    const reverse = Motion(tracks: _unit, period: period, direction: Direction.alternateReverse);
    expect(reverse.phase(Duration.zero), 1);
    expect(reverse.phase(const Duration(milliseconds: 500)), 0.75);
  });

  test('the rain drops are a third of a cycle apart and fade in by 30 %', () {
    final first = motionFor('rain', 'drop', 1)!, second = motionFor('rain', 'drop', 2)!;
    expect(first.at(Duration.zero), const Frame(dx: 1, dy: -4, opacity: 0));
    expect(first.at(const Duration(milliseconds: 330)).opacity, closeTo(1, 1e-9));
    expect(second.at(Duration.zero), first.at(const Duration(milliseconds: 400)));
    expect(first.at(const Duration(milliseconds: 1100)), first.at(Duration.zero));
  });

  test('every animated layer in the manifest has a motion or a painter', () {
    expect(iconLayers.length, 13);
    for (final entry in iconLayers.entries) {
      for (final layer in entry.value) {
        expect(File('assets/icons/${layer.asset}').existsSync(), isTrue, reason: layer.asset);
        if (layer.cls == null) continue;
        final covered =
            motionFor(entry.key, layer.cls, layer.nth) != null ||
            layerPainter(entry.key, layer.cls, layer.nth, Duration.zero) != null;
        expect(covered, isTrue, reason: '${entry.key} ${layer.cls} ${layer.nth}');
      }
    }
    expect(iconLayers['rain']!.where((l) => l.cls == 'drop').length, 3);
    expect(iconLayers['sun']!.map((l) => l.cls), ['rays', null], reason: 'the core draws over the rays');
    expect(iconLayers['vinyl']!.single.cls, isNull);
  });

  test('no layer asset still carries a stylesheet or a class', () {
    for (final file in Directory('assets/icons').listSync().whereType<File>()) {
      final text = file.readAsStringSync();
      expect(text.contains('<style'), isFalse, reason: file.path);
      expect(text.contains('class='), isFalse, reason: file.path);
    }
  });
}
