import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// An ordinary window quits when closed; a widget (an accessory app) lives on in the menu bar while hidden.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return sender.activationPolicy() == .regular
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
