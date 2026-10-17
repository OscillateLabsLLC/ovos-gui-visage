/// Client mirror of ovos-gui state (ovos-visage SPEC 6): namespaces, pages, session data and the active-skill stack.
///
/// This is a port of ovos_visage/state.py. The Python reference's snapshots for every recorded fixture live in
/// test/fixtures/expected; the replay test requires this model to produce the same ones.
library;

import '../json.dart';

export '../json.dart';

const activeSkills = 'mycroft.system.active_skills';
const systemNamespace = 'system';
const defaultIdleNamespace = 'ovos-skill-homescreen.openvoiceos';
const focusEvent = 'page_gained_focus';

class Namespace {
  Namespace(this.skillId);

  final String skillId;
  List<String> pages = [];
  Json data = {};
  int focusedIndex = 0;
  Json events = {};

  void clearPages() {
    pages = [];
    focusedIndex = 0;
  }

  Json toJson() => {
        'skill_id': skillId,
        'pages': List.of(pages),
        'data': data,
        'focused_index': focusedIndex,
        'events': events,
      };
}

/// The (namespace, page, index) the screen shows.
class Target {
  const Target(this.namespace, this.page, this.index);

  final String namespace;
  final String page;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is Target && other.namespace == namespace && other.page == page && other.index == index;

  @override
  int get hashCode => Object.hash(namespace, page, index);

  @override
  String toString() => '$namespace/$page[$index]';
}

class GuiState {
  GuiState({this.idleNamespace = defaultIdleNamespace});

  final String idleNamespace;
  final Map<String, Namespace> namespaces = {};
  final List<String> active = [];
  String? _lastActiveInsert;

  void reset() {
    _lastActiveInsert = null;
    namespaces.clear();
    active.clear();
  }

  Namespace namespace(String skillId) => namespaces.putIfAbsent(skillId, () => Namespace(skillId));

  /// Applies one GUI protocol message; false for an unknown or malformed one (the caller logs the payload).
  bool apply(Json message) {
    final handler = _handlers[message['type']];
    if (handler == null) return false;
    try {
      handler(message);
    } on Object {
      return false;
    }
    return true;
  }

  /// The first active namespace with pages, else the idle namespace's page; a skill enters `active` before its page
  /// arrives, so stopping at active[0] would flash idle in between.
  Target? current() {
    for (final skillId in [...active, idleNamespace]) {
      final ns = namespaces[skillId];
      if (ns == null || ns.pages.isEmpty) continue;
      final index = ns.focusedIndex.clamp(0, ns.pages.length - 1);
      return Target(skillId, ns.pages[index], index);
    }
    return null;
  }

  Json snapshot() => {
        'active': List.of(active),
        'idle_namespace': idleNamespace,
        'namespaces': {for (final entry in namespaces.entries) entry.key: entry.value.toJson()},
      };

  late final Map<String, void Function(Json)> _handlers = {
    'mycroft.session.set': _sessionSet,
    'mycroft.session.delete': _sessionDelete,
    'mycroft.session.list.insert': _listInsert,
    'mycroft.session.list.update': _listUpdate,
    'mycroft.session.list.move': _listMove,
    'mycroft.session.list.remove': _listRemove,
    'mycroft.gui.list.insert': _pagesInsert,
    'mycroft.gui.list.move': _pagesMove,
    'mycroft.gui.list.remove': _pagesRemove,
    'mycroft.events.triggered': _event,
  };

  void _sessionSet(Json m) => namespace(m['namespace']).data.addAll(m['data'] as Json);

  void _sessionDelete(Json m) => namespace(m['namespace']).data.remove(m['property']);

  List<dynamic> _sessionList(Json m) => namespace(m['namespace']).data[m['property']] as List;

  void _listInsert(Json m) {
    if (m['namespace'] == activeSkills) {
      final ids = [for (final item in m['data'] as List) item['skill_id'] as String];
      active.insertAll(m['position'] as int, ids);
      _lastActiveInsert = ids.isEmpty ? null : ids.last;
      return;
    }
    final data = namespace(m['namespace']).data;
    final items = data.putIfAbsent(m['property'], () => <dynamic>[]) as List;
    items.insertAll(m['position'] as int, m['values'] as List);
  }

  void _listUpdate(Json m) {
    final items = _sessionList(m);
    final position = m['position'] as int;
    final values = m['values'] as List;
    items.replaceRange(position, position + values.length, values);
  }

  void _listMove(Json m) {
    final items = m['namespace'] == activeSkills ? active : _sessionList(m);
    _move(items, m['from'] as int, m['to'] as int, (m['items_number'] ?? 1) as int);
  }

  void _listRemove(Json m) {
    final count = (m['items_number'] ?? 1) as int;
    if (m['namespace'] != activeSkills) {
      _remove(_sessionList(m), m['position'] as int, count);
      return;
    }
    // ovos-gui drops a removed namespace's pages without sending gui.list.remove.
    for (final skillId in _remove(active, m['position'] as int, count)) {
      namespace(skillId).clearPages();
    }
  }

  void _pagesInsert(Json m) {
    final skillId = m['namespace'] as String;
    final ns = namespace(skillId);
    final index = active.indexOf(skillId);
    // ovos-gui moves an active namespace to the front before loading its pages, but only tells clients when it
    // already had pages, so later positional ops would miss.
    if (ns.pages.isEmpty && index > 0 && skillId != _lastActiveInsert) _move(active, index, 0, 1);
    ns.pages.insertAll(m['position'] as int, [for (final item in m['data'] as List) item['page'] as String]);
  }

  void _pagesMove(Json m) =>
      _move(namespace(m['namespace']).pages, m['from'] as int, m['to'] as int, (m['items_number'] ?? 1) as int);

  void _pagesRemove(Json m) {
    final ns = namespace(m['namespace']);
    _remove(ns.pages, m['position'] as int, (m['items_number'] ?? 1) as int);
    ns.focusedIndex = ns.focusedIndex.clamp(0, ns.pages.isEmpty ? 0 : ns.pages.length - 1);
  }

  void _event(Json m) {
    final skillId = m['namespace'] as String;
    if (skillId == systemNamespace) return;
    final data = (m['data'] ?? <String, dynamic>{}) as Json;
    if (m['event_name'] == focusEvent) {
      namespace(skillId).focusedIndex = (data['number'] as num).toInt();
    } else {
      namespace(skillId).events[m['event_name'] as String] = data;
    }
  }
}

List<T> _remove<T>(List<T> items, int position, int count) {
  final end = (position + count).clamp(0, items.length);
  final removed = items.sublist(position, end);
  items.removeRange(position, end);
  return removed;
}

void _move<T>(List<T> items, int from, int to, int count) => items.insertAll(to, _remove(items, from, count));
