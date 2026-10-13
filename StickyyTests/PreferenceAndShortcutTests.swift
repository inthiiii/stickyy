import Carbon.HIToolbox
import Foundation
import Testing
@testable import Stickyy

@MainActor
struct PreferenceAndShortcutTests {
    @Test("Scratchpad selection round-trips through isolated defaults")
    func selectionRoundTrips() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsScratchpadSelectionStore(defaults: defaults)

        #expect(store.selectedScratchpadID == nil)
        store.selectedScratchpadID = "remember-me"
        #expect(store.selectedScratchpadID == "remember-me")
        store.selectedScratchpadID = nil
        #expect(store.selectedScratchpadID == nil)
    }

    @Test("The default shortcut is Control-Option-Space")
    func defaultShortcut() {
        #expect(GlobalShortcut.defaultShortcut.keyCode == UInt32(kVK_Space))
        #expect(GlobalShortcut.defaultShortcut.modifiers == UInt32(controlKey | optionKey))
    }

    @Test("Custom shortcuts round-trip through preference storage")
    func shortcutRoundTrip() throws {
        let shortcut = GlobalShortcut(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(cmdKey | shiftKey))
        let restored = try #require(GlobalShortcut(storageValue: shortcut.storageValue))
        #expect(restored == shortcut)
    }

    @Test("Configured shortcuts map to the expected native keys")
    func nativeShortcutMappings() {
        let restored = GlobalShortcut(storageValue: "commandShiftSpace")
        #expect(restored?.keyCode == UInt32(kVK_Space))
        #expect(restored?.modifiers == UInt32(cmdKey | shiftKey))
    }

    @Test("Clipboard pill count accepts only five or seven")
    func clipboardPillCount() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(StickyyPreferences.clipboardHistoryItemLimit(in: defaults) == 5)
        defaults.set(7, forKey: StickyyPreferences.clipboardHistoryLimit)
        #expect(StickyyPreferences.clipboardHistoryItemLimit(in: defaults) == 7)
        defaults.set(6, forKey: StickyyPreferences.clipboardHistoryLimit)
        #expect(StickyyPreferences.clipboardHistoryItemLimit(in: defaults) == 5)
    }

    @Test("The Shortcuts share destination is excluded")
    func filtersShortcutsSharingService() {
        #expect(!NativeShareControl.includesSharingService(title: "Shortcuts"))
        #expect(!NativeShareControl.includesSharingService(title: "Add to Shortcuts"))
        #expect(NativeShareControl.includesSharingService(title: "Messages"))
        #expect(NativeShareControl.includesSharingService(title: "Add to Notes"))
    }
}
