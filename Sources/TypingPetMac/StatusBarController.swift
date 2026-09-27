import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private weak var window: OverlayWindow?

    init(window: OverlayWindow) {
        self.window = window
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Typing Pet")
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let window else { return }
        MenuBuilder.populate(menu, for: window)
    }
}
