import Foundation

enum FloatingNoteMode: String, CaseIterable, Identifiable, Sendable {
    case recent
    case newEveryTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            String(localized: "Open Recent Note")
        case .newEveryTime:
            String(localized: "Create a New Note")
        }
    }
}

enum StickyyPreferences {
    static let usesLiquidGlass = "usesLiquidGlass"
    static let usesClipboardHistory = "usesClipboardHistory"
    static let clipboardHistoryLimit = "clipboardHistoryLimit"
    static let globalShortcut = "globalShortcut"
    static let selectedScratchpadID = "selectedScratchpadID"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let usesFloatingPanelShortcut = "usesFloatingPanelShortcut"
    static let floatingNoteMode = "floatingNoteMode"
    static let automaticallyChecksForUpdates = "automaticallyChecksForUpdates"

    static func clipboardHistoryEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.object(forKey: usesClipboardHistory) == nil
            ? true
            : defaults.bool(forKey: usesClipboardHistory)
    }

    static func clipboardHistoryItemLimit(
        in defaults: UserDefaults = .standard
    ) -> Int {
        defaults.integer(forKey: clipboardHistoryLimit) == 7 ? 7 : 5
    }

    static func floatingPanelEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.object(forKey: usesFloatingPanelShortcut) == nil
            ? true
            : defaults.bool(forKey: usesFloatingPanelShortcut)
    }

    static func selectedFloatingNoteMode(
        in defaults: UserDefaults = .standard
    ) -> FloatingNoteMode {
        guard let rawValue = defaults.string(forKey: floatingNoteMode),
              let mode = FloatingNoteMode(rawValue: rawValue) else {
            return .recent
        }
        return mode
    }

    static func automaticUpdateChecksEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.object(forKey: automaticallyChecksForUpdates) == nil
            ? true
            : defaults.bool(forKey: automaticallyChecksForUpdates)
    }
}

extension Notification.Name {
    static let globalShortcutPreferenceDidChange = Notification.Name(
        "Stickyy.globalShortcutPreferenceDidChange"
    )
    static let globalShortcutRecordingDidBegin = Notification.Name("Stickyy.globalShortcutRecordingDidBegin")
    static let globalShortcutRecordingDidEnd = Notification.Name("Stickyy.globalShortcutRecordingDidEnd")
    static let sharingPickerStateDidChange = Notification.Name("Stickyy.sharingPickerStateDidChange")
    static let clipboardHistoryPreferenceDidChange = Notification.Name(
        "Stickyy.clipboardHistoryPreferenceDidChange"
    )
    static let clipboardHistoryStateDidChange = Notification.Name(
        "Stickyy.clipboardHistoryStateDidChange"
    )
    static let onboardingDidFinish = Notification.Name(
        "Stickyy.onboardingDidFinish"
    )
}

@MainActor
protocol ScratchpadSelectionStoring: AnyObject {
    var selectedScratchpadID: String? { get set }
}

@MainActor
final class UserDefaultsScratchpadSelectionStore: ScratchpadSelectionStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedScratchpadID: String? {
        get { defaults.string(forKey: StickyyPreferences.selectedScratchpadID) }
        set { defaults.set(newValue, forKey: StickyyPreferences.selectedScratchpadID) }
    }
}
