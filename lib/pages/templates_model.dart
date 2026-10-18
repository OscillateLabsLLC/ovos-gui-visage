/// View models for the SYSTEM_* templates (SPEC 8.2), port of templates_model.js. Keys are those
/// GUIInterface.show_* sets in ovos_bus_client/apis/gui.py. Every model tolerates null or missing keys. Pure.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart' show BoxFit;

import '../json.dart';
import 'page.dart';

const readingWpm = 180;
const minPageMs = 4000;
const shortTextChars = 24;
const _charWidthEm = 0.56;
const _maxShortPx = 72;
const _wrapBelowPx = 48;
const _minShortPx = 40;
final _breakAfter = RegExp(r'[\s.,:;/-]');
final _safeUrl = RegExp(r'^https?://', caseSensitive: false);

/// data:image, http(s), the middle layer's /res/ URLs, and (same-host display) absolute file paths; resources/
/// decides whether a path is a loadable image.
final _safeImage = RegExp(r'^(data:image/|https?://|/)', caseSensitive: false);
const _fillToFit = {'fit': BoxFit.contain, 'crop': BoxFit.cover, 'stretch': BoxFit.fill};

({String title, String text}) textFrameModel(Json? data) => (title: text(data?['title']), text: text(data?['text']));

/// How long a page of `words` words stays up at reading pace, never shorter than [minPageMs].
int pageDurationMs(int words, {int wpm = readingWpm}) => math.max(minPageMs, (words / wpm * 60000).round());

/// Split text into pages greedily: each page holds as many words as `fits(candidate)` accepts (at least one).
List<String> paginate(String fullText, bool Function(String) fits) {
  final words = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final pages = <String>[];
  var current = <String>[];
  for (final word in words) {
    final candidate = [...current, word];
    if (current.isNotEmpty && !fits(candidate.join(' '))) {
      pages.add(current.join(' '));
      current = [word];
    } else {
      current = candidate;
    }
  }
  if (current.isNotEmpty) pages.add(current.join(' '));
  return pages;
}

bool isShortText(String value) => value.isNotEmpty && value.length <= shortTextChars;

int _fitPx(int longestLine, double innerPx) =>
    math.min(_maxShortPx, (innerPx / (math.max(longestLine, 1) * _charWidthEm)).floor());

/// The two-line split that best balances the halves (ties keep the heavier top line), breaking after a space or
/// punctuation; null if none.
List<String>? splitShort(String value) {
  List<String>? best;
  var bestLongest = 0;
  for (var i = 1; i < value.length; i++) {
    if (!_breakAfter.hasMatch(value[i - 1])) continue;
    final lines = [value.substring(0, i).trimRight(), value.substring(i).trimLeft()];
    if (lines.any((line) => line.isEmpty)) continue;
    final longest = lines.map((line) => line.length).reduce(math.max);
    if (best == null || longest <= bestLongest) {
      best = lines;
      bestLongest = longest;
    }
  }
  return best;
}

/// Lines and font size (px) for a short answer inside `innerPx`: one line while it can stay at least 48 px, else two
/// lines; never below 40 px.
({List<String> lines, int px}) shortLayout(String value, double innerPx) {
  final onePx = _fitPx(value.length, innerPx);
  final split = onePx < _wrapBelowPx ? splitShort(value) : null;
  if (split == null) return (lines: [value], px: math.max(_minShortPx, onePx));
  final twoPx = _fitPx(split.map((line) => line.length).reduce(math.max), innerPx);
  if (twoPx > onePx) return (lines: split, px: math.max(_minShortPx, twoPx));
  return (lines: [value], px: math.max(_minShortPx, onePx));
}

String loadingLabel(Json? data) => text(data?['label']);

/// GUIInterface.show_status_animation sends "Enabled" / "Disabled"; the QML does a string compare.
({bool ok, String label}) statusModel(Json? data) => (ok: data?['status'] == 'Enabled', label: text(data?['label']));

/// data:, http(s) and cache paths rewritten to /res/ are loadable; anything else (a bare producer path) is not.
String? imageSource(Object? value) {
  final src = text(value).trim();
  return _safeImage.hasMatch(src) ? src : null;
}

({String? src, BoxFit fit, String background, String title, String caption}) imageModel(Json? data) => (
  src: imageSource(data?['image']),
  fit: _fillToFit[text(data?['fill']).toLowerCase()] ?? BoxFit.contain,
  background: text(data?['background_color']),
  title: text(data?['title']),
  caption: text(data?['caption']),
);

({String url, bool frameable}) urlModel(Json? data) {
  final url = text(data?['url']).trim();
  return (url: url, frameable: _safeUrl.hasMatch(url));
}

({String title, String placeholder, String confirm, String exit}) inputBoxModel(Json? data) => (
  title: text(data?['title']),
  placeholder: text(data?['placeholder']),
  confirm: text(data?['confirm_text']),
  exit: text(data?['exit_text']),
);
