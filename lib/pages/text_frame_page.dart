/// SYSTEM_TextFrame (SPEC 8.2, SPEC 9): short answers in a glowing ring chip, title small above; long text as large
/// centred lines split into pages that fit the frame, turned at reading pace, with page dots. The pages are published
/// as an [InnerPager] (inner_pager.dart), so a person can step through them with the shell's gestures; the turning
/// then waits before it goes on from the page shown.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'data_faults.dart';
import 'inner_pager.dart';
import 'page.dart';
import 'templates_model.dart';
import 'template_text.dart';

/// The `SYSTEM_text` key list ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)):
/// `text` required, `title` optional.
List<String> textProblems(Json data) => [?requiredString(data['text'], 'text'), ?optionalString(data['title'], 'title')];

const _chipPx = 300.0;
const _chipInnerPx = 252.0;
const _dotsPx = 20.0;
const _gapsPx = 36.0;
final _longStyle = VisageText.fg(32, height: 1.32);

class TextFramePage extends StatefulWidget {
  const TextFramePage({super.key, required this.data});

  /// A missing `text`, or a key of the wrong type, is reported and the page shows what it has (gui-1.md 3.4, 6.5).
  static Widget page(Json data, PageContext ctx) => ReportsDataFaults(
    template: 'SYSTEM_text',
    problems: textProblems(data),
    child: TextFramePage(data: data),
  );

  final Json data;

  @override
  State<TextFramePage> createState() => _TextFramePageState();
}

class _TextFramePageState extends State<TextFramePage> {
  List<String> _pages = const [];
  int _index = 0;
  Timer? _timer;
  String _laidOut = '';
  double _laidOutHeight = 0;
  InnerPager? _pager;
  InnerPagerSlot? _slot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slot = InnerPagerScope.maybeOf(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _withdraw();
    super.dispose();
  }

  Duration _pageTime(int index) => Duration(milliseconds: pageDurationMs(_pages[index].split(RegExp(r'\s+')).length));

  /// Turns by itself after [after]; then every page for its own time, looping.
  void _turnAfter(Duration after) {
    _timer?.cancel();
    if (_pages.length < 2) return;
    _timer = Timer(after, () {
      setState(() => _index = (_index + 1) % _pages.length);
      _pager?.turnTo(_index);
      _turnAfter(_pageTime(_index));
    });
  }

  void _publish() {
    _withdraw();
    if (_pages.length < 2) return;
    final pager = _pager = InnerPager(count: _pages.length, pageTime: _pageTime)..addListener(_onStepped);
    _slot?.publish(pager);
  }

  void _withdraw() {
    final pager = _pager;
    if (pager == null) return;
    _slot?.withdraw(pager);
    pager.dispose();
    _pager = null;
  }

  /// A person stepped: show their page, and turn on from it once the hold is over.
  void _onStepped() {
    final pager = _pager!;
    if (pager.index != _index) setState(() => _index = pager.index);
    if (pager.takeHold() case final hold?) _turnAfter(hold);
  }

  /// Pages the long text against the available height; re-run only when the text or the frame changes.
  void _layout(String body, double width, double height) {
    if (_laidOut == body && _laidOutHeight == height) return;
    _laidOut = body;
    _laidOutHeight = height;
    _pages = paginate(body, (candidate) => measureText(candidate, _longStyle, width) <= height);
    _index = 0;
    _publish();
    if (_pages.length > 1) _turnAfter(_pageTime(0));
  }

  @override
  Widget build(BuildContext context) {
    final (:title, :text) = textFrameModel(widget.data);
    if (isShortText(text)) return _short(title, text);
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleHeight = title.isEmpty ? 0.0 : measureText(title, templateTitleStyle, constraints.maxWidth);
        _layout(text, constraints.maxWidth, constraints.maxHeight - titleHeight - _dotsPx - _gapsPx);
        return StaggerEnter(
          gap: 18,
          children: [
            if (title.isNotEmpty) TemplateTitle(title),
            Text(_pages.isEmpty ? '' : _pages[_index], textAlign: TextAlign.center, style: _longStyle),
            PageDots(count: _pages.length, active: _index),
          ],
        );
      },
    );
  }

  Widget _short(String title, String text) {
    final (:lines, :px) = shortLayout(text, _chipInnerPx);
    return StaggerEnter(
      gap: 18,
      children: [
        if (title.isNotEmpty) TemplateTitle(title),
        Circle(
          size: _chipPx,
          gradient: gradientFill,
          glow: const Glow(bloom: true),
          ring: const Ring(),
          children: [
            Text(
              lines.join('\n'),
              textAlign: TextAlign.center,
              style: VisageText.fg(px.toDouble(), weight: FontWeight.w300, height: 1.1),
            ),
          ],
        ),
      ],
    );
  }
}

/// Page dots under long text: the active one in the accent, a little larger.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: count < 2
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: i == active ? 10.8 : 8,
                      height: i == active ? 10.8 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == active ? VisageColors.accent : VisageColors.accentDim,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
