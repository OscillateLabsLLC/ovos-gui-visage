/// docs/DESIGN.md, Motion rules: every animation stops under the platform's reduce-motion setting and draws a still
/// frame. Like test/motion_test.dart, it finds the animation owners in the source: a file under lib/ that makes a
/// ticker, an AnimationController or an AnimatedBuilder must read `MediaQuery.maybeDisableAnimationsOf`, directly or
/// through circle.dart's `motionReduced`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _owns = RegExp(r'\b(createTicker|Ticker|AnimationController|AnimatedBuilder)\b');
final _honours = RegExp(r'maybeDisableAnimationsOf|motionReduced\(');

/// Wrappers that only swap the shared animations for still widgets; they own no motion of their own.
const notOwners = {'lib/pages/reduced_motion.dart'};

/// Animation owners that ignore the setting today (first run, 2026-10-25), for docs/BACKLOG.md, Pre-announcement
/// polish audit. Fix one and take it off; the last test fails while a fixed file is still listed.
const ignoring = {
  'lib/face/face.dart': 'audit: the face ticker runs blink, widen and the mouth tween',
  'lib/pages/loading_page.dart': 'audit: the fallback thinking dots breathe',
  'lib/pages/sun_times_page.dart': 'audit: the sun rises and settles over 8 s',
};

List<String> animationOwners() => [
  for (final entity in Directory('lib').listSync(recursive: true))
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart') &&
        !notOwners.contains(entity.path) &&
        _owns.hasMatch(entity.readAsStringSync()))
      entity.path,
]..sort();

bool honours(String path) => _honours.hasMatch(File(path).readAsStringSync());

void main() {
  test('every animation owner reads the reduce-motion setting, or is on the audit list', () {
    final offenders = [
      for (final path in animationOwners())
        if (!honours(path) && !ignoring.containsKey(path)) path,
    ];
    expect(
      offenders,
      isEmpty,
      reason: 'these animate but never read MediaQuery.maybeDisableAnimationsOf:\n${offenders.join('\n')}',
    );
  });

  test('the shared widgets and the icons are among the owners that honour it', () {
    final owners = animationOwners();
    expect(owners, containsAll(['lib/widgets/circle.dart', 'lib/widgets/motion_icon.dart']));
    expect(['lib/widgets/circle.dart', 'lib/widgets/motion_icon.dart'].every(honours), isTrue);
  });

  test('the audit list holds only files that still animate and still ignore the setting', () {
    final owners = animationOwners();
    for (final path in ignoring.keys) {
      expect(owners, contains(path), reason: '$path no longer animates; take it off the list');
      expect(honours(path), isFalse, reason: '$path now honours reduced motion; take it off the list');
    }
  });
}
