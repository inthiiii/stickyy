import AppKit
import SwiftUI

@MainActor
final class PopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    private let session: ScratchpadSession

    init(
        session: ScratchpadSession,
        clipboardHistory: ClipboardHistoryController
    ) {
        self.session = session
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
        NSApp.activate()
        session.requestEditorFocus()
    }

    func close() {
        popover.performClose(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        session.flush()
    }
}
