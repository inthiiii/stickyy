import AppKit
import Carbon.HIToolbox

enum GlobalShortcutChoice: String, CaseIterable, Identifiable {
    case controlOptionSpace
    case controlOptionS
    case controlShiftSpace
    case commandShiftSpace
    case disabled

    static let defaultChoice = GlobalShortcutChoice.controlOptionSpace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .controlOptionSpace: "Control–Option–Space"
        case .controlOptionS: "Control–Option–S"
        case .controlShiftSpace: "Control–Shift–Space"
        case .commandShiftSpace: "Command–Shift–Space"
        case .disabled: String(localized: "Off")
        }
    }

    fileprivate var keyCode: UInt32? {
        switch self {
        case .controlOptionSpace, .controlShiftSpace, .commandShiftSpace:
            UInt32(kVK_Space)
        case .controlOptionS:
            UInt32(kVK_ANSI_S)
        case .disabled:
            nil
        }
    }

    fileprivate var modifiers: UInt32 {
        switch self {
        case .controlOptionSpace, .controlOptionS:
            UInt32(controlKey | optionKey)
        case .controlShiftSpace:
            UInt32(controlKey | shiftKey)
        case .commandShiftSpace:
            UInt32(cmdKey | shiftKey)
        case .disabled:
            0
        }
    }
}

nonisolated private func handleStickyyHotKey(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let controller = Unmanaged<GlobalShortcutController>
        .fromOpaque(userData)
        .takeUnretainedValue()
    Task { @MainActor in
        controller.performAction()
    }
    return noErr
}

@MainActor
final class GlobalShortcutController: NSObject {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            handleStickyyHotKey,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        registerCurrentShortcut()
    }

    func performAction() {
        action()
    }

    @objc
    private func preferencesDidChange() {
        registerCurrentShortcut()
    }

    private func registerCurrentShortcut() {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
            self.hotKey = nil
        }

        let savedValue = UserDefaults.standard.string(
            forKey: StickyyPreferences.globalShortcut
        )
        let choice = savedValue.flatMap(GlobalShortcutChoice.init(rawValue:))
            ?? .defaultChoice
        guard let keyCode = choice.keyCode else { return }

        let hotKeyID = EventHotKeyID(signature: 0x53544B59, id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            choice.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        if status != noErr {
            NSLog("Stickyy could not register its global shortcut (%d).", status)
        }
    }
}
