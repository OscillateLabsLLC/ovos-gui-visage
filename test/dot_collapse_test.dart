import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/attention.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/shell_overlays.dart';
import 'package:ovos_gui_visage/widgets/dot_collapse.dart';

const _centre = Offset(40, 60);

Widget _framed(Widget child, {bool still = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Material(child: child),
  ),
);

Widget _dot(bool collapsed, {bool still = false}) => _framed(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 100,
      height: 100,
      child: DotCollapse(collapsed: collapsed, centre: _centre, child: const SizedBox.expand()),
    ),
  ),
  still: still,
);

Matrix4 _transform(WidgetTester tester) =>
    tester.widget<Transform>(find.descendant(of: find.byType(DotCollapse), matching: find.byType(Transform)).first).transform;

double _scale(WidgetTester tester) => _transform(tester).entry(0, 0);

void main() {
  testWidgets('the child shrinks to a dot at its centre over 300 ms, and is whole again at once', (tester) async {
    await tester.pumpWidget(_dot(false));
    expect(_scale(tester), 1);
    await tester.pumpWidget(_dot(true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scale(tester), inExclusiveRange(dotScale, 1));
    expect(MatrixUtils.transformPoint(_transform(tester), _centre), _centre, reason: 'the centre stays put');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scale(tester), closeTo(dotScale, 1e-9));
    await tester.pumpWidget(_dot(false));
    expect(_scale(tester), 1);
  });

  testWidgets('under reduced motion the collapse is a cut', (tester) async {
    await tester.pumpWidget(_dot(false, still: true));
    await tester.pumpWidget(_dot(true, still: true));
    expect(_scale(tester), closeTo(dotScale, 1e-9));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the attention face collapses to a dot while it stays opaque, then fades', (tester) async {
    final face = FaceController();
    final attention = Attention(face)..shown = true;
    addTearDown(attention.dispose);
    Widget overlay() => _framed(
      SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: AttentionOverlay(attention: attention, face: face),
      ),
    );
    double opacity() => tester.renderObject<RenderAnimatedOpacity>(find.byType(AnimatedOpacity)).opacity.value;
    await tester.pumpWidget(overlay());
    await tester.pump(const Duration(milliseconds: 500));
    attention.hide();
    await tester.pumpWidget(overlay());
    await tester.pump(const Duration(milliseconds: 200));
    expect(_scale(tester), lessThan(1));
    expect(opacity(), 1, reason: 'opaque while it collapses');
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacity(), 0);
  });
}
