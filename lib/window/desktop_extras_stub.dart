import 'status_menu.dart';
import 'window_config.dart';

/// No tray on the web.
class TrayHost {
  TrayHost({required this.onSelected});

  final void Function(String id) onSelected;

  Future<void> show(List<MenuEntry> items) async {}

  void dispose() {}
}

/// No window to drag on the web.
class WindowDrag {
  WindowDrag({required this.config, required this.onCorner});

  final WindowConfig Function() config;
  final void Function(Corner corner) onCorner;

  void attach() {}

  void start() {}

  void dispose() {}
}
