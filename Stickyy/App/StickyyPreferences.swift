import Foundation

enum StickyyPreferences {
    static let usesLiquidGlass = "usesLiquidGlass"
    static let usesClipboardHistory = "usesClipboardHistory"
    static let clipboardHistoryLimit = "clipboardHistoryLimit"
    static let globalShortcut = "globalShortcut"
    static let selectedScratchpadID = "selectedScratchpadID"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"

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
