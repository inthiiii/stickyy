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
final class NativeShareControl: NSButton, NSSharingServicePickerDelegate {
    var shareText = ""
    private var picker: NSSharingServicePicker?

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
        let picker = NSSharingServicePicker(items: [shareText])
        picker.delegate = self
        self.picker = picker
        picker.show(relativeTo: bounds, of: self, preferredEdge: .minY)
    }
}
