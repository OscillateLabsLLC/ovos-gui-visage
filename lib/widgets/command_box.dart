/// Typing a command instead of saying it: a text field over the bottom of the frame that sends what is typed as an
/// utterance (protocol/utterance.dart). Opened from the menu's "Type a command…" and from the keyboard button on the
/// homescreen in window and kiosk mode; Enter or the send button sends, Escape or the close button closes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class CommandBoxController extends ChangeNotifier {
  CommandBoxController({required this.send, this.onOpenChanged});

  /// Sends one command; true when it left, so the box closes only then.
  final bool Function(String text) send;
  final void Function(bool open)? onOpenChanged;
  bool _open = false;

  bool get isOpen => _open;

  void open() => _set(true);

  void close() => _set(false);

  /// Sends [text] and closes; blank text, or text that could not leave, keeps the box open with what was typed.
  bool submit(String text) {
    if (text.trim().isEmpty || !send(text)) return false;
    close();
    return true;
  }

  void _set(bool open) {
    if (_open == open) return;
    _open = open;
    onOpenChanged?.call(open);
    notifyListeners();
  }
}

const commandHint = 'Type a command';
const _boxHeight = 64.0;

class CommandBox extends StatefulWidget {
  const CommandBox({super.key, required this.controller});

  final CommandBoxController controller;

  @override
  State<CommandBox> createState() => _CommandBoxState();
}

class _CommandBoxState extends State<CommandBox> {
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

  void _submit() {
    if (widget.controller.submit(field.text)) field.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): widget.controller.close},
      child: Container(
        height: _boxHeight,
        padding: const EdgeInsets.only(left: 22, right: 6),
        decoration: BoxDecoration(
          color: VisageColors.card,
          borderRadius: BorderRadius.circular(_boxHeight / 2),
          border: Border.all(color: VisageColors.accentDim),
        ),
        child: Row(
          children: [
            Expanded(child: _field()),
            IconButton(tooltip: 'Send', onPressed: _submit, icon: const Icon(Icons.arrow_upward), color: VisageColors.accent),
            IconButton(
              tooltip: 'Close',
              onPressed: widget.controller.close,
              icon: const Icon(Icons.close),
              color: VisageColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field() => TextField(
    controller: field,
    focusNode: focus,
    style: VisageText.fg(22),
    cursorColor: VisageColors.accent,
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => _submit(),
    // Keeps the focus after Enter, so a command that could not leave can be sent again or closed with Escape.
    onEditingComplete: () {},
    decoration: InputDecoration.collapsed(hintText: commandHint, hintStyle: VisageText.muted(22)),
  );
}

/// The homescreen's way in, beside the idle page in window and kiosk mode.
class CommandButton extends StatelessWidget {
  const CommandButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: commandHint,
    onPressed: onPressed,
    iconSize: 30,
    style: IconButton.styleFrom(backgroundColor: VisageColors.accentSoft, foregroundColor: VisageColors.fg),
    icon: const Icon(Icons.keyboard_outlined),
  );
}
