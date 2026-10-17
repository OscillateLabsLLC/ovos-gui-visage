/// (namespace, page) -> page widget, keyed by exact name so adding a template is one entry and one file (SPEC 8.2).
/// System templates are shown in the calling skill's own namespace, so they route by page name alone.
library;

import 'package:flutter/widgets.dart';

import '../state/gui_state.dart';
import 'blank_page.dart';
import 'fallback_page.dart';
import 'page.dart';

const routes = <String, PageBuilder>{};

const templates = <String, PageBuilder>{};

PageBuilder resolve(Target? target) {
  if (target == null) return (_, _) => const BlankPage();
  return routes['${target.namespace}/${target.page}'] ?? templates[target.page] ?? FallbackPage.page;
}

/// Hosts the current page. A new (namespace, page, index) replaces the subtree, so page state resets; the same
/// target with new data rebuilds the same widget, so a page keeps its tickers and animations across updates.
class PageHost extends StatelessWidget {
  const PageHost({super.key, required this.state});

  final GuiState state;

  @override
  Widget build(BuildContext context) {
    final target = state.current();
    final ns = target == null ? null : state.namespace(target.namespace);
    final ctx = PageContext(namespace: target?.namespace ?? '', page: target?.page ?? '', events: ns?.events ?? const {});
    final data = Json.of(ns?.data ?? const {});
    return KeyedSubtree(key: ValueKey(target?.toString() ?? ''), child: resolve(target)(data, ctx));
  }
}
