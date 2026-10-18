// App shell: connects to OVOS, hosts the current page in the 480 x 800 frame scaled to the window, and overlays the
// face for listen/think/speak (full over idle, compact badge over content pages, SPEC 5.3). The face is switchable
// while running, over the bus (face_remote.dart) and by hand on the screen (try_on.dart). A peeking widget shows only
// the badge until the face is shown (window/peek.dart), and the window follows over the bus (window_remote.dart).
import 'dart:async';

import 'package:flutter/material.dart';

import 'app_config.dart';
import 'attention.dart';
import 'face/face.dart';
import 'face/face_badge.dart';
import 'face/face_remote.dart';
import 'face/face_scope.dart';
import 'face/face_theme.dart';
import 'face/try_on.dart';
import 'pages/router.dart';
import 'protocol/core_bus.dart';
import 'protocol/endpoints.dart';
import 'protocol/gui_client.dart';
import 'state/gui_state.dart';
import 'theme.dart';
import 'widgets/offline_pill.dart';
import 'widgets/widget_manager.dart';
import 'window/face_picker.dart';
import 'window/peek.dart';
import 'window/status_menu.dart';
import 'window/status_menu_binding.dart';
import 'window/status_menu_host.dart';
import 'window/window_remote.dart';
import 'window/window_shell.dart';

const _pageBg = VisageColors.pageBg;
const _effects = WindowEffects(mode: setWindowMode, visible: setWindowVisible);
const _dimBg = Color(0xEB05070A);
const _badgeHeight = 104.0;
const _badgeGap = 7.0;

/// Content pages keep this much of the bottom free for the badge (SPEC 5.3: badge plus a 7 px gap above and below).
const _attentionStrip = _badgeHeight + 2 * _badgeGap;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await loadAppConfig();
  await applyWindowConfig(config.window);
  runApp(VisageApp(config: config));
}

class VisageApp extends StatelessWidget {
  const VisageApp({super.key, this.config = const AppConfig()});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: config.window.isWidget ? Colors.transparent : VisageColors.bg,
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
  late final WidgetManager widgets = WidgetManager(bus, log: _log);
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
  late final StatusMenuController menu = bindStatusMenu(
    face: remote,
    faceController: face,
    window: window,
    show: menuHost.show,
    quit: quitApp,
  );
  late bool windowExpanded;
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

  @override
  void initState() {
    super.initState();
    attention.addListener(_refresh);
    face.addListener(_refresh);
    windowExpanded = peek.expanded;
    peek.addListener(_onPeek);
    widgets;
    remote;
    window;
    menu;
    bus.start();
    gui.start();
  }

  @override
  void dispose() {
    menu.dispose();
    face.removeListener(_refresh);
    attention.dispose();
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
      unawaited(setWidgetExpanded(window.config, expanded: windowExpanded));
    }
    if (mounted) setState(() {});
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: collapsed,
          child: TickerMode(
            enabled: !collapsed,
            child: FittedBox(child: _frame()),
          ),
        ),
        if (collapsed) _PeekBadge(face: face, onTap: peek.tap),
      ],
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
                  padding: EdgeInsets.fromLTRB(24, 32, 24, attention.compact ? _attentionStrip : 32),
                  child: PageHost(state: state),
                ),
              ),
              _AttentionOverlay(attention: attention, face: face),
              if (!guiConnected) const OfflinePill(),
              FaceTryOn(controller: face, remote: remote, enabled: peek.expanded, onActive: peek.hold),
            ],
          ),
        ),
      ),
    );
  }
}

/// The collapsed peek window: the resting badge alone in a square frame; a tap expands it for a while.
class _PeekBadge extends StatelessWidget {
  const _PeekBadge({required this.face, required this.onTap});

  final FaceController face;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FittedBox(
        child: SizedBox.square(
          dimension: frameWidth,
          child: FaceBadge(controller: face),
        ),
      ),
    );
  }
}

/// The face over the page: full and dimming over idle, else scaled into a disc at the bottom centre (SPEC 5.3).
class _AttentionOverlay extends StatelessWidget {
  const _AttentionOverlay({required this.attention, required this.face});

  final Attention attention;
  final FaceController face;

  @override
  Widget build(BuildContext context) {
    final geometry = face.theme.geometry;
    final scale = _badgeHeight / (2 * geometry.badgeRadius);
    final badgeCentre = Offset(frameWidth / 2, frameHeight - _badgeGap - _badgeHeight / 2);
    final shift = attention.compact ? badgeCentre - geometry.centre : Offset.zero;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: attention.shown ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: attention.compact ? Colors.transparent : _dimBg,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(shift.dx, shift.dy, 0)
              ..translateByDouble(geometry.centre.dx, geometry.centre.dy, 0, 1)
              ..scaleByDouble(attention.compact ? scale : 1, attention.compact ? scale : 1, 1, 1)
              ..translateByDouble(-geometry.centre.dx, -geometry.centre.dy, 0, 1),
            child: BadgeFace(controller: face, compact: attention.compact),
          ),
        ),
      ),
    );
  }
}
