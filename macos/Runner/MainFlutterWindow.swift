import Cocoa
import FlutterMacOS

/// The window, plus what the widget modes need that window_manager lacks on macOS (lib/window/window_channel.dart):
/// a level beneath every other window and the desktop icons, switchable at runtime, ordering in and out without
/// becoming key, the activation policy, the menu bar item (StatusMenu.swift), opening a URL (the face picker), and
/// kiosk mode (Kiosk.swift).
class MainFlutterWindow: NSWindow {
  private var statusMenu: StatusMenu?
  private let kiosk = Kiosk()

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
    case "openUrl": return openUrl(call.arguments as? String)
    case "setKiosk": return kiosk.setKiosk(call.arguments as? Bool, window: self)
    case "setKeepAwake": return kiosk.setKeepAwake(call.arguments as? Bool)
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
    case "kiosk":
      level = Kiosk.level
      collectionBehavior = Kiosk.behaviour
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

  private func openUrl(_ text: String?) -> Any? {
    guard let text = text, let url = URL(string: text) else { return badArgument("openUrl", text) }
    NSLog("open: %@", text)
    guard NSWorkspace.shared.open(url) else {
      return FlutterError(code: "open-failed", message: "the system did not open \(text)", details: nil)
    }
    return nil
  }

  private func badArgument(_ method: String, _ value: Any?) -> FlutterError {
    FlutterError(code: "bad-argument", message: "\(method) got \(String(describing: value))", details: nil)
  }
}
