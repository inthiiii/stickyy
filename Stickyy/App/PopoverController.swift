import AppKit
import SwiftUI

@MainActor
final class PopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    private let session: ScratchpadSession
    private let clipboardShelfController: ClipboardShelfController

    init(
        session: ScratchpadSession,
        clipboardHistory: ClipboardHistoryController
    ) {
        self.session = session
        clipboardShelfController = ClipboardShelfController(
            history: clipboardHistory,
            session: session
        )
        popover = NSPopover()
        super.init()

        popover.behavior = .transient
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        popover.contentSize = NSSize(
            width: StickyyMetrics.popoverWidth,
            height: StickyyMetrics.popoverHeight
        )
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ScratchpadView(
                session: session,
                clipboardHistory: clipboardHistory,
                onDismiss: { [weak self] in
                    self?.close()
                }
            )
        )
    }

    var isShown: Bool {
        popover.isShown
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            close()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard !popover.isShown else {
            session.requestEditorFocus()
            return
        }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        if let popoverWindow = popover.contentViewController?.view.window {
            clipboardShelfController.show(relativeTo: popoverWindow)
        }
        NSApp.activate()
        session.requestEditorFocus()
    }

    func close() {
        clipboardShelfController.hide()
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        clipboardShelfController.hide()
        session.flush()
    }
}
