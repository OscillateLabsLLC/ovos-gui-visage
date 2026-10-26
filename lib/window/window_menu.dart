/// The menu inside the window, the third host of status_menu.dart beside the macOS menu bar item and the Linux tray, so
/// a desktop with neither (stock GNOME, a Pi, a browser tab) can still change mode, leave kiosk and quit (issue #14).
/// [WindowMenuHost] takes the controller's items like the other hosts and holds open requests; [WindowMenu] draws them
/// once the window is [WindowMenu.ready], so a collapsed peek badge expands first. The menu is plain stacked text on the
/// attention face's scrim, centred in the 480 x 800 frame (menu_rows.dart); a submenu drills in with a Back row.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../face/face_theme.dart' show frameHeight, frameWidth;
import '../theme.dart';
import '../widgets/circle.dart' show motionReduced;
import 'menu_rows.dart';
import 'status_menu.dart';

class WindowMenuHost extends ChangeNotifier {
  WindowMenuHost({required this.onSelected, required this.canQuit, this.onOpenChanged});

  final void Function(String id) onSelected;
  final bool canQuit;

  /// Told when the menu opens and closes, so a peeking window stays expanded while it is up.
  final void Function(bool open)? onOpenChanged;
  List<MenuEntry> _items = const [];
  Offset? _request;
  bool _open = false;
  bool _dismissing = false;

  List<MenuEntry> get items => _items;

  /// The position of a request that has not been shown yet; null when none is waiting.
  Offset? get pending => _request;

  void show(List<MenuEntry> items) {
    _items = windowMenuEntries(items, canQuit: canQuit);
    notifyListeners();
  }

  /// Asks for the menu at [at] in window coordinates; it opens as soon as the window can hold it.
  void open(Offset at) {
    _request = at;
    if (!_open) _setOpen(true);
    notifyListeners();
  }

  /// Escape: closes the menu, or a request still waiting for the window to grow. False when neither was open, so
  /// Escape can mean something else (leaving kiosk).
  bool dismiss() {
    if (!_open) return false;
    _request = null;
    _dismissing = true;
    notifyListeners();
    return true;
  }

  bool takeDismiss() {
    final dismissing = _dismissing;
    _dismissing = false;
    return dismissing;
  }

  Offset? take() {
    final at = _request;
    _request = null;
    return at;
  }

  void closed() {
    if (!_open) return;
    _request = null;
    _setOpen(false);
  }

  void _setOpen(bool open) {
    _open = open;
    onOpenChanged?.call(open);
  }
}

/// A peek widget grows over several frames, so a request waits until the window has held its size this long.
const menuSettle = Duration(milliseconds: 250);

/// Closing fades the menu; opening is the item cadence of its rows.
const menuFade = Duration(milliseconds: 120);

const _framePadding = EdgeInsets.symmetric(horizontal: 24, vertical: 32);

/// The scrim's name to a screen reader: a tap on it closes the menu.
const closeMenuLabel = 'Close the menu';

class WindowMenu extends StatefulWidget {
  const WindowMenu({super.key, required this.host, required this.child, this.ready = true});

  final WindowMenuHost host;
  final Widget child;

  /// False while the window is a collapsed peek badge, which has no room for a menu; a request waits for the expansion.
  final bool ready;

  @override
  State<WindowMenu> createState() => _WindowMenuState();
}

class _WindowMenuState extends State<WindowMenu> {
  Size _size = Size.zero;
  bool _settled = false;
  Timer? _settle;
  bool _shown = false;
  bool _fading = false;

  /// The submenus drilled into, outermost first, by entry id.
  List<String> _path = const [];
  int _focus = -1;

  @override
  void initState() {
    super.initState();
    widget.host.addListener(_changed);
  }

  @override
  void didUpdateWidget(WindowMenu old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  @override
  void dispose() {
    widget.host.removeListener(_changed);
    _settle?.cancel();
    super.dispose();
  }

  void _changed() {
    if (widget.host.takeDismiss()) _close();
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  /// The request's position stays with the host for the tray hosts; this menu always sits in the frame's centre.
  void _openPending() {
    if (!mounted || !widget.ready || !_settled || widget.host.pending == null) return;
    widget.host.take();
    setState(() {
      _shown = true;
      _fading = false;
      _goTo(const []);
    });
  }

  void _close() {
    if (_shown && mounted) {
      setState(() {
        _shown = false;
        _fading = !motionReduced(context);
      });
    }
    widget.host.closed();
  }

  /// Shows the level [path] reaches, with nothing focused.
  void _goTo(List<String> path) {
    _path = path;
    _focus = -1;
  }

  void _resized(Size size) {
    _size = size;
    _settled = false;
    _settle?.cancel();
    _settle = Timer(menuSettle, () {
      _settled = true;
      _openPending();
    });
  }

  void _activate(MenuEntry entry) {
    if (entry == backEntry) return _back();
    if (entry.children.isNotEmpty) return setState(() => _goTo([..._path, entry.id]));
    _close();
    widget.host.onSelected(entry.id);
  }

  void _back() => setState(() => _goTo(_path.sublist(0, _path.length - 1)));

  KeyEventResult _key(KeyEvent event, List<MenuEntry> rows) {
    if (!_shown || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      setState(() => _focus = nextFocus(rows, _focus, key == LogicalKeyboardKey.arrowDown ? 1 : -1));
    } else if (_selectKeys.contains(key)) {
      if (_focus >= 0) _activate(rows[_focus]);
    } else if (_path.isNotEmpty && (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.arrowLeft)) {
      _back();
    } else if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key != LogicalKeyboardKey.arrowLeft && key != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.biggest != _size) _resized(constraints.biggest);
        return Stack(fit: StackFit.expand, children: [widget.child, if (_shown || _fading) _overlay(context)]);
      },
    );
  }

  /// The scrim over the window, and the level centred in a box the frame's size, scaled as the frame is.
  Widget _overlay(BuildContext context) {
    final level = menuLevel(widget.host.items, _path);
    return IgnorePointer(
      ignoring: !_shown,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: motionReduced(context) ? Duration.zero : menuFade,
        onEnd: () => setState(() => _fading = false),
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) => _key(event, level.rows),
          child: Stack(fit: StackFit.expand, children: [_scrim(), _framed(_level(level))]),
        ),
      ),
    );
  }

  /// The attention face's dim over the whole window; a tap on it closes the menu.
  Widget _scrim() => Semantics(
    container: true,
    button: true,
    label: closeMenuLabel,
    child: GestureDetector(
      onTap: _close,
      child: const ColoredBox(color: VisageColors.scrim),
    ),
  );

  /// [level] centred at the page's padding in a box the frame's size, scaled into the window as the frame is.
  Widget _framed(Widget level) => FittedBox(
    child: SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: Padding(
        padding: _framePadding,
        child: Center(child: SingleChildScrollView(child: level)),
      ),
    ),
  );

  Widget _level(({String? heading, List<MenuEntry> rows}) level) => MenuLevelView(
    key: ValueKey(_path.join('/')),
    heading: level.heading,
    rows: level.rows,
    focus: _focus,
    onHover: (i) => setState(() => _focus = i),
    onActivate: (i) => _activate(level.rows[i]),
  );
}

final _selectKeys = {LogicalKeyboardKey.enter, LogicalKeyboardKey.numpadEnter, LogicalKeyboardKey.space};
