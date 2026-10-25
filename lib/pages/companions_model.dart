/// The interactive companions of the drafted GUI-1 amendment A (gui1-upstream SPEC_PROPOSALS.md, part A; its 3.4
/// rows on the branch `gui1/interaction-reply-leg`): `SYSTEM_confirm`, `SYSTEM_select` and `SYSTEM_input`, their keys
/// and the reply event each one sends through [PageContext.trigger], which GUI-1 carries as an `interaction` frame.
/// Pure, except that malformed data is reported (template_keys.dart); the spoken path covers what a page cannot show.
library;

import '../json.dart';
import 'template_keys.dart';

const confirmTemplate = 'SYSTEM_confirm';
const selectTemplate = 'SYSTEM_select';
const inputTemplate = 'SYSTEM_input';

/// The reply events, each with its `data` (amendment A, the reply-event table).
const confirmEvent = 'confirm';
const selectEvent = 'select';
const inputEvent = 'input';

const defaultYes = 'Yes';
const defaultNo = 'No';

Json confirmAnswer(bool answer) => {'answer': answer};

Json selectAnswer(Object value) => {'value': value};

Json inputAnswer(String text) => {'text': text};

/// `question` is required; `yes_label` and `no_label` override the backend's own words.
({String question, String yes, String no}) confirmModel(Json data) {
  final yes = readText(confirmTemplate, data, 'yes_label');
  final no = readText(confirmTemplate, data, 'no_label');
  return (
    question: readText(confirmTemplate, data, 'question', required: true),
    yes: yes.isEmpty ? defaultYes : yes,
    no: no.isEmpty ? defaultNo : no,
  );
}

/// One choice: [value] (a string or a number) goes back unchanged.
typedef Choice = ({String label, Object value, String? image});

/// `prompt` and `items` are required. An item without a `label`, or whose `value` is not a string or a number, is
/// reported and left out, so the page offers only the choices it can answer with.
({String prompt, List<Choice> choices}) selectModel(Json data) {
  final items = readList(selectTemplate, data, 'items', required: true) ?? const [];
  return (
    prompt: readText(selectTemplate, data, 'prompt', required: true),
    choices: [...readItems(selectTemplate, items, 'items').map(_choice).nonNulls],
  );
}

Choice? _choice(Json item) {
  final label = readText(selectTemplate, item, 'label', required: true);
  final value = item['value'];
  if (value is! String && value is! num) {
    reportKey(selectTemplate, 'value', 'must be a string or a number, got ${value?.runtimeType} $value');
    return null;
  }
  if (label.isEmpty) return null;
  return (label: label, value: value!, image: readImage(selectTemplate, item, 'image'));
}

/// `prompt` is required; `secret` true masks the text, and any other value than a boolean is reported and read false.
({String prompt, String placeholder, bool secret}) inputModel(Json data) {
  final secret = data['secret'];
  if (secret != null && secret is! bool) reportKey(inputTemplate, 'secret', 'must be a boolean, got ${secret.runtimeType}');
  return (
    prompt: readText(inputTemplate, data, 'prompt', required: true),
    placeholder: readText(inputTemplate, data, 'placeholder'),
    secret: secret == true,
  );
}
