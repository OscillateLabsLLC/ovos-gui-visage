import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/resources/locate.dart';

void main() {
  test('session values are classified by where they point', () {
    expect(locate('/res/ovos-skill-weather/sun.svg').kind, ResourceKind.cache);
    expect(locate('/res/ovos-skill-weather/sun.svg').value, 'ovos-skill-weather/sun.svg');
    expect(locate('file:///home/ovos/a.png').value, '/home/ovos/a.png');
    expect(locate('/home/ovos/a.png').kind, ResourceKind.absolute);
    expect(locate(' https://x.test/a.png ').kind, ResourceKind.http);
    expect(locate('data:image/png;base64,AA==').kind, ResourceKind.data);
    expect(locate('relative/a.png').kind, ResourceKind.none);
    expect(locate(null).kind, ResourceKind.none);
  });

  test('only image suffixes count as images', () {
    expect(locate('/res/a/b.PNG').isImage, isTrue);
    expect(locate('/res/a/b.json').isImage, isFalse);
    expect(locate('/res/a/b').isImage, isFalse);
    expect(locate('data:image/svg+xml,<svg/>').isImage, isTrue);
    expect(locate('data:text/plain,hi').isImage, isFalse);
  });
}
