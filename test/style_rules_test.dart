/// ovos-visage SPEC 9 and docs/DESIGN.md: no cards or nested panels, no accent borders or edge stripes; circles, rings
/// and plain stacked text on black. A port of ovos-visage `tests/test_style_rules.py`: it reads the source, so the
/// detection is plain pattern matching, and a sanctioned exception goes in [allowed] with its reason.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const card = 'card widget';
const roundedFill = 'filled box with rounded, not circular, corners';
const border = 'border with a width';
const divider = 'divider that is not the faint hairline';

/// The one divider colour the design allows: the stored notification list's hairline.
const _hairlines = {'_hairline', 'Color(0x24FFFFFF)'};

/// Exceptions: file -> rule -> why it is allowed. Every entry must still match something. A reason that starts with
/// `audit:` is not known to be sanctioned; docs/BACKLOG.md, Pre-announcement polish audit, lists it for a decision.
const allowed = <String, Map<String, String>>{
  'lib/pages/fallback_page.dart': {roundedFill: 'the debug card for unrouted pages (CONTRIBUTING, Visual rule)'},
  'lib/widgets/offline_pill.dart': {roundedFill: 'StatusPill: the GUI-offline pill and the outcome pill (v2.1.0)'},
  'lib/widgets/home_chips.dart': {roundedFill: 'the notification-count badge (ovos-visage .badge)'},
  'lib/pages/now_playing_status.dart': {roundedFill: 'the listening bars: 3 px wide with 2 px corners, fully rounded'},
  'lib/widgets/command_box.dart': {
    roundedFill: 'the typed-command box: corner radius is half its height, a full pill',
    border: 'the one text field: its accent outline marks where to type (decided 2026-10-25)',
  },
  'lib/widgets/volume_indicator.dart': {roundedFill: 'the volume pill: a status pill like the offline pill (decided 2026-10-25)'},
  'lib/widgets/notification_stack.dart': {
    roundedFill: 'notification popups: short-lived notices, rounded like the pills (decided 2026-10-25)',
  },
};

class Hit {
  const Hit(this.file, this.line, this.rule, this.code);

  final String file;
  final int line;
  final String rule;
  final String code;

  @override
  String toString() => '$file:$line $rule: $code';
}

List<File> libSources() => [
  for (final entity in Directory('lib').listSync(recursive: true))
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart') &&
        !entity.path.contains('lib/face/mark1_'))
      entity,
]..sort((a, b) => a.path.compareTo(b.path));

final _lineComment = RegExp(r'(?<!:)//.*');
final _call = RegExp(
  r'\b(Card|BoxDecoration|ShapeDecoration|Material|BorderSide|Border\.all|BorderDirectional|Divider|VerticalDivider)\(',
);
final _argName = RegExp(r'^\s*(\w+)\s*:');

/// Everything [file] breaks, from its [source].
List<Hit> scan(String file, String source) {
  final code = source.replaceAll(_lineComment, '');
  final hits = <Hit>[];
  for (final match in _call.allMatches(code)) {
    final args = _topLevelArgs(_inside(code, match.end));
    final rule = _rule(match.group(1)!, args);
    if (rule == null) continue;
    final line = '\n'.allMatches(code.substring(0, match.start)).length + 1;
    hits.add(Hit(file, line, rule, code.substring(match.start, (match.end + 60).clamp(0, code.length)).split('\n').first));
  }
  return hits;
}

String? _rule(String name, Map<String, String> args) => switch (name) {
  'Card' => card,
  'BoxDecoration' when args.containsKey('borderRadius') && _filled(args) && !'${args['shape']}'.contains('circle') => roundedFill,
  'ShapeDecoration' when _filled(args) && !'${args['shape']}'.contains('CircleBorder') => roundedFill,
  'Material' when args.containsKey('borderRadius') && _filled(args) => roundedFill,
  'BorderSide' || 'Border.all' when !_zero(args['width']) => border,
  'BorderDirectional' => border,
  'Divider' || 'VerticalDivider' when !_zero(args['thickness']) && !_hairlines.contains(args['color']) => divider,
  _ => null,
};

bool _filled(Map<String, String> args) =>
    (args.containsKey('color') && args['color'] != 'Colors.transparent') || args.containsKey('gradient');

/// An absent width or thickness is Flutter's default of one pixel, so only an explicit zero passes.
bool _zero(String? value) => value != null && RegExp(r'^0(\.0)?$').hasMatch(value);

/// The text between the parenthesis opened just before [from] and the one that closes it.
String _inside(String code, int from) {
  var depth = 1;
  for (var i = from; i < code.length; i++) {
    if (code[i] == '(' || code[i] == '[' || code[i] == '{') depth++;
    if (code[i] == ')' || code[i] == ']' || code[i] == '}') depth--;
    if (depth == 0) return code.substring(from, i);
  }
  return code.substring(from);
}

/// Named arguments at the call's own depth, name -> value text; nested calls' arguments are not the call's.
Map<String, String> _topLevelArgs(String inside) {
  final args = <String, String>{};
  var depth = 0, start = 0;
  void take(int end) {
    final part = inside.substring(start, end);
    final name = _argName.firstMatch(part);
    if (name != null) args[name.group(1)!] = part.substring(name.end).trim();
  }

  for (var i = 0; i < inside.length; i++) {
    final c = inside[i];
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) depth--;
    if (c == ',' && depth == 0) {
      take(i);
      start = i + 1;
    }
  }
  take(inside.length);
  return args;
}

List<Hit> violations(String rule) => [
  for (final file in libSources())
    for (final hit in scan(file.path, file.readAsStringSync()))
      if (hit.rule == rule && allowed[hit.file]?[rule] == null) hit,
];

void main() {
  for (final rule in [card, roundedFill, border, divider]) {
    test('no $rule outside the allowlist', () {
      final found = violations(rule);
      expect(found, isEmpty, reason: found.join('\n'));
    });
  }

  test('every allowlist entry still matches something, so the list cannot go stale', () {
    final all = [for (final file in libSources()) ...scan(file.path, file.readAsStringSync())];
    for (final MapEntry(key: file, value: rules) in allowed.entries) {
      for (final rule in rules.keys) {
        expect(all.any((hit) => hit.file == file && hit.rule == rule), isTrue, reason: '$file $rule');
      }
    }
  });

  test('every page and widget is scanned, generated and Mark 1 bitmap files are not', () {
    final paths = libSources().map((file) => file.path).toList();
    expect(paths, containsAll(['lib/pages/idle_page.dart', 'lib/widgets/circle.dart', 'lib/screen_frame.dart']));
    expect(paths.where((path) => path.endsWith('.g.dart') || path.contains('mark1_')), isEmpty);
  });

  test('the guard catches the alarm card it exists for', () {
    final dir = Directory.systemTemp.createTempSync('style_rules');
    final file = File('${dir.path}/alarm_card.dart')
      ..writeAsStringSync('''
final alarm = Container(
  decoration: BoxDecoration(
    color: Color(0xFF0D141C),
    borderRadius: BorderRadius.circular(18),
    border: Border(left: BorderSide(color: VisageColors.accent, width: 4)),
  ),
);
final fine = BoxDecoration(shape: BoxShape.circle, color: VisageColors.card);
''');
    final hits = scan(file.path, file.readAsStringSync());
    dir.deleteSync(recursive: true);
    expect(hits.map((hit) => hit.rule), [roundedFill, border]);
  });
}
