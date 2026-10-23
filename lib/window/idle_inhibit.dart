import 'plugin_calls.dart';

/// The session-bus calls an idle inhibit needs: package:dbus in the app (idle_inhibit_dbus_io.dart), a fake in tests.
abstract interface class InhibitBus {
  /// org.freedesktop.ScreenSaver.Inhibit; the cookie [screenSaverUnInhibit] takes back.
  Future<int> screenSaverInhibit(String appName, String reason);

  Future<void> screenSaverUnInhibit(int cookie);

  /// org.freedesktop.portal.Inhibit with the idle flag; the request handle [portalRelease] closes.
  Future<String> portalInhibit(String reason);

  Future<void> portalRelease(String handle);
}

const inhibitAppName = 'ovos-gui-visage';
const inhibitReason = 'Kiosk mode keeps the display awake';

/// Keeps the Linux display from blanking while kiosk mode lasts. The ScreenSaver service answers on Plasma; the
/// desktop portal is the fallback. A step that fails is reported once and the kiosk carries on: the display may
/// blank, but it is never silent about it. Holds and releases run in order, so a quick toggle cannot leak a cookie.
class IdleInhibitor {
  IdleInhibitor(this._bus);

  final InhibitBus _bus;
  Future<void> _last = Future.value();
  Future<void> Function()? _undo;

  bool get held => _undo != null;

  Future<void> hold() => _last = _last.then((_) => _hold());

  Future<void> release() => _last = _last.then((_) => _release());

  Future<void> _hold() async {
    if (_undo != null) return;
    _undo = await _screenSaver() ?? await _portal();
  }

  Future<Future<void> Function()?> _screenSaver() async {
    final cookie = await attemptPluginCall(
      'keeping the display awake through org.freedesktop.ScreenSaver; trying the desktop portal',
      () => _bus.screenSaverInhibit(inhibitAppName, inhibitReason),
    );
    return cookie == null ? null : () => _bus.screenSaverUnInhibit(cookie);
  }

  Future<Future<void> Function()?> _portal() async {
    final handle = await attemptPluginCall(
      'keeping the display awake through org.freedesktop.portal.Inhibit; the display may blank in kiosk mode',
      () => _bus.portalInhibit(inhibitReason),
    );
    return handle == null ? null : () => _bus.portalRelease(handle);
  }

  Future<void> _release() async {
    final undo = _undo;
    _undo = null;
    if (undo != null) await attemptPluginCall('releasing the kiosk idle inhibit', undo);
  }
}
