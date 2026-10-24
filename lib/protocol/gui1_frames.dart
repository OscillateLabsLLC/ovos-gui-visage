/// The GUI-1 adapter wire protocol, version 1 (gui1-upstream WIRE.md): the `hello` Visage sends and the typed frames
/// the adapter answers with. Pure: [parseGui1Frame] turns one decoded text frame into a [Gui1Frame] or throws.
library;

import '../json.dart';

export '../json.dart';

const gui1Protocol = 'ovos-gui-1';
const gui1Version = 1;
const gui1Port = 18182;
const gui1Path = '/gui1';
const defaultSessionId = 'default';

/// Kept equal to pubspec.yaml's version by test/gui1_frames_test.dart.
const visageVersion = '2.4.0';
const gui1ClientName = 'visage/$visageVersion';

Json helloFrame({String sessionId = defaultSessionId, String client = gui1ClientName}) => {
  'type': 'hello',
  'protocol': gui1Protocol,
  'version': gui1Version,
  'session_id': sessionId,
  'client': client,
};

sealed class Gui1Frame {
  const Gui1Frame();
}

class Gui1Welcome extends Gui1Frame {
  const Gui1Welcome({required this.protocol, required this.version, required this.sessionId, required this.server});

  final String protocol;
  final int version;
  final String sessionId;
  final String server;
}

class Gui1Error extends Gui1Frame {
  const Gui1Error(this.reason);

  final String reason;
}

/// Show [template] (a spec name, or a skill's own template name) for [skillId]; [data] is the full session data.
class Gui1Template extends Gui1Frame {
  const Gui1Template({required this.skillId, required this.template, required this.data, required this.sessionId});

  final String skillId;
  final String template;
  final Json data;
  final String sessionId;
}

/// [data] is the namespace's full merged data after the change, never a delta.
class Gui1SessionUpdate extends Gui1Frame {
  const Gui1SessionUpdate({required this.skillId, required this.data, required this.sessionId});

  final String skillId;
  final Json data;
  final String sessionId;
}

class Gui1Activated extends Gui1Frame {
  const Gui1Activated({required this.skillId, required this.sessionId});

  final String skillId;
  final String sessionId;
}

class Gui1Deactivated extends Gui1Frame {
  const Gui1Deactivated({required this.skillId, required this.sessionId});

  final String skillId;
  final String sessionId;
}

/// The device's stack is empty; device-wide, so it carries no session.
class Gui1Idle extends Gui1Frame {
  const Gui1Idle();
}

/// A bus topic forwarded as is, to every client, with the session it came from.
class Gui1Status extends Gui1Frame {
  const Gui1Status({required this.eventName, required this.data, required this.sessionId});

  final String eventName;
  final Json data;
  final String sessionId;
}

class Gui1StackEntry {
  const Gui1StackEntry({required this.skillId, required this.template, required this.data});

  final String skillId;

  /// Null while the namespace has data but no template yet.
  final String? template;
  final Json data;
}

/// The session's whole stack, index 0 the active namespace; empty means idle.
class Gui1Snapshot extends Gui1Frame {
  const Gui1Snapshot({required this.sessionId, required this.stack});

  final String sessionId;
  final List<Gui1StackEntry> stack;
}

/// One server frame; a frame of an unknown type or with a missing or mistyped field throws [Gui1FrameException].
Gui1Frame parseGui1Frame(Json frame) {
  final type = frame['type'];
  final parse = _parsers[type];
  if (parse == null) throw Gui1FrameException(frame, 'unknown frame type $type');
  try {
    return parse(frame);
  } on TypeError catch (cause) {
    throw Gui1FrameException(frame, '$cause');
  }
}

final Map<String, Gui1Frame Function(Json)> _parsers = {
  'welcome': (f) => Gui1Welcome(
    protocol: f['protocol'] as String,
    version: f['version'] as int,
    sessionId: f['session_id'] as String,
    server: f['server'] as String,
  ),
  'error': (f) => Gui1Error(f['reason'] as String),
  'template': (f) => Gui1Template(
    skillId: f['skill_id'] as String,
    template: f['template'] as String,
    data: _data(f),
    sessionId: f['session_id'] as String,
  ),
  'session_update': (f) =>
      Gui1SessionUpdate(skillId: f['skill_id'] as String, data: _data(f), sessionId: f['session_id'] as String),
  'activated': (f) => Gui1Activated(skillId: f['skill_id'] as String, sessionId: f['session_id'] as String),
  'deactivated': (f) => Gui1Deactivated(skillId: f['skill_id'] as String, sessionId: f['session_id'] as String),
  'idle': (_) => const Gui1Idle(),
  'status': (f) => Gui1Status(eventName: f['event_name'] as String, data: _data(f), sessionId: f['session_id'] as String),
  'snapshot': (f) =>
      Gui1Snapshot(sessionId: f['session_id'] as String, stack: [for (final entry in f['stack'] as List) _entry(entry as Json)]),
};

Gui1StackEntry _entry(Json e) =>
    Gui1StackEntry(skillId: e['skill_id'] as String, template: e['template'] as String?, data: _data(e));

Json _data(Json f) => Json.of(f['data'] as Json);

class Gui1FrameException extends FormatException {
  Gui1FrameException(Json frame, String cause) : super('malformed GUI-1 frame: $cause', frame);
}
