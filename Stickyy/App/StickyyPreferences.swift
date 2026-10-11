import Foundation

enum StickyyPreferences {
    static let usesLiquidGlass = "usesLiquidGlass"
    static let usesClipboardHistory = "usesClipboardHistory"
    static let globalShortcut = "globalShortcut"
    static let selectedScratchpadID = "selectedScratchpadID"

    static func clipboardHistoryEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.object(forKey: usesClipboardHistory) == nil
            ? true
            : defaults.bool(forKey: usesClipboardHistory)
    }
}

extension Notification.Name {
    static let clipboardHistoryPreferenceDidChange = Notification.Name(
        "Stickyy.clipboardHistoryPreferenceDidChange"
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
