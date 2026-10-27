/// SYSTEM_select (drafted amendment A, companions_model.dart): the prompt as plain text, then one full-width answer per
/// choice that scrolls and rises in. A tap sends `select` with the choice's `value` unchanged. With no usable choice
/// the prompt stands alone with a hint, since the spoken path still takes the answer.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../theme.dart';
import 'companion_controls.dart';
import 'companions_model.dart';
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';

const noChoices = 'Answer by voice';
const _rowGapPx = 14.0;

class SelectPage extends StatelessWidget {
  const SelectPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => SelectPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) {
    final (:prompt, :choices) = selectModel(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: [
        if (prompt.isNotEmpty)
          Text(prompt, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: VisageText.fg(30)),
        Expanded(
          child: choices.isEmpty
              ? const Center(child: TemplateHint(noChoices))
              : ListView.separated(
                  itemCount: choices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: _rowGapPx),
                  itemBuilder: (_, i) => RiseOrStill(index: i, child: _button(choices[i])),
                ),
        ),
      ],
    );
  }

  Widget _button(Choice choice) => ChoiceButton(
    label: choice.label,
    thumbnail: imageFor(choice.image, fit: BoxFit.cover),
    onPressed: () => ctx.trigger(selectEvent, selectAnswer(choice.value)),
  );
}
