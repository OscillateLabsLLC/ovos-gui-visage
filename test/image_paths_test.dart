/// Finding F39: over GUI-1 an absolute filesystem path in an image key is a fault and the image is dropped (gui-1.md 3.5;
/// amendment G makes it a MUST); legacy keeps loading a path, as the Qt pages did. The page learns the protocol from
/// its PageContext.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/companions_model.dart';
import 'package:ovos_gui_visage/pages/image_frame_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/template_keys.dart';
import 'package:ovos_gui_visage/pages/templates_model.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const _path = '/Users/me/cat.png';
const _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

PageContext _ctx(String page, ChosenProtocol? protocol) =>
    PageContext(namespace: hello, page: page, events: const {}, protocol: protocol);

void main() {
  setUp(forgetReportedKeys);

  test('the model keeps a path on legacy and drops it, reported, over GUI-1', () async {
    expect(imageModel({'image': _path}).src, _path);
    final faults = await collectFaults(() async {
      expect(imageModel({'image': _path}, gui1Template: 'SYSTEM_image').src, isNull);
      expect(imageModel({'image': _png}, gui1Template: 'SYSTEM_image').src, _png);
    });
    expect(faults.single.exceptionAsString(), contains('image must be an http(s) URL or a data:image URI'));
  });

  test('the page reads the protocol from its context, under every name of the template', () {
    for (final name in ['SYSTEM_image', 'SYSTEM_ImageFrame', 'SYSTEM_animated_image']) {
      final gui1 = ImageFramePage.page(const {'image': _path}, _ctx(name, ChosenProtocol.gui1)) as ImageFramePage;
      expect(gui1.gui1Template, isNotNull, reason: name);
      for (final legacy in [ChosenProtocol.legacy, null]) {
        expect((ImageFramePage.page(const {}, _ctx(name, legacy)) as ImageFramePage).gui1Template, isNull);
      }
    }
  });

  testWidgets('over GUI-1 the image page with a path shows "Image unavailable" and reports it', (tester) async {
    final page = resolve(const Target(hello, 'SYSTEM_image', 0), gaps: freshGaps().templates);
    final faults = await collectFaults(() async {
      await tester.pumpWidget(host(page(const {'image': _path, 'title': 'Cat'}, _ctx('SYSTEM_image', ChosenProtocol.gui1))));
    });
    expect(find.text(unavailable), findsOneWidget);
    expect(faults.single.exceptionAsString(), contains(_path));
  });

  testWidgets('on legacy the same page tries the path, so a missing file is the only report', (tester) async {
    final page = resolve(const Target(hello, 'SYSTEM_image', 0), gaps: freshGaps().templates);
    final faults = await collectFaults(() async {
      await tester.pumpWidget(host(page(const {'image': _path}, _ctx('SYSTEM_image', ChosenProtocol.legacy))));
    });
    expect(faults.single.exceptionAsString(), contains('no such file $_path'));
  });

  test('list and select item images refuse a path on every protocol, as the media and weather keys do', () async {
    final faults = await collectFaults(() async {
      expect(readImage('SYSTEM_list', {'image': _path}, 'image'), isNull);
      expect(
        selectModel({
          'prompt': 'p',
          'items': [
            {'label': 'a', 'value': 'a', 'image': _path},
          ],
        }).choices.single.image,
        isNull,
      );
    });
    expect(faults, hasLength(2));
  });
}
