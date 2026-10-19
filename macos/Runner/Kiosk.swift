import Cocoa
import FlutterMacOS
import IOKit.pwr_mgt

/// Kiosk mode's macOS half (lib/window/kiosk_shell_io.dart). The window sits one level below the menu bar (24),
/// above the Dock (20) and notification banners (21), so it covers both while the auto-hidden menu bar, and the
/// status item in it, still slide down over it at the top edge. Not native fullscreen, which makes its own Space and
/// animates. While the app is frontmost the Dock is hidden and the menu bar hides until the pointer reaches the top.
/// A power assertion keeps the display awake until kiosk ends or the app quits.
final class Kiosk {
  static let level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
  static let behaviour: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
  private static let assertionName = "ovos-gui-visage kiosk keeps the display awake" as CFString

  private var assertion: IOPMAssertionID?
  private var quitObserver: NSObjectProtocol?

  init() {
    quitObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.release() }
  }

  /// On: activates the app, hides the Dock and the menu bar, fills the main screen and takes the keyboard (Escape).
  func setKiosk(_ on: Bool?, window: NSWindow) -> Any? {
    guard let on = on else { return FlutterError(code: "bad-argument", message: "setKiosk got nil", details: nil) }
    guard on else {
      NSApp.presentationOptions = []
      NSLog("kiosk: off, Dock and menu bar restored")
      return nil
    }
    if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
    NSApp.presentationOptions = [.hideDock, .autoHideMenuBar]
    if let screen = NSScreen.screens.first { window.setFrame(screen.frame, display: true) }
    window.makeKeyAndOrderFront(nil)
    NSLog(
      "kiosk: on, frame %@, presentation options %lu", NSStringFromRect(window.frame),
      NSApp.currentSystemPresentationOptions.rawValue)
    return nil
  }

  func setKeepAwake(_ on: Bool?) -> Any? {
    guard let on = on else { return FlutterError(code: "bad-argument", message: "setKeepAwake got nil", details: nil) }
    return on ? take() : release()
  }

  private func take() -> Any? {
    if assertion != nil { return nil }
    var id = IOPMAssertionID(0)
    let status = IOPMAssertionCreateWithName(
      kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn),
      Kiosk.assertionName, &id)
    guard status == kIOReturnSuccess else {
      NSLog("kiosk: keep-awake assertion failed, status %d", status)
      return FlutterError(code: "keep-awake-failed", message: "IOPMAssertionCreateWithName returned \(status)", details: nil)
    }
    assertion = id
    NSLog("kiosk: keep-awake assertion %u taken", id)
    return nil
  }

  @discardableResult
  private func release() -> Any? {
    guard let id = assertion else { return nil }
    assertion = nil
    let status = IOPMAssertionRelease(id)
    NSLog("kiosk: keep-awake assertion %u released, status %d", id, status)
    guard status == kIOReturnSuccess else {
      return FlutterError(code: "keep-awake-failed", message: "IOPMAssertionRelease returned \(status)", details: nil)
    }
    return nil
  }
}
