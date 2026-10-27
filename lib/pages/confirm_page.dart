/// SYSTEM_confirm (drafted amendment A, companions_model.dart): the question as plain stacked text over two round
/// answers. A tap sends `confirm` with `{"answer": true|false}`; the spoken path stays the authority.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'companion_controls.dart';
import 'companions_model.dart';
import 'page.dart';
import 'reduced_motion.dart';

class ConfirmPage extends StatelessWidget {
  const ConfirmPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => ConfirmPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  void _answer(bool answer) => ctx.trigger(confirmEvent, confirmAnswer(answer));

  @override
  Widget build(BuildContext context) {
    final (:question, :yes, :no) = confirmModel(data);
    return Center(
      child: StaggerOrStill(
        gap: 40,
        children: [
          if (question.isNotEmpty)
            Text(question, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: VisageText.fg(32)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 32,
            children: [
              AnswerCircle(label: yes, primary: true, onPressed: () => _answer(true)),
              AnswerCircle(label: no, onPressed: () => _answer(false)),
            ],
          ),
        ],
      ),
    );
  }
}
