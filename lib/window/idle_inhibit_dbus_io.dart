import 'package:dbus/dbus.dart';

import 'idle_inhibit.dart';

const _portalIdleFlag = 8;

/// [InhibitBus] on the session bus. The connection opens on the first inhibit and stays open: the ScreenSaver
/// service and the portal both drop an inhibit when its caller leaves the bus, which is also what releases it if the
/// process dies without quitting.
class DBusInhibitBus implements InhibitBus {
  DBusClient? _client;

  DBusClient get _bus => _client ??= DBusClient.session();

  @override
  Future<int> screenSaverInhibit(String appName, String reason) async {
    final reply = await _screenSaver('Inhibit', [DBusString(appName), DBusString(reason)], DBusSignature('u'));
    return reply.returnValues.single.asUint32();
  }

  @override
  Future<void> screenSaverUnInhibit(int cookie) => _screenSaver('UnInhibit', [DBusUint32(cookie)], DBusSignature(''));

  Future<DBusMethodSuccessResponse> _screenSaver(String name, List<DBusValue> values, DBusSignature reply) => _bus.callMethod(
    destination: 'org.freedesktop.ScreenSaver',
    path: DBusObjectPath('/ScreenSaver'),
    interface: 'org.freedesktop.ScreenSaver',
    name: name,
    values: values,
    replySignature: reply,
  );

  @override
  Future<String> portalInhibit(String reason) async {
    final reply = await _bus.callMethod(
      destination: 'org.freedesktop.portal.Desktop',
      path: DBusObjectPath('/org/freedesktop/portal/desktop'),
      interface: 'org.freedesktop.portal.Inhibit',
      name: 'Inhibit',
      values: [
        const DBusString(''),
        const DBusUint32(_portalIdleFlag),
        DBusDict.stringVariant({'reason': DBusString(reason)}),
      ],
      replySignature: DBusSignature('o'),
    );
    return reply.returnValues.single.asObjectPath().value;
  }

  @override
  Future<void> portalRelease(String handle) => _bus.callMethod(
    destination: 'org.freedesktop.portal.Desktop',
    path: DBusObjectPath(handle),
    interface: 'org.freedesktop.portal.Request',
    name: 'Close',
    replySignature: DBusSignature(''),
  );
}
