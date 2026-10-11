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

    @Test("Every shortcut option has a stable unique identifier")
    func shortcutIdentifiersAreUnique() {
        let choices = GlobalShortcutChoice.allCases
        #expect(Set(choices.map(\.rawValue)).count == choices.count)
        #expect(GlobalShortcutChoice.defaultChoice == .controlOptionSpace)
    }

    @Test("Disabled shortcut does not register a key combination")
    func disabledShortcutHasNoKey() {
        #expect(GlobalShortcutChoice.disabled.keyCode == nil)
        #expect(GlobalShortcutChoice.disabled.modifiers == 0)
    }

    @Test("Configured shortcuts map to the expected native keys")
    func nativeShortcutMappings() {
        #expect(GlobalShortcutChoice.controlOptionSpace.keyCode == UInt32(kVK_Space))
        #expect(GlobalShortcutChoice.controlOptionS.keyCode == UInt32(kVK_ANSI_S))
        #expect(
            GlobalShortcutChoice.commandShiftSpace.modifiers
                == UInt32(cmdKey | shiftKey)
        )
    }
}
