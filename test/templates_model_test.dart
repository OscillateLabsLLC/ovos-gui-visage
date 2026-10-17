// Port of tests/js/templates_model.test.mjs (the html srcdoc parts move with the webview work).
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/templates_model.dart';

void main() {
  test('every model tolerates null and missing keys', () {
    for (final data in [
      null,
      <String, dynamic>{},
      {'title': null, 'text': null, 'label': null, 'image': null, 'url': null},
    ]) {
      expect(textFrameModel(data), (title: '', text: ''));
      expect(loadingLabel(data), '');
      expect(statusModel(data), (ok: false, label: ''));
      expect(imageModel(data), (src: null, fit: BoxFit.contain, background: '', title: '', caption: ''));
      expect(urlModel(data), (url: '', frameable: false));
      expect(inputBoxModel(data), (title: '', placeholder: '', confirm: '', exit: ''));
    }
  });

  test('paginate fills each page as far as fits() allows and never drops a word', () {
    final words = List.generate(23, (i) => 'w$i').join(' ');
    final pages = paginate(words, (candidate) => candidate.split(' ').length <= 10);
    expect(pages.map((p) => p.split(' ').length), [10, 10, 3]);
    expect(pages.join(' '), words);
    expect(paginate('onlyoneverylongword', (_) => false), ['onlyoneverylongword']);
    expect(paginate('', (_) => true), isEmpty);
  });

  test('pages stay up at reading pace with a floor', () {
    expect(pageDurationMs(180), 60000);
    expect(pageDurationMs(66), 22000);
    expect(pageDurationMs(3), 4000);
  });

  test('status is Enabled only on the exact string the producer sends', () {
    expect(statusModel({'status': 'Enabled'}).ok, isTrue);
    for (final status in ['Disabled', 'enabled', true, 1]) {
      expect(statusModel({'status': status}).ok, isFalse, reason: '$status');
    }
  });

  test('image sources: data:image, http(s), /res/ and absolute paths are candidates; other schemes are not', () {
    expect(imageSource('data:image/png;base64,AAAA'), 'data:image/png;base64,AAAA');
    expect(imageSource('https://x.org/a.png'), 'https://x.org/a.png');
    expect(imageSource('/res/ns/qt5/a.svg'), '/res/ns/qt5/a.svg');
    expect(imageSource('/home/ovos/.cache/ovos_gui/x/a.png'), '/home/ovos/.cache/ovos_gui/x/a.png');
    for (final bad in ['relative.png', 'file:///tmp/a.png', 'javascript:alert(1)', 'data:text/html,<b>x</b>']) {
      expect(imageSource(bad), isNull, reason: bad);
    }
    expect(['fit', 'crop', 'stretch', 'CROP', 'zoom'].map((fill) => imageModel({'fill': fill}).fit), [
      BoxFit.contain,
      BoxFit.cover,
      BoxFit.fill,
      BoxFit.cover,
      BoxFit.contain,
    ]);
  });

  test('url frames only http(s)', () {
    expect(urlModel({'url': 'https://example.com'}).frameable, isTrue);
    expect(urlModel({'url': 'file:///etc/hosts'}).frameable, isFalse);
    expect(urlModel({'url': 'javascript:alert(1)'}).frameable, isFalse);
  });

  test('short answers stay one line while big, wrap before shrinking below 48 px, never below 40 px', () {
    expect(isShortText('tails'), isTrue);
    expect(isShortText(''), isFalse);
    expect(isShortText('x' * 25), isFalse);
    final tails = shortLayout('tails', 252);
    expect(tails.lines, ['tails']);
    expect(tails.px, 72);
    final ip = shortLayout('192.168.100.200', 252);
    expect(ip.lines, ['192.168.', '100.200']);
    expect(ip.px >= 48 && 8 * 0.56 * ip.px <= 252, isTrue, reason: '${ip.px}px');
    expect(shortLayout('supercalifragilistic', 252).lines, ['supercalifragilistic']);
    expect(shortLayout('supercalifragilistic', 252).px, 40);
    expect(shortLayout('${'x' * 12} ${'x' * 11}', 252).px, greaterThanOrEqualTo(40));
  });

  test('splitShort balances the halves at a space or punctuation', () {
    expect(splitShort('New York City'), ['New York', 'City']);
    expect(splitShort('10.0.0.1'), ['10.0.', '0.1']);
    expect(splitShort('abcdef'), isNull);
  });
}
