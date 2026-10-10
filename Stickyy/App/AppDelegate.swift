import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: AppEnvironment.productName
            )
            button.toolTip = AppEnvironment.productName
        }

        let menu = NSMenu()
        let phaseLabel = NSMenuItem(
            title: "Stickyy — Phase 1",
            action: nil,
            keyEquivalent: ""
        )
        phaseLabel.isEnabled = false
        menu.addItem(phaseLabel)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Stickyy",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }
}
