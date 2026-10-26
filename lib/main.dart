// App shell: connects to OVOS, hosts the current page in the 480 x 800 frame scaled to the window, and overlays the face
// for listen/think/speak (full over idle, compact badge over content pages, SPEC 5.3). The face is switchable over the
// bus (face_remote.dart) and on the screen (try_on.dart). A peeking widget shows only the badge until the face is shown
// (window/peek.dart); the window follows the bus (window_remote.dart). Pages answer back; a command can be typed.
import 'dart:async';

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'attention.dart';
import 'captions.dart';
import 'face/face.dart';
import 'face/face_remote.dart';
import 'faults.dart';
import 'frame_log.dart';
import 'outcome.dart';
import 'protocol/core_bus.dart';
import 'protocol/endpoints.dart';
import 'protocol/gui_link.dart';
import 'screen_frame.dart';
import 'screen_input.dart';
import 'state/gui_state.dart';
import 'turn_feed.dart';
import 'volume.dart';
import 'volume_controls.dart';
import 'widgets/notification_actions.dart';
import 'widgets/notification_popups.dart';
import 'widgets/widget_manager.dart';
import 'screen_link.dart';
import 'shell_overlays.dart';
import 'window/desktop_extras.dart';
import 'window/face_picker.dart';
import 'window/peek.dart';
import 'window/status_menu.dart';
import 'window/status_menu_binding.dart';
import 'window/status_menu_host.dart';
import 'window/window_config.dart';
import 'window/window_remote.dart';
import 'window/window_shell.dart';
import 'window/window_title.dart';
import 'window/window_menu.dart';
import 'window/window_surface.dart';

const _effects = WindowEffects(mode: setWindowMode, visible: setWindowVisible, place: setWidgetExpanded);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logFaultsPlainly();
  final config = await loadAppConfig();
  if (config.frameLog) startFrameLog(debugPrint);
  await applyWindowConfig(config.window);
  runApp(VisageApp(config: config));
}

class VisageApp extends StatelessWidget {
  const VisageApp({super.key, this.config = const AppConfig()});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: Center(child: Screen(config: config)),
      ),
    );
  }
}

class Screen extends StatefulWidget {
  const Screen({super.key, this.config = const AppConfig()});

  final AppConfig config;

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  final state = GuiState();
  late final face = FaceController(theme: widget.config.face.theme());
  late final Attention attention = Attention(face);
  final sockets = endpoints();
  late final CoreBus bus = CoreBus(url: sockets.core.toString(), log: _log);
  late final NotificationPopups popups = NotificationPopups(onExpired: (record) => widgets.popClear(record));
  late final WidgetManager widgets = WidgetManager(bus, log: _log, popups: popups);
  late final NotificationActions notifications = NotificationActions(bus: bus, popups: popups);
  final captions = Captions();
  final outcome = OutcomeModel();
  late final FaceRemote remote = FaceRemote(
    bus,
    face,
    initial: widget.config.face,
    persist: saveFaceConfig,
    picker: () => openFacePicker(sockets.core),
    log: _log,
  );
  late final PeekController peek = PeekController(enabled: widget.config.window.peeks);
  late final ScreenVolume volume = ScreenVolume(bus: bus, peek: peek);
  late final WindowRemote window = WindowRemote(
    bus,
    peek,
    initial: widget.config.window,
    persist: saveWindowConfig,
    effects: _effects,
    log: _log,
  );
  late final StatusMenuHost menuHost = StatusMenuHost(onSelected: (id) => menu.dispatch(id));
  late final TrayHost tray = TrayHost(onSelected: (id) => menu.dispatch(id));
  late final WindowDrag drag = WindowDrag(config: () => window.config, onCorner: window.setCorner);
  bool tryOnActive = false;
  late final ScreenInput input = ScreenInput(
    state: state,
    bus: bus,
    sendGui: (message) => gui.send(message),
    requestFocus: (namespace, page) => gui.requestFocus(namespace, page),
    peek: peek,
    window: window,
    dispatchMenu: (id) => menu.dispatch(id),
    onChanged: _refresh,
    storage: widgets.stored,
    lang: widget.config.lang,
  );
  late final StatusMenuController menu = bindStatusMenu(
    face: remote,
    faceController: face,
    window: window,
    volume: volume.model,
    volumeControls: volume.controls,
    show: _showMenu,
    typeCommand: () => input.typeCommand(),
    quit: quitApp,
    protocol: gui.title,
  );
  late bool windowExpanded;
  late WindowMode windowMode = widget.config.window.mode;
  late final GuiLink gui = screenLink(
    config: widget.config,
    sockets: sockets,
    bus: bus,
    state: state,
    attention: attention,
    onChanged: _refresh,
    onStatus: _onGuiStatus,
    log: _log,
  );
  bool guiConnected = false;
  late final FocusAnnouncer focus = FocusAnnouncer(gui);

