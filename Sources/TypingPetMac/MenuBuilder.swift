import AppKit

/// NSMenuItem targets must be real Objective-C objects; this wraps a Swift
/// closure so menu construction can stay declarative.
final class MenuAction: NSObject {
    private let handler: () -> Void
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    @objc func invoke(_ sender: Any?) { handler() }
}

enum MenuBuilder {
    static func makeMenu(for window: OverlayWindow) -> NSMenu {
        let menu = NSMenu()
        populate(menu, for: window)
        return menu
    }

    /// Rebuilds the menu's items in place so checkmarks (size, always-on-top,
    /// lock) reflect current settings every time the menu is about to open.
    static func populate(_ menu: NSMenu, for window: OverlayWindow) {
        menu.removeAllItems()
        var actions: [MenuAction] = []
        func item(_ title: String, checked: Bool = false, _ handler: @escaping () -> Void) -> NSMenuItem {
            let action = MenuAction(handler)
            actions.append(action)
            let menuItem = NSMenuItem(title: title, action: #selector(MenuAction.invoke(_:)), keyEquivalent: "")
            menuItem.target = action
            menuItem.state = checked ? .on : .off
            return menuItem
        }

        menu.addItem(item("Settings…") {
            SettingsWindowController.shared.show(for: window)
        })

        let sizeMenu = NSMenu()
        let sizeLabels = ["Small", "Normal", "Large", "Extra Large"]
        for (index, scale) in PetOptions.scales.enumerated() {
            let checked = abs(window.settings.scale - scale) < 0.001
            sizeMenu.addItem(item(sizeLabels[index], checked: checked) {
                window.applyScale(scale)
            })
        }
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        menu.addItem(.separator())

        let topMostMenu = NSMenu()
        for mode in TopMostMode.allCases {
            topMostMenu.addItem(item(mode.label, checked: window.settings.topMostMode == mode) {
                window.applyTopMost(mode)
            })
        }
        let topMostItem = NSMenuItem(title: "Always on Top", action: nil, keyEquivalent: "")
        topMostItem.submenu = topMostMenu
        menu.addItem(topMostItem)

        menu.addItem(item("Lock Position", checked: window.settings.locked) {
            window.applyLocked(!window.settings.locked)
        })
        menu.addItem(item("Reset Position") {
            window.resetPosition()
        })

        menu.addItem(.separator())

        menu.addItem(item("Quit Typing Pet") {
            window.quit()
        })

        window.menuActions = actions
    }
}
