import 'package:ovos_gui_visage/window/idle_inhibit.dart';

/// Records every inhibit call; a service set to fail throws as a missing D-Bus name would.
class FakeInhibitBus implements InhibitBus {
  FakeInhibitBus({this.screenSaverFails = false, this.portalFails = false});

  bool screenSaverFails;
  bool portalFails;
  bool unInhibitFails = false;
  final calls = <String>[];
  var _nextCookie = 41;

  @override
  Future<int> screenSaverInhibit(String appName, String reason) async {
    calls.add('screenSaver.Inhibit($appName)');
    if (screenSaverFails) throw StateError('org.freedesktop.ScreenSaver was not provided by any .service files');
    return ++_nextCookie;
  }

  @override
  Future<void> screenSaverUnInhibit(int cookie) async {
    calls.add('screenSaver.UnInhibit($cookie)');
    if (unInhibitFails) throw StateError('cookie $cookie is unknown');
  }

  @override
  Future<String> portalInhibit(String reason) async {
    calls.add('portal.Inhibit');
    if (portalFails) throw StateError('No such interface org.freedesktop.portal.Inhibit');
    return '/org/freedesktop/portal/desktop/request/1_1/t';
  }

  @override
  Future<void> portalRelease(String handle) async => calls.add('portal.Close($handle)');
}
