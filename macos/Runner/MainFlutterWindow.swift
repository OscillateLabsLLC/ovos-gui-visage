import Cocoa
import FlutterMacOS

/// The window, plus what the widget modes need that window_manager lacks on macOS (lib/window/window_channel.dart):
/// a level beneath every other window and the desktop icons, switchable at runtime, ordering in and out without
/// becoming key, the activation policy, and the menu bar item (StatusMenu.swift).
class MainFlutterWindow: NSWindow {
  private var statusMenu: StatusMenu?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "ovos_gui_visage/window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    statusMenu = StatusMenu(channel: channel)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let window = self else { return result(FlutterError(code: "gone", message: "no window", details: nil)) }
      result(window.handle(call))
    }

    super.awakeFromNib()
  }

  private func handle(_ call: FlutterMethodCall) -> Any? {
    switch call.method {
    case "setDesktopLevel": return setLevel("desktop")
    case "setWindowLevel": return setLevel(call.arguments as? String)
    case "setVisible": return setVisible(call.arguments as? Bool)
    case "setActivationPolicy": return setActivationPolicy(call.arguments as? String)
    case "setMenu": return statusMenu?.update(call.arguments)
    default: return FlutterMethodNotImplemented
    }
  }

  private func setLevel(_ name: String?) -> Any? {
    switch name {
    case "float":
      level = .floating
      collectionBehavior = [.canJoinAllSpaces]
    case "desktop":
      level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
      collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    case "normal":
      level = .normal
      collectionBehavior = []
    default:
      return badArgument("setWindowLevel", name)
    }
    return nil
  }

  private func setVisible(_ visible: Bool?) -> Any? {
    guard let visible = visible else { return badArgument("setVisible", nil) }
    visible ? orderFrontRegardless() : orderOut(nil)
    return nil
  }

  private func setActivationPolicy(_ name: String?) -> Any? {
    switch name {
    case "accessory": NSApp.setActivationPolicy(.accessory)
    case "regular": NSApp.setActivationPolicy(.regular)
    default: return badArgument("setActivationPolicy", name)
    }
    return nil
  }

  private func badArgument(_ method: String, _ value: Any?) -> FlutterError {
    FlutterError(code: "bad-argument", message: "\(method) got \(String(describing: value))", details: nil)
  }
}
