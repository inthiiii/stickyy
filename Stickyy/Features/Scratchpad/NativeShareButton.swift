import AppKit
import SwiftUI

struct NativeShareButton: NSViewRepresentable {
    let text: String
    let isEnabled: Bool

    func makeNSView(context: Context) -> NativeShareControl {
        let button = NativeShareControl()
        button.setAccessibilityIdentifier("exportToAppleNotes")
        button.setAccessibilityLabel(String(localized: "Export to Apple Notes"))
        return button
    }

    func updateNSView(_ button: NativeShareControl, context: Context) {
        button.shareText = text
        button.isEnabled = isEnabled
    }
}

@MainActor
final class NativeShareControl: NSButton, NSSharingServiceDelegate {
    var shareText = ""
    private var services: [NSSharingService] = []
    private var activeService: NSSharingService?
    private var isPerformingShare = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
        imagePosition = .imageOnly
        isBordered = false
        bezelStyle = .inline
        target = self
        action = #selector(showSharingPicker)
        toolTip = String(localized: "Export to Apple Notes")
    }

    required init?(coder: NSCoder) { nil }

    @objc private func showSharingPicker() {
        guard !shareText.isEmpty else { return }
        setSharingActive(true)
        isPerformingShare = false
        services = NSSharingService.sharingServices(forItems: [shareText])
            .filter { Self.includesSharingService(title: $0.title) }

        let menu = NSMenu(title: String(localized: "Share"))
        for (index, service) in services.enumerated() {
            let item = NSMenuItem(
                title: service.title,
                action: #selector(performShare(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.image = service.image
            item.setAccessibilityIdentifier("sharingService_\(index)")
            menu.addItem(item)
        }

        if menu.items.isEmpty {
            let unavailable = NSMenuItem(title: String(localized: "No Sharing Services Available"), action: nil, keyEquivalent: "")
            unavailable.isEnabled = false
            menu.addItem(unavailable)
        }

        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: bounds.height + 4),
            in: self
        )
        if !isPerformingShare { setSharingActive(false) }
    }

    @objc private func performShare(_ sender: NSMenuItem) {
        guard services.indices.contains(sender.tag) else { return }
        let service = services[sender.tag]
        guard service.canPerform(withItems: [shareText]) else { return }
        isPerformingShare = true
        activeService = service
        service.delegate = self
        service.perform(withItems: [shareText])
    }

    func sharingService(
        _ sharingService: NSSharingService,
        didShareItems items: [Any]
    ) {
        finishSharing()
    }

    func sharingService(
        _ sharingService: NSSharingService,
        didFailToShareItems items: [Any],
        error: any Error
    ) {
        finishSharing()
        NSAlert(error: error).runModal()
    }

    private func finishSharing() {
        isPerformingShare = false
        activeService = nil
        services = []
        setSharingActive(false)
    }

    private func setSharingActive(_ isActive: Bool) {
        NotificationCenter.default.post(
            name: .sharingPickerStateDidChange,
            object: isActive
        )
    }

    nonisolated static func includesSharingService(title: String) -> Bool {
        !title.localizedCaseInsensitiveContains("shortcut")
    }
}
