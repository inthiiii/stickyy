import AppKit
import SwiftUI

@MainActor
final class StartupStatusController {
    private static let cardSize = NSSize(width: 330, height: 88)
    private let panel: NSPanel
    private var dismissalTask: Task<Void, Never>?

    init() {
        panel = NSPanel(
            contentRect: NSRect(
                origin: .zero,
                size: Self.cardSize
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle,
        ]
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.contentViewController = NSHostingController(
            rootView: StartupStatusView()
        )
        panel.setContentSize(Self.cardSize)
    }

    deinit {
        dismissalTask?.cancel()
    }

    func show() {
        dismissalTask?.cancel()
        let targetFrame = frameBelowMenuBar()

        let reduceMotion = NSWorkspace.shared
            .accessibilityDisplayShouldReduceMotion
        panel.alphaValue = reduceMotion ? 1 : 0
        panel.setFrame(
            reduceMotion
                ? targetFrame
                : targetFrame.offsetBy(dx: 0, dy: -8),
            display: false
        )
        panel.orderFrontRegardless()

        if !reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.24
                context.timingFunction = CAMediaTimingFunction(
                    name: .easeOut
                )
                panel.animator().alphaValue = 1
                panel.animator().setFrame(targetFrame, display: true)
            }
        }

        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, let self else { return }
            self.hide()
        }
    }

    private func hide() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            Task { @MainActor in
                panel?.orderOut(nil)
            }
        }
    }

    private func frameBelowMenuBar() -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        } ?? NSScreen.main
        guard let visibleFrame = targetScreen?.visibleFrame else {
            return NSRect(origin: .zero, size: Self.cardSize)
        }

        return NSRect(
            origin: NSPoint(
                x: visibleFrame.midX - Self.cardSize.width / 2,
                y: visibleFrame.maxY - Self.cardSize.height - 14
            ),
            size: Self.cardSize
        )
    }
}

private struct StartupStatusView: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 42, height: 42)
                .background(Color.primary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Stickyy is ready")
                    .font(.system(size: 15, weight: .semibold))
                Text("Back in your menu bar · \(shortcutTitle)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .shadow(color: .green.opacity(0.45), radius: 4)
        }
        .padding(.horizontal, 18)
        .frame(width: 330, height: 88)
        .stickyyPillSurface(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Stickyy is ready. Back in your menu bar."
        )
        .accessibilityIdentifier("startupStatusPanel")
    }

    private var shortcutTitle: String {
        guard let storedValue = UserDefaults.standard.string(
            forKey: StickyyPreferences.globalShortcut
        ), let shortcut = GlobalShortcut(storageValue: storedValue) else {
            return GlobalShortcut.defaultShortcut.title
        }
        return shortcut.title
    }
}
