import AppKit
import QuartzCore
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

        let parentFrame: NSRect
        if let contentView = parentWindow.contentView {
            let inWindow = contentView.convert(contentView.bounds, to: nil)
            parentFrame = parentWindow.convertToScreen(inWindow)
        } else {
            parentFrame = parentWindow.frame
        }
        let shelfSize = panel.frame.size
        let origin = NSPoint(
            x: parentFrame.midX - (shelfSize.width / 2),
            y: parentFrame.minY
                - StickyyMetrics.clipboardShelfGap
                - shelfSize.height
        )
        let targetFrame = NSRect(origin: origin, size: shelfSize)
        let isNewlyShown = !panel.isVisible

        if panel.parent !== parentWindow {
            panel.parent?.removeChildWindow(panel)
            parentWindow.addChildWindow(panel, ordered: .above)
        }
        panel.setFrame(targetFrame, display: true)
        panel.orderFront(nil)
        if isNewlyShown { animateOpening() }
    }

    func hide() {
        panel.contentView?.layer?.removeAllAnimations()
        panel.alphaValue = 1
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        parentWindow = nil
    }

    func owns(_ window: NSWindow?) -> Bool {
        panel === window
    }

    private func animateOpening() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
              let view = panel.contentView else { return }
        view.wantsLayer = true
        guard let layer = view.layer else { return }
        layer.removeAllAnimations()

        let spring = CASpringAnimation(keyPath: "transform")
        spring.fromValue = CATransform3DMakeScale(0.88, 0.88, 1)
        spring.toValue = CATransform3DIdentity
        spring.mass = 1
        spring.stiffness = 250
        spring.damping = 18
        spring.initialVelocity = 0.5
        spring.duration = min(spring.settlingDuration, 0.42)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = 0.16

        layer.add(spring, forKey: "stickyy.open.spring")
        layer.add(fade, forKey: "stickyy.open.fade")
    }
}
