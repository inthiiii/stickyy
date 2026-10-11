import AppKit
import SwiftUI

@MainActor
final class ClipboardShelfController {
    private let panel: NSPanel
    private let history: ClipboardHistoryController
    private weak var parentWindow: NSWindow?
    private var historyStateObserver: NSObjectProtocol?

    init(
        history: ClipboardHistoryController,
        session: ScratchpadSession
    ) {
        self.history = history

        panel = NSPanel(
            contentRect: NSRect(
                origin: .zero,
                size: NSSize(
                    width: StickyyMetrics.popoverWidth,
                    height: StickyyMetrics.clipboardShelfHeight
                )
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.title = String(localized: "Clipboard History")
        panel.setAccessibilityLabel(String(localized: "Clipboard History"))
        panel.collectionBehavior = [.transient, .ignoresCycle]
        let hostingController = NSHostingController(
            rootView: ClipboardHistoryView(history: history) { text in
                session.insertIntoEditor(text)
            }
        )
        hostingController.view.setAccessibilityLabel(
            String(localized: "Clipboard History")
        )
        panel.contentViewController = hostingController

        historyStateObserver = NotificationCenter.default.addObserver(
            forName: .clipboardHistoryStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateVisibility()
            }
        }
    }

    func show(relativeTo parentWindow: NSWindow) {
        self.parentWindow = parentWindow
        updateVisibility()
    }

    func updateVisibility() {
        guard history.isEnabled else {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
            return
        }

        guard let parentWindow,
              parentWindow.isVisible else {
            hide()
            return
        }

        let parentFrame = parentWindow.frame
        let shelfSize = panel.frame.size
        let origin = NSPoint(
            x: parentFrame.midX - (shelfSize.width / 2),
            y: parentFrame.minY
                - StickyyMetrics.clipboardShelfGap
                - shelfSize.height
        )
        panel.setFrameOrigin(origin)

        if panel.parent !== parentWindow {
            panel.parent?.removeChildWindow(panel)
            parentWindow.addChildWindow(panel, ordered: .above)
        }
        panel.orderFront(nil)
    }

    func hide() {
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        parentWindow = nil
    }

    func owns(_ window: NSWindow?) -> Bool {
        panel === window
    }
}
