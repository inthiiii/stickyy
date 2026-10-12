import AppKit
import SwiftUI

@MainActor
final class PopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    private let session: ScratchpadSession
    private let clipboardShelfController: ClipboardShelfController
    private weak var anchorWindow: NSWindow?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var sharingStateObserver: NSObjectProtocol?
    private var isSharing = false

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: NSApp
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceApplicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        sharingStateObserver = NotificationCenter.default.addObserver(
            forName: .sharingPickerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let isSharing = notification.object as? Bool ?? false
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isSharing = isSharing
                if !self.isSharing, !NSApp.isActive, self.popover.isShown {
                    self.close()
                }
            }
        }
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

        anchorWindow = button.window
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        if let popoverWindow = popover.contentViewController?.view.window {
            clipboardShelfController.show(relativeTo: popoverWindow)
        }
        startDismissalMonitoring()
        NSApp.activate()
        session.requestEditorFocus()
    }

    func close() {
        stopDismissalMonitoring()
        clipboardShelfController.hide()
        popover.close()
    }

    func popoverDidClose(_ notification: Notification) {
        stopDismissalMonitoring()
        clipboardShelfController.hide()
        session.flush()
    }

    private func startDismissalMonitoring() {
        if localMouseMonitor == nil {
            localMouseMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                MainActor.assumeIsolated {
                    self?.dismissIfNeeded(for: event)
                }
                return event
            }
        }

        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown]
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, !self.isSharing else { return }
                    self.close()
                }
            }
        }
    }

    private func stopDismissalMonitoring() {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        anchorWindow = nil
    }

    private func dismissIfNeeded(for event: NSEvent) {
        guard !isSharing else { return }
        guard let eventWindow = event.window else {
            close()
            return
        }
        let popoverWindow = popover.contentViewController?.view.window
        let belongsToStickyy = NSApp.windows.contains {
            $0 === eventWindow
        }
        guard !belongsToStickyy,
              eventWindow !== popoverWindow,
              !clipboardShelfController.owns(eventWindow),
              eventWindow !== anchorWindow else {
            return
        }
        close()
    }

    @objc private func applicationDidResignActive() {
        guard popover.isShown, !isSharing else { return }
        close()
    }

    @objc private func workspaceApplicationDidActivate(
        _ notification: Notification
    ) {
        guard popover.isShown,
              !isSharing,
              let application = notification.userInfo?[
                  NSWorkspace.applicationUserInfoKey
              ] as? NSRunningApplication,
              application.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return
        }
        close()
    }
}
