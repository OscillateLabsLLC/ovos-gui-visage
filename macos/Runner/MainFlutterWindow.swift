import Cocoa
import FlutterMacOS

/// The window, plus the one native call the widget modes need that window_manager lacks on macOS: a window level
/// beneath every other window and the desktop icons, above the wallpaper, so the app can sit on the desktop.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "ovos_gui_visage/window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let window = self else { return result(FlutterError(code: "gone", message: "no window", details: nil)) }
      switch call.method {
      case "setDesktopLevel":
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