  void _log(String line) => debugPrint(line);

  /// The macOS menu bar item and the Linux tray item show the same list; each ignores the other platform. The window's
  /// own menu shows it everywhere.
  void _showMenu(List<MenuEntry> items) {
    menuHost.show(items);
    unawaited(tray.show(items));
    input.menu.show(items);
  }

  /// Try-on mode owns the gestures while it is active, so the widget cannot be dragged then.
  void _onTryOn(bool active) {
    tryOnActive = active;
    peek.hold(active);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    attention.addListener(_refresh);
    face.addListener(_refresh);
    captions.addListener(_refresh);
    outcome.addListener(_refresh);
    popups.addListener(_refresh);
    input.notificationList.addListener(_refresh);
    volume.model.addListener(_refresh);
    bindTurnFeed(bus, {captions.handle: captionEvents, outcome.handle: outcomeEvents, volume.model.handle: volumeEvents});
    windowExpanded = peek.expanded;
    peek.addListener(_onPeek);
    widgets;
    remote;
    window.addListener(_onWindow);
    menu;
    drag.attach();
    bindWindowTitle(gui, window, setWindowTitle);
    bus.start();
    gui.start();
  }

  @override
  void dispose() {
    menu.dispose();
    input.dispose();
    drag.dispose();
    tray.dispose();
    face.removeListener(_refresh);
    attention.dispose();
    captions.dispose();
    outcome.dispose();
    popups.dispose();
    volume.dispose();
    peek.dispose();
    gui.stop();
    bus.stop();
    super.dispose();
  }

  void _onGuiStatus(bool connected) {
    state.reset();
    focus.reset();
    guiConnected = connected;
    if (connected) volume.model.requestLevel();
    _refresh();
  }

  void _onPeek() {
    if (peek.expanded != windowExpanded) {
      windowExpanded = peek.expanded;
      _log('peek: window ${windowExpanded ? 'expands' : 'collapses'}');
      // During a mode switch the mode effect places the window; a second, animated resize would race it.
      if (window.config.mode == windowMode) unawaited(setWidgetExpanded(window.config, expanded: windowExpanded));
    }
    if (mounted) setState(() {});
  }

  void _onWindow() {
    windowMode = window.config.mode;
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    peek.attention(attention.shown);
    final target = state.current();
    attention.setCompact(isContentPage(target, state.idleNamespace));
    input.syncNotificationList();
    focus.update(target);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !peek.expanded;
    final mode = window.config.mode;
    return WindowSurface(
      mode: mode,
      onLeaveKiosk: window.leaveKiosk,
      onDragStart: tryOnActive ? null : drag.start,
      onMenu: tryOnActive ? null : input.menu.open,
      onDismiss: input.dismiss,
      onStep: input.step,
      onVolume: volume.controls.act,
      child: WindowMenu(
        host: input.menu,
        ready: !collapsed,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: collapsed,
              child: TickerMode(
                enabled: !collapsed,
                child: FittedBox(child: ScreenFrame(parts: _parts(mode))),
              ),
            ),
            if (collapsed) PeekBadge(face: face, onTap: peek.tap),
          ],
        ),
      ),
    );
  }

  FrameParts _parts(WindowMode mode) => FrameParts(
    state: state,
    attention: attention,
    face: face,
    remote: remote,
    commands: input.commands,
    send: gui.send,
    connected: guiConnected,
    protocol: gui.chosen,
    captions: widget.config.captions ? captions : null,
    outcome: outcome,
    volume: volume.model,
    popups: popups,
    notifications: notifications,
    notificationList: input.notificationList,
    listShown: input.notificationList.isOpen,
    expanded: peek.expanded,
    kiosk: mode == WindowMode.kiosk,
    typeOnHome: mode == WindowMode.window || mode == WindowMode.kiosk,
    input: input,
    onTryOn: _onTryOn,
  );
}
