import AppKit
import SwiftUI

@MainActor
final class StickyySettingsWindowController: NSWindowController,
    NSWindowDelegate {
    init() {
        let hostingController = NSHostingController(
            rootView: StickyySettingsView()
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "Stickyy Settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 470, height: 700))
        window.minSize = NSSize(width: 470, height: 700)
        window.setFrameAutosaveName("StickyySettingsWindow")
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window else { return }
        if !window.isVisible,
           !window.setFrameUsingName("StickyySettingsWindow") {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
