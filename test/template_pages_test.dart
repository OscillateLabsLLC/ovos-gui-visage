import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/html_frame_page.dart';
import 'package:ovos_gui_visage/pages/image_frame_page.dart';
import 'package:ovos_gui_visage/pages/input_box_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/status_page.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/pages/url_frame_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const ctx = PageContext(namespace: 'some.skill', page: 'SYSTEM_TextFrame', events: {});

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 736, child: page)),
  ),
);

const longText =
    'A teaspoon is about five millilitres, a tablespoon is three teaspoons, and a cup is sixteen tablespoons. '
    'So a cup holds forty-eight teaspoons, or roughly two hundred and forty millilitres. In the United Kingdom the '
    'cup was historically larger, about two hundred and eighty-four millilitres, but most modern recipes use the '
    'metric cup of two hundred and fifty millilitres. When a recipe says a scant cup it means slightly less than '
    'full; a heaping tablespoon is mounded above the rim. Dry ingredients should be levelled with a knife, and flour '
    'should be spooned into the cup rather than scooped.';

void main() {
  test('every SYSTEM template is routed by page name in any namespace', () {
    for (final name in templates.keys) {
      expect(resolve(Target('any.skill', name, 0))({}, ctx), isNot(isA<Text>()), reason: name);
    }
  });

  testWidgets('a short text frame sits in a chip with its title', (tester) async {
    await tester.pumpWidget(host(TextFramePage.page({'text': 'Tails', 'title': 'Coin flip'}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COIN FLIP'), findsOneWidget);
    expect(find.text('Tails'), findsOneWidget);
    expect(find.byType(PageDots), findsNothing);
  });

  testWidgets('a long text frame is paginated with dots and steps pages', (tester) async {
    await tester.pumpWidget(host(TextFramePage.page({'text': longText, 'title': null}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    final dots = tester.widget<PageDots>(find.byType(PageDots));
    expect(dots.count, greaterThan(1));
    expect(dots.active, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.widget<PageDots>(find.byType(PageDots)).active, 0, reason: 'a page stays at least 4 s');
    await tester.pump(const Duration(seconds: 61));
    expect(tester.widget<PageDots>(find.byType(PageDots)).active, isNot(0));
  });

  testWidgets('status without a cached animation draws the glyph and label', (tester) async {
    await tester.pumpWidget(host(StatusPage.page({'status': 'Disabled', 'label': 'Microphone muted'}, ctx)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Microphone muted'), findsOneWidget);
  });

  testWidgets('image frame shows the hint when the image cannot load, and reports it', (tester) async {
    await tester.pumpWidget(host(ImageFramePage.page({'image': '/nope/missing.png', 'caption': 'cap', 'title': 't'}, ctx)));
    expect('${tester.takeException()}', contains('no such file /nope/missing.png'));
    expect(find.text(unavailable), findsOneWidget);
    expect(find.text('cap'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
  });

  test('background colours parse like CSS', () {
    expect(parseColor('#0d1a28'), const Color(0xFF0D1A28));
    expect(parseColor('#fff'), const Color(0xFFFFFFFF));
    expect(parseColor(''), Colors.transparent);
    expect(parseColor('blue'), Colors.transparent);
  });

  testWidgets('input box shows title, placeholder and hints', (tester) async {
    final data = {'title': 'Name?', 'placeholder': 'say a name', 'confirm_text': 'OK', 'exit_text': 'Cancel'};
    await tester.pumpWidget(host(InputBoxPage.page(data, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Name?'), findsOneWidget);
    expect(find.text('say a name'), findsOneWidget);
    expect(find.text('OK  ·  Cancel'), findsOneWidget);
  });

  testWidgets('url frame shows the address and why it is not framed', (tester) async {
    await tester.pumpWidget(host(UrlFramePage.page({'url': 'https://example.com'}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('https://example.com'), findsOneWidget);
    expect(find.text('no web view on this platform'), findsOneWidget);
  });

  test('html is reduced to text', () {
    expect(htmlToText('<style>p{}</style><p>Hello <b>there</b></p><script>x()</script><p>&amp; bye</p>'), 'Hello there\n& bye');
  });
}
