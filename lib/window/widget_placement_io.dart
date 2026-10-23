import 'dart:io';

import '../faults.dart';
import 'plugin_calls.dart';
import 'widget_placement.dart';
import 'window_channel.dart';
import 'window_config.dart';

Future<WidgetPlacement>? _placement;

/// The display backend, asked of the Linux runner once per run. macOS places its windows as asked, so it is not
/// asked; a runner that cannot answer is reported once and the app places the widget as before.
Future<WidgetPlacement> widgetPlacement() => _placement ??= _detect();

Future<WidgetPlacement> _detect() async {
  if (!Platform.isLinux) return WidgetPlacement(DisplayBackend.other);
  final name = await attemptPluginCall(
    'displayBackend from the Linux runner',
    () => windowChannel.invokeMethod<String>('displayBackend'),
  );
  return WidgetPlacement(DisplayBackend.named(name));
}

/// Reports [waylandWidgetFault] the first time [config] is a widget that the display cannot place.
Future<void> reportUnplaceableWidget(WindowConfig config) async {
  final placement = await widgetPlacement();
  if (placement.takeReport(config)) {
    reportFault(waylandWidgetFault, UnsupportedError('display backend ${placement.backend.name}'));
  }
}
