import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: NSObject, NSWindowDelegate {
    private let session: ScratchpadSession
    private let panel: FloatingNotePanel

    init(
        session: ScratchpadSession,
        clipboardHistory: ClipboardHistoryController
    ) {
        self.session = session
        panel = FloatingNotePanel(
            contentRect: NSRect(
                origin: .zero,
                size: NSSize(
                    width: StickyyMetrics.floatingPanelWidth,
                    height: StickyyMetrics.floatingPanelHeight
                )
            ),
            styleMask: [
                .borderless,
                .nonactivatingPanel,
                .resizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.delegate = self
        panel.level = .floating
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
        ]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(
            width: StickyyMetrics.floatingPanelMinWidth,
            height: StickyyMetrics.floatingPanelMinHeight
        )
        panel.contentViewController = NSHostingController(
            rootView: FloatingScratchpadView(
                session: session,
                clipboardHistory: clipboardHistory,
                onDismiss: { [weak self] in
                    self?.close()
                }
            )
        )
        panel.setFrameAutosaveName("StickyyFloatingPanel")
    }

    var isShown: Bool {
        panel.isVisible
    }

    func toggle() {
        if panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        guard !panel.isVisible else {
            panel.makeKeyAndOrderFront(nil)
            session.requestEditorFocus()
            return
        }

        if StickyyPreferences.selectedFloatingNoteMode() == .newEveryTime {
            session.createScratchpad()
        }

        let restoredFrame = panel.setFrameUsingName("StickyyFloatingPanel")
        let frameIsVisible = NSScreen.screens.contains {
            $0.visibleFrame.intersects(panel.frame)
        }
        if !restoredFrame || !frameIsVisible {
            centerOnActiveScreen()
        }

        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate()
        session.requestEditorFocus()
    }

    func close() {
        guard panel.isVisible else { return }
        session.flush()
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        // The floating note deliberately remains visible above other apps.
        // Its shortcut or Escape key is the explicit dismissal gesture.
        session.flush()
    }

    func windowWillClose(_ notification: Notification) {
        session.flush()
    }

    private func centerOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main
        guard let visibleFrame = targetScreen?.visibleFrame else { return }

        let origin = NSPoint(
            x: visibleFrame.midX - panel.frame.width / 2,
            y: visibleFrame.midY - panel.frame.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

@MainActor
private final class FloatingNotePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
