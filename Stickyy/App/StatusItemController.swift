import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popoverController: PopoverController
    private lazy var contextMenu = makeContextMenu()

    init(popoverController: PopoverController) {
        self.popoverController = popoverController
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        super.init()

        guard let button = statusItem.button else {
            assertionFailure("Stickyy could not create its menu-bar button.")
            return
        }

        button.image = NSImage(
            systemSymbolName: "note.text",
            accessibilityDescription: AppEnvironment.productName
        )
        button.image?.isTemplate = true
        button.toolTip = AppEnvironment.productName
        button.setAccessibilityLabel(AppEnvironment.productName)
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func showScratchpad() {
        guard let button = statusItem.button else { return }
        popoverController.show(relativeTo: button)
    }

    @objc
    private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(from: sender)
        } else {
            popoverController.toggle(relativeTo: sender)
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        popoverController.close()
        statusItem.menu = contextMenu
        button.performClick(nil)
        statusItem.menu = nil
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let phaseLabel = NSMenuItem(
            title: String(localized: "Stickyy — Phase 6"),
            action: nil,
            keyEquivalent: ""
        )
        phaseLabel.isEnabled = false
        menu.addItem(phaseLabel)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: String(localized: "Settings…"),
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: String(localized: "Quit Stickyy"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)
        return menu
    }

    @objc
    private func showSettings() {
        popoverController.close()
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
