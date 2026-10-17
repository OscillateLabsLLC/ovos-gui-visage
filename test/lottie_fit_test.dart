// Port of tests/js/lottie_fit.test.mjs, against OVOS's loading.json shape.
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/lottie/fit.dart';

Map<String, dynamic> layer({List<double> p = const [100, 100, 0], double r = 0, List<Map<String, dynamic>> shapes = const []}) =>
    {
      'ks': {
        'p': {'k': p},
        'a': {
          'k': [0, 0, 0],
        },
        's': {
          'k': [100, 100, 100],
        },
        'r': {'k': r},
      },
      'shapes': shapes,
    };

Map<String, dynamic> ellipse(double size, {List<double> at = const [0, 0], double stroke = 0}) => {
  'ty': 'gr',
  'it': [
    {
      'ty': 'el',
      's': {
        'k': [size, size],
      },
      'p': {'k': at},
    },
    {
      'ty': 'st',
      'w': {'k': stroke},
    },
    {
      'ty': 'tr',
      'p': {
        'k': [0, 0],
      },
    },
  ],
};

void main() {
  test('the largest static circle is the ring', () {
    final data = {
      'w': 300,
      'h': 400,
      'layers': [
        layer(shapes: [ellipse(40)]),
        layer(p: [150, 200, 0], shapes: [ellipse(200, stroke: 10)]),
      ],
    };
    expect(ringOf(data), (cx: 150.0, cy: 200.0, r: 105.0));
    final fit = ringFit(data)!;
    expect(fit.width, closeTo(300 * 0.98 / 210, 1e-9));
    expect(fit.left, closeTo(0.5 - 150 * 0.98 / 210, 1e-9));
  });

  test('a rotated offset circle lands where the layer rotation puts it', () {
    final data = {
      'w': 100,
      'h': 100,
      'layers': [
        layer(
          p: [50, 50, 0],
          r: 90,
          shapes: [
            ellipse(20, at: [10, 0]),
          ],
        ),
      ],
    };
    final ring = ringOf(data)!;
    expect(ring.cx, closeTo(50, 1e-9));
    expect(ring.cy, closeTo(60, 1e-9));
  });

  test('no circles means no fit', () {
    expect(ringOf({'layers': []}), isNull);
    expect(ringFit({'w': 1, 'h': 1, 'layers': []}), isNull);
    expect(
      ringOf({
        'layers': [
          layer(
              shapes: [
                ellipse(20, at: [5, 0]),
              ],
            )
            ..['ks']['r'] = {
              'k': [1],
            },
        ],
      }),
      isNull,
    );
  });
}
