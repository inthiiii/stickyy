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

enum TextCountMode: String, CaseIterable, Identifiable, Sendable {
    case words
    case characters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .words: String(localized: "Words")
        case .characters: String(localized: "Characters")
        }
    }
}

enum StickyyPreferences {
    static let usesLiquidGlass = "usesLiquidGlass"
    static let usesClipboardHistory = "usesClipboardHistory"
    static let clipboardHistoryLimit = "clipboardHistoryLimit"
    static let usesPinnedClipboardItems = "usesPinnedClipboardItems"
    static let pinnedClipboardItems = "pinnedClipboardItems"
    static let globalShortcut = "globalShortcut"
    static let selectedScratchpadID = "selectedScratchpadID"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let usesFloatingPanelShortcut = "usesFloatingPanelShortcut"
    static let floatingNoteMode = "floatingNoteMode"
    static let automaticallyChecksForUpdates = "automaticallyChecksForUpdates"
    static let showsTextCount = "showsTextCount"
    static let textCountMode = "textCountMode"
    static let lastPresentedReleaseNotesVersion =
        "lastPresentedReleaseNotesVersion"

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

    static func pinnedClipboardItemsEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.bool(forKey: usesPinnedClipboardItems)
    }

    static func textCountEnabled(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.bool(forKey: showsTextCount)
    }

    static func selectedTextCountMode(
        in defaults: UserDefaults = .standard
    ) -> TextCountMode {
        guard let rawValue = defaults.string(forKey: textCountMode),
              let mode = TextCountMode(rawValue: rawValue) else {
            return .words
        }
        return mode
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

    static func shouldShowOnboarding(
        in defaults: UserDefaults = .standard
    ) -> Bool {
        !defaults.bool(forKey: hasCompletedOnboarding)
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
    static let pinnedClipboardItemsDidChange = Notification.Name(
        "Stickyy.pinnedClipboardItemsDidChange"
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
