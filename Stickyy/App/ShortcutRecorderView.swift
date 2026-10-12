import AppKit
import Carbon.HIToolbox
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var storageValue: String

    func makeNSView(context: Context) -> ShortcutRecorderControl {
        let control = ShortcutRecorderControl()
        control.onShortcut = { shortcut in
            storageValue = shortcut.storageValue
            NotificationCenter.default.post(name: .globalShortcutPreferenceDidChange, object: nil)
        }
        control.shortcut = GlobalShortcut(storageValue: storageValue) ?? .defaultShortcut
        control.setAccessibilityIdentifier("globalShortcutRecorder")
        return control
    }

    func updateNSView(_ control: ShortcutRecorderControl, context: Context) {
        if !control.isRecording { control.shortcut = GlobalShortcut(storageValue: storageValue) ?? .defaultShortcut }
    }
}

@MainActor
final class ShortcutRecorderControl: NSButton {
    var shortcut = GlobalShortcut.defaultShortcut { didSet { refreshTitle() } }
    var onShortcut: (GlobalShortcut) -> Void = { _ in }
    private(set) var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        focusRingType = .exterior
        setAccessibilityLabel(String(localized: "Show Stickyy shortcut"))
        refreshTitle()
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        title = String(localized: "Press shortcut…")
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }
        if event.keyCode == UInt16(kVK_Escape) { isRecording = false; refreshTitle(); return }
        let modifiers = GlobalShortcut.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            title = String(localized: "Include ⌘, ⌥, ⌃, or ⇧")
            return
        }
        shortcut = GlobalShortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        isRecording = false
        onShortcut(shortcut)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        refreshTitle()
        return super.resignFirstResponder()
    }

    private func refreshTitle() {
        title = shortcut.title
        setAccessibilityValue(shortcut.title)
    }
}
