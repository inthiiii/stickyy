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

    @Test("Floating notes are enabled with the recent note by default")
    func floatingNoteDefaults() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(StickyyPreferences.floatingPanelEnabled(in: defaults))
        #expect(
            StickyyPreferences.selectedFloatingNoteMode(in: defaults)
                == .recent
        )
    }

    @Test("Floating note preferences validate stored values")
    func floatingNotePreferences() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: StickyyPreferences.usesFloatingPanelShortcut)
        defaults.set(
            FloatingNoteMode.newEveryTime.rawValue,
            forKey: StickyyPreferences.floatingNoteMode
        )

        #expect(!StickyyPreferences.floatingPanelEnabled(in: defaults))
        #expect(
            StickyyPreferences.selectedFloatingNoteMode(in: defaults)
                == .newEveryTime
        )

        defaults.set("not-a-mode", forKey: StickyyPreferences.floatingNoteMode)
        #expect(
            StickyyPreferences.selectedFloatingNoteMode(in: defaults)
                == .recent
        )
    }

    @Test("Automatic update checks are enabled by default")
    func automaticUpdateDefaults() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(
            StickyyPreferences.automaticUpdateChecksEnabled(in: defaults)
        )
        defaults.set(
            false,
            forKey: StickyyPreferences.automaticallyChecksForUpdates
        )
        #expect(
            !StickyyPreferences.automaticUpdateChecksEnabled(in: defaults)
        )
    }

    @Test("Onboarding appears only until the user completes it")
    func onboardingCompletion() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(StickyyPreferences.shouldShowOnboarding(in: defaults))
        defaults.set(true, forKey: StickyyPreferences.hasCompletedOnboarding)
        #expect(!StickyyPreferences.shouldShowOnboarding(in: defaults))
    }

    @Test("Text count is off with word mode selected by default")
    func textCountDefaults() throws {
        let suiteName = "StickyyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(!StickyyPreferences.textCountEnabled(in: defaults))
        #expect(
            StickyyPreferences.selectedTextCountMode(in: defaults) == .words
        )
        defaults.set(true, forKey: StickyyPreferences.showsTextCount)
        defaults.set(
            TextCountMode.characters.rawValue,
            forKey: StickyyPreferences.textCountMode
        )
        #expect(StickyyPreferences.textCountEnabled(in: defaults))
        #expect(
            StickyyPreferences.selectedTextCountMode(in: defaults)
                == .characters
        )
    }

    @Test("Word and character counts handle whitespace and composed characters")
    func textCounts() {
        let text = "  One two\nthree 👨‍👩‍👧‍👦"
        #expect(TextCount.value(for: text, mode: .words) == 3)
        #expect(TextCount.value(for: text, mode: .characters) == 17)
    }
}
