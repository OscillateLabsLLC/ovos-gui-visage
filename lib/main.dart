// App shell: connects to OVOS, hosts the current page in the 480 x 800 frame scaled to the window, and overlays the
// face for listen/think/speak (full over idle, compact badge over content pages, SPEC 5.3).
import 'package:flutter/material.dart';

import 'attention.dart';
import 'face/face.dart';
import 'face/face_theme.dart';
import 'face/visage_theme.dart';
import 'pages/router.dart';
import 'protocol/core_bus.dart';
import 'protocol/gui_client.dart';
import 'state/gui_state.dart';
import 'theme.dart';
import 'widgets/widget_manager.dart';

const _pageBg = VisageColors.pageBg;
const _dimBg = Color(0xEB05070A);
const _badgeDisc = Color(0xEB141B24);
const _badgeHeight = 104.0;
const _badgeGap = 7.0;

/// Content pages keep this much of the bottom free for the badge (SPEC 5.3: badge plus a 7 px gap above and below).
const _attentionStrip = _badgeHeight + 2 * _badgeGap;

void main() => runApp(const VisageApp());

class VisageApp extends StatelessWidget {
  const VisageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: VisageColors.bg,
        child: Center(child: Screen()),
      ),
    );
  }
}

class Screen extends StatefulWidget {
  const Screen({super.key});

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  final state = GuiState();
  final face = FaceController();
  late final Attention attention = Attention(face);
  late final CoreBus bus = CoreBus(log: _log);
  late final WidgetManager widgets = WidgetManager(bus, log: _log);
  late final GuiClient gui = GuiClient(
    bus: bus,
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
    widgets;
    bus.start();
    gui.start();
  }

  @override
  void dispose() {
    attention.dispose();
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

  void _refresh() {
    if (!mounted) return;
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
    return FittedBox(
      child: SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
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
              if (!guiConnected) const _OfflinePill(),
            ],
          ),
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
    final geometry = const VisageTheme().geometry;
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
            child: Stack(
              children: [
                if (attention.compact)
                  Positioned.fill(child: CustomPaint(painter: _DiscPainter(geometry.centre, geometry.badgeRadius))),
                Face(controller: face),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  _DiscPainter(this.centre, this.radius);

  final Offset centre;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(centre, radius, Paint()..color = _badgeDisc);

  @override
  bool shouldRepaint(_DiscPainter old) => old.centre != centre || old.radius != radius;
}

class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF3A1D1D), borderRadius: BorderRadius.circular(10)),
          child: const Text('GUI offline', style: TextStyle(color: Color(0xFFFFB4B4), fontSize: 12)),
        ),
      ),
    );
  }
}
