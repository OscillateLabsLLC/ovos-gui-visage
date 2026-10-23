/// SYSTEM_InputBox (SPEC 8.2): the title as a prompt above a text field with the placeholder as its hint, and the
/// confirm and exit buttons. It answers as ovos-core's own SYSTEM_InputBox.qml did (mycroft/res/ui, added in #298,
/// removed with the rest of mycroft/ in #439): Enter or confirm sends `input.box.response` with `{"text": ...}` and
/// exit sends `input.box.close`, both in the skill's namespace, so the skill hears `<skill_id>.input.box.response`.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/motion_icon.dart';
import 'page.dart';
import 'templates_model.dart';

const inputBoxResponse = 'input.box.response';
const inputBoxClose = 'input.box.close';

class InputBoxPage extends StatefulWidget {
  const InputBoxPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => InputBoxPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  State<InputBoxPage> createState() => _InputBoxPageState();
}

class _InputBoxPageState extends State<InputBoxPage> {
  final field = TextEditingController();
  final focus = FocusNode();

  /// Asked for, not `autofocus`: the window surface already holds the focus, and autofocus yields to it.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  @override
  void dispose() {
    field.dispose();
    focus.dispose();
    super.dispose();
  }

  void _confirm() => widget.ctx.trigger(inputBoxResponse, {'text': field.text});

  void _exit() => widget.ctx.trigger(inputBoxClose);

  @override
  Widget build(BuildContext context) {
    final model = inputBoxModel(widget.data);
    return StaggerEnter(
      gap: 24,
      children: [
        Circle(
          size: 150,
          gradient: gradientFill,
          glow: const Glow(),
          ring: const Ring(),
          children: const [MotionIcon('mic', size: 84)],
        ),
        if (model.title.isNotEmpty) Text(model.title, textAlign: TextAlign.center, style: VisageText.fg(30)),
        _field(model.placeholder),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            _button(model.confirm.isEmpty ? 'Confirm' : model.confirm, _confirm, primary: true),
            _button(model.exit.isEmpty ? 'Exit' : model.exit, _exit),
          ],
        ),
      ],
    );
  }

  Widget _field(String placeholder) => TextField(
    controller: field,
    focusNode: focus,
    textAlign: TextAlign.center,
    style: VisageText.fg(24),
    cursorColor: VisageColors.accent,
    onSubmitted: (_) => _confirm(),
    decoration: InputDecoration(
      hintText: placeholder,
      hintStyle: VisageText.muted(22).copyWith(fontStyle: FontStyle.italic),
      filled: true,
      fillColor: VisageColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide.none),
    ),
  );

  Widget _button(String label, VoidCallback onPressed, {bool primary = false}) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: primary ? VisageColors.accent : VisageColors.card,
      foregroundColor: VisageColors.fg,
      minimumSize: const Size(150, 56),
      textStyle: VisageText.fg(20, weight: FontWeight.w500),
    ),
    child: Text(label),
  );
}
