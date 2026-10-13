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
    private var keyMonitor: Any?

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
        if isRecording {
            stopRecording()
            return
        }
        isRecording = true
        title = String(localized: "Press shortcut…")
        window?.makeFirstResponder(self)
        NotificationCenter.default.post(name: .globalShortcutRecordingDidBegin, object: nil)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = UInt32(event.keyCode)
            let modifiers = GlobalShortcut.carbonModifiers(from: event.modifierFlags)
            let handled = MainActor.assumeIsolated {
                self?.record(keyCode: keyCode, modifiers: modifiers) ?? false
            }
            return handled ? nil : event
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }
        _ = record(keyCode: UInt32(event.keyCode), modifiers: GlobalShortcut.carbonModifiers(from: event.modifierFlags))
    }

    private func record(keyCode: UInt32, modifiers: UInt32) -> Bool {
        guard isRecording else { return false }
        if keyCode == UInt32(kVK_Escape) { stopRecording(); return true }
        guard modifiers & ~UInt32(shiftKey) != 0 else {
            NSSound.beep()
            title = String(localized: "Include ⌘, ⌥, or ⌃")
            return true
        }
        shortcut = GlobalShortcut(keyCode: keyCode, modifiers: modifiers)
        onShortcut(shortcut)
        stopRecording()
        return true
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { stopRecording() }
        return super.resignFirstResponder()
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        refreshTitle()
        NotificationCenter.default.post(name: .globalShortcutRecordingDidEnd, object: nil)
    }

    private func refreshTitle() {
        title = shortcut.title
        setAccessibilityValue(shortcut.title)
    }
}
