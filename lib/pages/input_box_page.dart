/// SYSTEM_InputBox (SPEC 8.2): the title as a prompt above a text field with the placeholder as its hint, and the
/// confirm and exit buttons. It answers as ovos-core's own SYSTEM_InputBox.qml did (mycroft/res/ui, added in #298,
/// removed with the rest of mycroft/ in #439): Enter or confirm sends `input.box.response` with `{"text": ...}` and
/// exit sends `input.box.close`, both in the skill's namespace, so the skill hears `<skill_id>.input.box.response`.
///
/// SYSTEM_input (drafted amendment A, companions_model.dart) is the same page with the `prompt`, a masked field when
/// `secret`, and one Send button: Enter or Send sends `input` with `{"text": ...}`. It has no exit event, since the
/// spoken path covers a user who does not answer.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/motion_icon.dart';
import 'companions_model.dart';
import 'page.dart';
import 'templates_model.dart';

const inputBoxResponse = 'input.box.response';
const inputBoxClose = 'input.box.close';
const sendLabel = 'Send';

/// What the page shows and sends: [exitEvent] null means no exit button.
typedef InputSpec = ({
  String prompt,
  String placeholder,
  String confirmLabel,
  String? exitLabel,
  bool secret,
  String confirmEvent,
  String? exitEvent,
  bool primaryDim,
});

InputSpec legacyInputSpec(Json data) {
  final model = inputBoxModel(data);
  return (
    prompt: model.title,
    placeholder: model.placeholder,
    confirmLabel: model.confirm.isEmpty ? 'Confirm' : model.confirm,
    exitLabel: model.exit.isEmpty ? 'Exit' : model.exit,
    secret: false,
    confirmEvent: inputBoxResponse,
    exitEvent: inputBoxClose,
    primaryDim: false,
  );
}

InputSpec companionInputSpec(Json data) {
  final model = inputModel(data);
  return (
    prompt: model.prompt,
    placeholder: model.placeholder,
    confirmLabel: sendLabel,
    exitLabel: null,
    secret: model.secret,
    confirmEvent: inputEvent,
    exitEvent: null,
    primaryDim: true,
  );
}

class InputBoxPage extends StatefulWidget {
  const InputBoxPage({super.key, required this.spec, required this.ctx});

  static Widget page(Json data, PageContext ctx) => InputBoxPage(spec: legacyInputSpec(data), ctx: ctx);

  static Widget companion(Json data, PageContext ctx) => InputBoxPage(spec: companionInputSpec(data), ctx: ctx);

  final InputSpec spec;
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

  void _confirm() => widget.ctx.trigger(widget.spec.confirmEvent, inputAnswer(field.text));

  void _exit() => widget.ctx.trigger(widget.spec.exitEvent!);

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
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
        if (spec.prompt.isNotEmpty) Text(spec.prompt, textAlign: TextAlign.center, style: VisageText.fg(30)),
        _field(spec.placeholder, secret: spec.secret),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            _button(spec.confirmLabel, _confirm, fill: spec.primaryDim ? VisageColors.accentDim : VisageColors.accent),
            if (spec.exitLabel case final exit?) _button(exit, _exit),
          ],
        ),
      ],
    );
  }

  Widget _field(String placeholder, {required bool secret}) => TextField(
    controller: field,
    focusNode: focus,
    obscureText: secret,
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

  Widget _button(String label, VoidCallback onPressed, {Color fill = VisageColors.card}) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: fill,
      foregroundColor: VisageColors.fg,
      minimumSize: const Size(150, 56),
      textStyle: VisageText.fg(20, weight: FontWeight.w500),
    ),
    child: Text(label),
  );
}
