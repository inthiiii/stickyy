import Foundation

enum StickyyPreferences {
    static let usesLiquidGlass = "usesLiquidGlass"
    static let globalShortcut = "globalShortcut"
    static let selectedScratchpadID = "selectedScratchpadID"
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
