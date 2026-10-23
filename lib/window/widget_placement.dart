import 'window_config.dart';

/// The display system the native window is on, as the Linux runner reads it from GDK (linux/runner/window_channel.cc).
/// macOS and the web report [other], since they place their windows as asked.
enum DisplayBackend {
  x11,
  wayland,
  other;

  /// A name the runner does not know is [other]: the app behaves as it did before it could ask.
  static DisplayBackend named(String? name) => values.firstWhere((b) => b.name == name, orElse: () => other);
}

/// Why a widget on native Wayland stays where the compositor puts it (measured on KWin 5.27 and labwc 0.7.1, issue #13).
const waylandWidgetFault =
    'the corner widget modes on native Wayland: an app cannot place its own window there or keep it above or below '
    'other windows, so a float or desktop widget sits where the compositor puts it and drag-to-corner is off. '
    'The app prefers X11 when Xwayland is available; install Xwayland, or use window or kiosk mode';

/// Whether the corner widget can be placed and stacked on [backend], and the one report when it cannot. Native Wayland
/// accepts the position and keep-above calls and ignores them, so the app must say so itself.
class WidgetPlacement {
  WidgetPlacement(this.backend);

  final DisplayBackend backend;
  bool _reported = false;

  /// False on native Wayland: no corner, no keep-above or keep-below, and no window position to read after a drag.
  bool get placesWidgets => backend != DisplayBackend.wayland;

  /// A drop is snapped to a corner and the corner saved only where the window's position can be read back.
  bool get snapsAfterDrag => placesWidgets;

  /// True once per run, the first time a widget mode runs where it cannot be placed.
  bool takeReport(WindowConfig config) {
    if (placesWidgets || !config.isWidget || _reported) return false;
    _reported = true;
    return true;
  }
}
