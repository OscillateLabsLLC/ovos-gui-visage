import Cocoa
import FlutterMacOS

/// The menu bar item. Dart owns the items (lib/window/status_menu.dart) and sends the whole list on every change;
/// this rebuilds the NSMenu from it and sends the id of a chosen item back as `menuSelected`.
class StatusMenu: NSObject {
  private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let channel: FlutterMethodChannel

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
    item.button?.image = StatusMenu.faceGlyph()
    item.button?.toolTip = "ovos-gui-visage"
  }

  func update(_ arguments: Any?) -> Any? {
    guard let entries = arguments as? [[String: Any]] else {
      return FlutterError(code: "bad-menu", message: "setMenu wants a list of items", details: "\(String(describing: arguments))")
    }
    item.menu = build(entries)
    NSLog("menu: %d items", entries.count)
    return nil
  }

  private func build(_ entries: [[String: Any]]) -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    for entry in entries {
      menu.addItem(menuItem(entry))
    }
    return menu
  }

  private func menuItem(_ entry: [String: Any]) -> NSMenuItem {
    if entry["separator"] as? Bool == true { return .separator() }
    let menuItem = NSMenuItem(title: entry["title"] as? String ?? "", action: #selector(selected(_:)), keyEquivalent: "")
    menuItem.target = self
    menuItem.representedObject = entry["id"] as? String
    menuItem.state = entry["checked"] as? Bool == true ? .on : .off
    menuItem.isEnabled = entry["enabled"] as? Bool ?? true
    if let children = entry["children"] as? [[String: Any]] {
      menuItem.submenu = build(children)
    }
    return menuItem
  }

  @objc private func selected(_ sender: NSMenuItem) {
    guard let id = sender.representedObject as? String else { return NSLog("menu: %@ has no id", sender.title) }
    channel.invokeMethod("menuSelected", arguments: id)
  }

  /// Two eyes and a smile, drawn as a template so the menu bar tints it for light and dark.
  private static func faceGlyph() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
      NSColor.black.setFill()
      NSBezierPath(ovalIn: NSRect(x: 4.5, y: 10, width: 3, height: 3)).fill()
      NSBezierPath(ovalIn: NSRect(x: 10.5, y: 10, width: 3, height: 3)).fill()
      let smile = NSBezierPath()
      smile.appendArc(withCenter: NSPoint(x: 9, y: 8), radius: 4.5, startAngle: 200, endAngle: 340)
      smile.lineWidth = 1.6
      smile.lineCapStyle = .round
      NSColor.black.setStroke()
      smile.stroke()
      return true
    }
    image.isTemplate = true
    return image
  }
}
