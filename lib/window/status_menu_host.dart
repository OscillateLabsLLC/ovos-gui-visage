/// Draws the status menu natively and hands back the id of a selected item; the web build has no menu bar.
library;

export 'status_menu_host_stub.dart' if (dart.library.io) 'status_menu_host_io.dart';
