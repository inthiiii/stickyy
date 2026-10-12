import AppKit
import Carbon.HIToolbox

struct GlobalShortcut: Equatable, Sendable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaultShortcut = GlobalShortcut(
        keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | optionKey)
    )

    var storageValue: String { "v1:\(keyCode):\(modifiers)" }
    var title: String { modifierSymbols + keyName }

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(storageValue: String) {
        let parts = storageValue.split(separator: ":")
        if parts.count == 3, parts[0] == "v1",
           let keyCode = UInt32(parts[1]), let modifiers = UInt32(parts[2]) {
            self.init(keyCode: keyCode, modifiers: modifiers)
            return
        }
        switch storageValue {
        case "controlOptionSpace": self.init(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey))
        case "controlOptionS": self.init(keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(controlKey | optionKey))
        case "controlShiftSpace": self.init(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | shiftKey))
        case "commandShiftSpace": self.init(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | shiftKey))
        default: return nil
        }
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    private var modifierSymbols: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result
    }

    private var keyName: String { Self.keyCodeNames[Int(keyCode)] ?? "Key \(keyCode)" }

    private static let keyCodeNames: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_Escape: "⎋",
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D", kVK_ANSI_E: "E",
        kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H", kVK_ANSI_I: "I", kVK_ANSI_J: "J",
        kVK_ANSI_K: "K", kVK_ANSI_L: "L", kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O",
        kVK_ANSI_P: "P", kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X", kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z", kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8",
        kVK_ANSI_9: "9", kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
        kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12", kVK_LeftArrow: "←", kVK_RightArrow: "→",
        kVK_UpArrow: "↑", kVK_DownArrow: "↓"
    ]
}

nonisolated private func handleStickyyHotKey(
    _ nextHandler: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let controller = Unmanaged<GlobalShortcutController>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in controller.performAction() }
    return noErr
}

@MainActor
final class GlobalShortcutController: NSObject {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var localKeyMonitor: Any?
    private var fallbackGlobalKeyMonitor: Any?
    private var currentShortcut = GlobalShortcut.defaultShortcut
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), handleStickyyHotKey, 1, &eventType,
            Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        NotificationCenter.default.addObserver(self, selector: #selector(preferencesDidChange),
            name: .globalShortcutPreferenceDidChange, object: nil)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = UInt32(event.keyCode)
            let modifiers = GlobalShortcut.carbonModifiers(from: event.modifierFlags)
            let handled = MainActor.assumeIsolated {
                guard let self, keyCode == self.currentShortcut.keyCode,
                      modifiers == self.currentShortcut.modifiers else { return false }
                self.performAction()
                return true
            }
            return handled ? nil : event
        }
        registerCurrentShortcut()
    }

    func performAction() { action() }
    @objc private func preferencesDidChange() { registerCurrentShortcut() }

    private func registerCurrentShortcut() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        let saved = UserDefaults.standard.string(forKey: StickyyPreferences.globalShortcut)
        let shortcut = saved.flatMap(GlobalShortcut.init(storageValue:)) ?? .defaultShortcut
        currentShortcut = shortcut
        let hotKeyID = EventHotKeyID(signature: 0x53544B59, id: 1)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKey)
        if status == noErr {
            if let fallbackGlobalKeyMonitor {
                NSEvent.removeMonitor(fallbackGlobalKeyMonitor)
                self.fallbackGlobalKeyMonitor = nil
            }
        } else {
            installFallbackMonitorIfNeeded()
            NSLog("Stickyy is using its shortcut fallback because Carbon returned %d.", status)
        }
    }

    private func installFallbackMonitorIfNeeded() {
        guard fallbackGlobalKeyMonitor == nil else { return }
        fallbackGlobalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = UInt32(event.keyCode)
            let modifiers = GlobalShortcut.carbonModifiers(from: event.modifierFlags)
            Task { @MainActor [weak self] in
                guard let self, keyCode == self.currentShortcut.keyCode,
                      modifiers == self.currentShortcut.modifiers else { return }
                self.performAction()
            }
        }
    }
}
