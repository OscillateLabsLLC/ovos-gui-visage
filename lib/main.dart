// App shell: connects to OVOS, hosts the current page in the 480 x 800 frame scaled to the window, and overlays the
// face for listen/think/speak (full over idle, compact badge over content pages, SPEC 5.3). The face is switchable
// while running, over the bus (face_remote.dart) and by hand on the screen (try_on.dart). A peeking widget shows only
// the badge until the face is shown (window/peek.dart), and the window follows over the bus (window_remote.dart).
import 'dart:async';

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'attention.dart';
import 'captions.dart';
import 'face/face.dart';
import 'face/face_remote.dart';
import 'face/face_scope.dart';
import 'face/face_theme.dart';
import 'face/try_on.dart';
import 'faults.dart';
import 'outcome.dart';
import 'pages/router.dart';
import 'protocol/core_bus.dart';
import 'protocol/endpoints.dart';
import 'protocol/gui_client.dart';
import 'state/gui_state.dart';
import 'theme.dart';
import 'turn_feed.dart';
import 'widgets/caption_strip.dart';
import 'widgets/notification_popups.dart';
import 'widgets/notification_stack.dart';
import 'widgets/offline_pill.dart';
import 'widgets/outcome_pill.dart';
import 'widgets/widget_manager.dart';
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
import 'window/window_surface.dart';

const _pageBg = VisageColors.pageBg;
const _effects = WindowEffects(mode: setWindowMode, visible: setWindowVisible, place: setWidgetExpanded);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logFaultsPlainly();
  final config = await loadAppConfig();
  await applyWindowConfig(config.window);
  runApp(VisageApp(config: config));
}

/// The browser tab and the task switcher show this; without it Flutter web blanks the page title.
const appTitle = 'OVOS Visage';

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
  late final StatusMenuController menu = bindStatusMenu(
    face: remote,
    faceController: face,
    window: window,
    show: _showMenu,
    quit: quitApp,
  );
  late bool windowExpanded;
  late WindowMode windowMode = widget.config.window.mode;
  late final GuiClient gui = GuiClient(
    bus: bus,
    guiUrlOverride: sockets.gui,
    guiId: 'ovos-gui-visage-${DateTime.now().millisecondsSinceEpoch % 100000}',
    onMessage: _onGuiMessage,
    onStatus: _onGuiStatus,
    log: _log,
  );
  bool guiConnected = false;
  Target? lastFocus;

  void _log(String line) => debugPrint(line);

  /// The macOS menu bar item and the Linux tray item show the same list; each ignores the other platform.
  void _showMenu(List<MenuEntry> items) {
    menuHost.show(items);
    unawaited(tray.show(items));
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
    bindTurnFeed(bus, {captions.handle: captionEvents, outcome.handle: outcomeEvents});
    windowExpanded = peek.expanded;
    peek.addListener(_onPeek);
    widgets;
    remote;
    window.addListener(_onWindow);
    menu;
    drag.attach();
    bus.start();
    gui.start();
  }

  @override
  void dispose() {
    menu.dispose();
    drag.dispose();
    tray.dispose();
    face.removeListener(_refresh);
    attention.dispose();
    captions.dispose();
    outcome.dispose();
    popups.dispose();
    peek.dispose();
    gui.stop();
    bus.stop();
    super.dispose();
  }

  void _onGuiMessage(Json message) {
    if (!state.apply(message)) _log('unknown GUI message $message');
    if (message['type'] == 'mycroft.events.triggered' && message['namespace'] == systemNamespace) {
      attention.handle(message['event_name'] as String, (message['data'] ?? <String, dynamic>{}) as Json);
    }
    _refresh();
  }

  void _onGuiStatus(bool connected) {
    state.reset();
    lastFocus = null;
    guiConnected = connected;
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
    if (target != null && target != lastFocus) {
      lastFocus = target;
      gui.send(focusMessage(target.namespace, target.index));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !peek.expanded;
    return WindowSurface(
      mode: window.config.mode,
      onLeaveKiosk: window.leaveKiosk,
      onDragStart: tryOnActive ? null : drag.start,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: collapsed,
            child: TickerMode(
              enabled: !collapsed,
              child: FittedBox(child: _frame()),
            ),
          ),
          if (collapsed) PeekBadge(face: face, onTap: peek.tap),
        ],
      ),
    );
  }

  Widget _frame() {
    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: FaceScope(
          controller: face,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _pageBg)),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, attention.compact ? attentionStrip : 32),
                  child: PageHost(state: state, send: gui.send),
                ),
              ),
              AttentionOverlay(attention: attention, face: face),
              if (widget.config.captions) CaptionStrip(captions: captions, compact: attention.compact),
              _topStatus(),
              FaceTryOn(controller: face, remote: remote, enabled: peek.expanded, onActive: _onTryOn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topStatus() => TopStatus(
    children: [
      if (!guiConnected) const OfflinePill(),
      OutcomePill(outcome: outcome.showing),
      if (popups.all.isNotEmpty) NotificationStack(popups: popups.all),
    ],
  );
}
