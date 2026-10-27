/// The in-window menu in Visage's vocabulary: drilling into submenus with Back, the keyboard focus, the check marks,
/// and the accessibility guidelines over the resting page at both page sizes.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/theme.dart';
import 'package:ovos_gui_visage/window/menu_rows.dart';
import 'package:ovos_gui_visage/window/status_menu.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_menu.dart';

import 'gui1_fixture.dart' show restingNow;

final _items = buildStatusMenu(const StatusMenuState(mode: WindowMode.kiosk, peek: false, visible: true, face: FaceSpec.visage));

Future<WindowMenuHost> _open(WidgetTester tester, {List<String>? chosen, Size size = const Size(480, 800)}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final host = WindowMenuHost(onSelected: chosen?.add ?? (_) {}, canQuit: true)..show(_items);
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        color: VisageColors.pageBg,
        child: WindowMenu(
          host: host,
          child: RestingPage(ambient: const {}, now: () => restingNow),
        ),
      ),
    ),
  );
  await tester.pump(menuSettle);
  host.open(Offset.zero);
  await _settle(tester);
  return host;
}

Color _colourOf(WidgetTester tester, String title) => tester.widget<Text>(find.text(title)).style!.color!;

/// Past the entry cadence or the close fade, in frames: one long pump is a single frame.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await _settle(tester);
}

void main() {
  group('levels and focus', () {
    final top = windowMenuEntries(_items, canQuit: true);

    test('the top level has no heading; a submenu has its title as heading and Back first', () {
      expect(menuLevel(top, const []).heading, isNull);
      final face = menuLevel(top, const ['face']);
      expect(face.heading, 'Face');
      expect(face.rows.first, backEntry);
      expect(face.rows.skip(1).every((e) => e.id.startsWith(facePrefix)), isTrue);
      expect(menuLevel(top, const ['gone']).heading, isNull, reason: 'a path the items no longer have ends early');
    });

    test('the focus skips separators and rows that cannot be chosen, and wraps', () {
      final rows = menuLevel(top, const []).rows;
      expect(rows[nextFocus(rows, -1, 1)].title, 'Type a command…');
      expect(rows[nextFocus(rows, -1, -1)].title, 'Quit OVOS Visage');
      final volume = rows.indexWhere((e) => e.id == volumeItem);
      expect(rows[nextFocus(rows, volume, 1)].title, 'Float above windows', reason: 'past the rule and the disabled Peek');
      expect(nextFocus(rows, rows.length - 1, 1), 0);
      expect(nextFocus(const [MenuEntry.separator()], -1, 1), -1);
    });
  });

  testWidgets('a submenu drills in under its title with Back; Back returns; a choice inside closes the menu', (tester) async {
    final chosen = <String>[];
    await _open(tester, chosen: chosen);
    await _tapText(tester, 'Face');
    expect(find.text('Full screen'), findsNothing, reason: 'the top level is replaced, not cascaded');
    expect(_colourOf(tester, 'Face'), VisageColors.muted, reason: 'the heading');
    expect(_colourOf(tester, 'Back'), VisageColors.muted);
    await _tapText(tester, 'Back');
    expect(find.text('Full screen'), findsOneWidget);
    await _tapText(tester, 'Face');
    await _tapText(tester, 'Mark 1');
    expect(chosen, ['${facePrefix}mark1']);
    expect(find.byType(MenuLevelView), findsNothing);
  });

  testWidgets('the keys: down and up move the accent, Enter chooses, Right or Enter drills, Left and Escape go back', (
    tester,
  ) async {
    final chosen = <String>[];
    await _open(tester, chosen: chosen);
    expect(_colourOf(tester, 'Type a command…'), VisageColors.fg);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_colourOf(tester, 'Type a command…'), VisageColors.accent);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect([_colourOf(tester, 'Type a command…'), _colourOf(tester, 'Volume')], [VisageColors.fg, VisageColors.accent]);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.text('Volume up'), findsOneWidget, reason: 'Enter on a submenu drills in');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('Volume up'), findsNothing);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.space);
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Full screen'), findsOneWidget, reason: 'Escape in a submenu goes back one level');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(chosen, [quitItem]);
    expect(find.byType(MenuLevelView), findsNothing);
  });

  testWidgets('a hovered row turns accent', (tester) async {
    await _open(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: tester.getCenter(find.text('Colours')));
    await tester.pump();
    expect(_colourOf(tester, 'Colours'), VisageColors.accent);
  });

  testWidgets('a checked entry shows the dot in its ring, an unchecked one the empty ring, others no mark', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);
    CheckMark? markOf(String title) {
      final row = find.ancestor(of: find.text(title), matching: find.byType(MenuRow));
      final mark = find.descendant(of: row, matching: find.byType(CheckMark));
      return mark.evaluate().isEmpty ? null : tester.widget<CheckMark>(mark);
    }

    expect(markOf('Full screen')?.checked, isTrue);
    expect(markOf('Float above windows')?.checked, isFalse);
    expect(markOf('Type a command…'), isNull);
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Full screen'), matching: find.byType(MenuRow))),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasCheckedState: true,
        isChecked: true,
        label: 'Full screen',
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  for (final page in const [Size(432, 736), Size(432, 650)]) {
    testWidgets(
      'open over the resting page at ${page.width.round()} x ${page.height.round()}: labelled tap targets, contrast, no overflow',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, size: page);
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      },
    );
  }
}
