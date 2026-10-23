/// The menu inside the window, the third host of status_menu.dart beside the macOS menu bar item and the Linux tray, so
/// a desktop with neither (stock GNOME, a Pi, a browser tab) can still change mode, leave kiosk and quit (issue #14).
/// [WindowMenuHost] takes the controller's items like the other hosts and holds open requests; [WindowMenu] draws them
/// with Flutter's MenuAnchor once the window is big enough to hold a menu, so a collapsed peek badge expands first.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
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

/// Below this the window is the collapsed badge, and a menu would not fit; the request waits for the expansion.
const menuMinWindow = 240.0;

/// A menu closes whenever the view changes size (RawMenuAnchor), so a request waits until the window has held its
/// size this long: an expanding peek widget animates its growth over several frames.
const menuSettle = Duration(milliseconds: 250);
const _menuInset = 12.0;

class WindowMenu extends StatefulWidget {
  const WindowMenu({super.key, required this.host, required this.child});

  final WindowMenuHost host;
  final Widget child;

  @override
  State<WindowMenu> createState() => _WindowMenuState();
}

class _WindowMenuState extends State<WindowMenu> {
  final controller = MenuController();
  Size _size = Size.zero;
  bool _settled = false;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    widget.host.addListener(_changed);
  }

  @override
  void dispose() {
    widget.host.removeListener(_changed);
    _settle?.cancel();
    super.dispose();
  }

  void _changed() {
    if (widget.host.takeDismiss()) controller.isOpen ? controller.close() : widget.host.closed();
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  void _openPending() {
    if (!mounted || !_settled || widget.host.pending == null || _size.shortestSide < menuMinWindow) return;
    final at = widget.host.take()!;
    final inside = Offset(at.dx.clamp(_menuInset, _size.width), at.dy.clamp(_menuInset, _size.height));
    controller.open(position: inside);
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.biggest != _size) _resized(constraints.biggest);
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: _menuColours),
          child: MenuAnchor(
            controller: controller,
            onClose: widget.host.closed,
            style: _menuStyle,
            menuChildren: [for (final entry in widget.host.items) _entry(entry)],
            child: SizedBox.expand(child: widget.child),
          ),
        );
      },
    );
  }

  Widget _entry(MenuEntry entry) {
    if (entry.separator) return const Divider(height: 9, thickness: 1, color: VisageColors.accentDim);
    final select = entry.enabled ? () => widget.host.onSelected(entry.id) : null;
    final label = Text(entry.title);
    if (entry.children.isNotEmpty) {
      return SubmenuButton(
        style: _itemStyle,
        menuStyle: _menuStyle,
        menuChildren: [for (final c in entry.children) _entry(c)],
        child: label,
      );
    }
    if (isCheckable(entry)) {
      return CheckboxMenuButton(
        style: _itemStyle,
        value: entry.checked,
        onChanged: select == null ? null : (_) => select(),
        child: label,
      );
    }
    return MenuItemButton(style: _itemStyle, onPressed: select, child: label);
  }
}

const _menuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(VisageColors.card),
  side: WidgetStatePropertyAll(BorderSide(color: VisageColors.accentDim)),
);

/// Compact rows, so the whole menu fits a 400 px widget without scrolling.
final _itemStyle = MenuItemButton.styleFrom(
  foregroundColor: VisageColors.fg,
  disabledForegroundColor: VisageColors.muted,
  minimumSize: const Size(0, 32),
  visualDensity: VisualDensity.compact,
);

const _menuColours = ColorScheme.dark(primary: VisageColors.accent, surface: VisageColors.card);
