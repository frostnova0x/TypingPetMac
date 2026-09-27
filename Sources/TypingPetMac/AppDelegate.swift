import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: OverlayWindow!
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.load()
        NSApp.setActivationPolicy(settings.showInDock ? .regular : .accessory)

        overlay = OverlayWindow(settings: settings)
        overlay.orderFrontRegardless()

        statusBar = StatusBarController(window: overlay)

        requestAccessibilityPermissionIfNeeded()

        if !settings.welcomed {
            settings.welcomed = true
            settings.save()
            DispatchQueue.main.async {
                SettingsWindowController.shared.show(for: self.overlay)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
