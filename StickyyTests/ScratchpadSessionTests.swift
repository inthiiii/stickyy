import Foundation
import Testing
@testable import Stickyy

@MainActor
struct ScratchpadSessionTests {
    @Test("An empty store creates and saves a blank scratchpad")
    func createsInitialScratchpad() {
        let store = RecordingScratchpadStore()
        let session = makeSession(store: store)

        #expect(session.scratchpads.count == 1)
        #expect(session.text.isEmpty)
        #expect(store.scratchpads.count == 1)
    }

    @Test("Clipboard paste requests focus the editor with exact text")
    func requestsClipboardInsertion() {
        let session = makeSession(store: RecordingScratchpadStore())
        let previousFocusRequest = session.editorFocusRequest

        session.insertIntoEditor("Pasted thought")

        #expect(session.pendingTextInsertion?.text == "Pasted thought")
        #expect(session.editorFocusRequest == previousFocusRequest + 1)
    }

    @Test("Applied editor insertions cannot replay")
    func appliedInsertionIsCleared() throws {
        let session = makeSession(store: RecordingScratchpadStore())
        session.insertIntoEditor("Paste once")
        let insertion = try #require(session.pendingTextInsertion)

        session.didApplyTextInsertion(id: insertion.id)

        #expect(session.pendingTextInsertion == nil)
    }

    @Test("Onboarding prepares a saved welcome scratchpad")
    func preparesWelcomeScratchpad() {
        let store = RecordingScratchpadStore()
        let session = makeSession(store: store)

        session.prepareWelcomeScratchpad()

        #expect(session.activeTitle == "Welcome to Stickyy")
        #expect(session.text.contains("Welcome to Stickyy"))
        #expect(session.text.contains("⌘1–⌘7"))
        #expect(store.scratchpads.first?.text == session.text)
    }

    @Test("The welcome scratchpad never overwrites an existing thought")
    func welcomeScratchpadPreservesExistingThought() {
        let original = Scratchpad(title: "Keep", text: "Do not replace")
        let store = RecordingScratchpadStore([original])
        let session = makeSession(store: store)

        session.prepareWelcomeScratchpad()

        #expect(session.scratchpads.count == 2)
        #expect(session.activeTitle == "Welcome to Stickyy")
        #expect(
            session.scratchpads.first(where: { $0.id == original.id })?.text
                == "Do not replace"
        )
    }

    @Test("The remembered scratchpad becomes active")
    func restoresSelection() {
        let first = Scratchpad(title: "First", text: "One")
        let second = Scratchpad(title: "Second", text: "Two")
        let selection = MemorySelectionStore(selectedScratchpadID: second.id)
        let session = ScratchpadSession(
            store: RecordingScratchpadStore([first, second]),
            selectionStore: selection
        )

        #expect(session.activeScratchpadID == second.id)
        #expect(session.text == "Two")
    }

    @Test("An invalid remembered selection falls back safely")
    func invalidSelectionFallsBack() {
        let scratchpad = Scratchpad(title: "Available")
        let selection = MemorySelectionStore(selectedScratchpadID: "missing")
        let session = ScratchpadSession(
            store: RecordingScratchpadStore([scratchpad]),
            selectionStore: selection
        )

        #expect(session.activeScratchpadID == scratchpad.id)
        #expect(selection.selectedScratchpadID == scratchpad.id)
    }

    @Test("Creating a scratchpad selects and remembers it")
    func createsAndSelectsScratchpad() {
        let store = RecordingScratchpadStore([Scratchpad(title: "First")])
        let selection = MemorySelectionStore()
        let session = ScratchpadSession(store: store, selectionStore: selection)

        let newID = session.createScratchpad()

        #expect(session.scratchpads.count == 2)
        #expect(session.activeScratchpadID == newID)
        #expect(selection.selectedScratchpadID == newID)
    }

    @Test("Flush immediately saves the active text")
    func flushSavesLatestText() {
        let scratchpad = Scratchpad(text: "Old text")
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)

        session.text = "Latest text"
        session.flush()

        #expect(store.scratchpads.first?.text == "Latest text")
    }

    @Test("Switching scratchpads flushes the outgoing edit")
    func selectionFlushesOutgoingScratchpad() {
        let first = Scratchpad(title: "First")
        let second = Scratchpad(title: "Second")
        let store = RecordingScratchpadStore([first, second])
        let session = makeSession(store: store)

        session.text = "Saved before switching"
        session.selectScratchpad(id: second.id)

        #expect(
            store.scratchpads.first(where: { $0.id == first.id })?.text
                == "Saved before switching"
        )
        #expect(session.activeScratchpadID == second.id)
    }

    @Test("Rapid edits are coalesced into one autosave")
    func coalescesRapidEdits() async throws {
        let scratchpad = Scratchpad()
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store, autosaveDelay: .milliseconds(20))
        store.saveCount = 0

        session.text = "One"
        session.text = "Two"
        session.text = "Three"
        try await Task.sleep(for: .milliseconds(70))

        #expect(store.scratchpads.first?.text == "Three")
        #expect(store.saveCount == 1)
    }

    @Test("Continuous typing receives periodic durable saves")
    func continuouslyTypingStillSaves() async throws {
        let scratchpad = Scratchpad()
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(
            store: store,
            autosaveDelay: .milliseconds(20)
        )
        store.saveCount = 0

        for index in 1...8 {
            session.text = "Edit \(index)"
            try await Task.sleep(for: .milliseconds(10))
        }
        try await Task.sleep(for: .milliseconds(30))

        #expect(store.scratchpads.first?.text == "Edit 8")
        #expect(store.saveCount >= 2)
    }

    @Test("Search matches titles and note text")
    func searchesScratchpads() {
        let session = makeSession(
            store: RecordingScratchpadStore([
                Scratchpad(title: "Shopping", text: "Milk"),
                Scratchpad(title: "Ideas", text: "Build a paper plane"),
            ])
        )

        session.searchQuery = "paper"

        #expect(session.visibleScratchpads.map(\.title) == ["Ideas"])
    }

    @Test("Pinned scratchpads sort before newer unpinned scratchpads")
    func pinnedSortFirst() {
        let older = Scratchpad(
            title: "Pinned",
            isPinned: true,
            updatedAt: .distantPast
        )
        let newer = Scratchpad(title: "Recent", updatedAt: .now)
        let session = makeSession(store: RecordingScratchpadStore([newer, older]))

        #expect(session.visibleScratchpads.map(\.title) == ["Pinned", "Recent"])
    }

    @Test("Pin changes are persisted")
    func togglesPin() {
        let scratchpad = Scratchpad(title: "Important")
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)

        session.togglePin(id: scratchpad.id)

        #expect(session.scratchpads.first?.isPinned == true)
        #expect(store.scratchpads.first?.isPinned == true)
    }

    @Test("Renaming trims whitespace and persists the title")
    func renamesScratchpad() {
        let scratchpad = Scratchpad(title: "Old")
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)

        session.renameScratchpad(id: scratchpad.id, to: "  New name  ")

        #expect(session.activeTitle == "New name")
        #expect(store.scratchpads.first?.title == "New name")
    }

    @Test("An empty rename uses the Untitled fallback")
    func emptyRenameUsesFallback() {
        let scratchpad = Scratchpad(title: "Old")
        let session = makeSession(
            store: RecordingScratchpadStore([scratchpad])
        )

        session.renameScratchpad(id: scratchpad.id, to: "   \n")

        #expect(session.activeTitle == "Untitled")
    }

    @Test("Deleting the final scratchpad creates a blank replacement")
    func deletingLastCreatesReplacement() {
        let scratchpad = Scratchpad(title: "Only")
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)

        session.deleteScratchpad(id: scratchpad.id)

        #expect(session.scratchpads.count == 1)
        #expect(session.activeTitle == "Untitled")
        #expect(session.text.isEmpty)
        #expect(store.scratchpads.count == 1)
    }

    @Test("Deleting a background scratchpad preserves the active selection")
    func deletingBackgroundScratchpadPreservesSelection() {
        let active = Scratchpad(title: "Active")
        let background = Scratchpad(title: "Background")
        let store = RecordingScratchpadStore([active, background])
        let session = makeSession(store: store)

        session.deleteScratchpad(id: background.id)

        #expect(session.activeScratchpadID == active.id)
        #expect(session.scratchpads.map(\.id) == [active.id])
    }

    @Test("A failed deletion leaves the scratchpad available")
    func deleteFailurePreservesScratchpad() {
        let scratchpad = Scratchpad(title: "Keep")
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)
        store.failsOnDelete = true

        session.deleteScratchpad(id: scratchpad.id)

        #expect(session.scratchpads.map(\.id) == [scratchpad.id])
        #expect(session.persistenceError != nil)
    }

    @Test("Persistence failures keep the current text visible")
    func saveFailurePreservesText() {
        let scratchpad = Scratchpad()
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)
        store.failsOnSave = true

        session.text = "Keep this in memory"
        session.flush()

        #expect(session.text == "Keep this in memory")
        #expect(session.persistenceError != nil)
    }

    @Test("A restore failure creates a usable in-memory scratchpad")
    func restoreFailureCreatesFallback() {
        let store = RecordingScratchpadStore()
        store.failsOnLoad = true

        let session = makeSession(store: store)

        #expect(session.scratchpads.count == 1)
        #expect(session.text.isEmpty)
        #expect(session.persistenceError != nil)
    }

    @Test("A one-megabyte scratchpad remains intact")
    func largeScratchpadRemainsIntact() {
        let scratchpad = Scratchpad()
        let store = RecordingScratchpadStore([scratchpad])
        let session = makeSession(store: store)
        let largeText = String(repeating: "A thought worth keeping. ", count: 45_000)

        session.text = largeText
        session.flush()

        #expect(session.text == largeText)
        #expect(store.scratchpads.first?.text == largeText)
    }

    private func makeSession(
        store: RecordingScratchpadStore,
        autosaveDelay: Duration = .milliseconds(300)
    ) -> ScratchpadSession {
        ScratchpadSession(
            store: store,
            selectionStore: MemorySelectionStore(),
            autosaveDelay: autosaveDelay
        )
    }
}

@MainActor
private final class MemorySelectionStore: ScratchpadSelectionStoring {
    var selectedScratchpadID: String?

    init(selectedScratchpadID: String? = nil) {
        self.selectedScratchpadID = selectedScratchpadID
    }
}

@MainActor
private final class RecordingScratchpadStore: ScratchpadStoring {
    var scratchpads: [Scratchpad]
    var saveCount = 0
    var failsOnLoad = false
    var failsOnSave = false
    var failsOnDelete = false

    init(_ scratchpads: [Scratchpad] = []) {
        self.scratchpads = scratchpads
    }

    func loadScratchpads() throws -> [Scratchpad] {
        if failsOnLoad { throw ScratchpadStoreError.unavailable }
        return scratchpads
    }

    func save(_ scratchpad: Scratchpad) throws {
        if failsOnSave { throw ScratchpadStoreError.unavailable }
        if let index = scratchpads.firstIndex(where: { $0.id == scratchpad.id }) {
            scratchpads[index] = scratchpad
        } else {
            scratchpads.append(scratchpad)
        }
        saveCount += 1
    }

    func deleteScratchpad(id: String) throws {
        if failsOnDelete { throw ScratchpadStoreError.unavailable }
        scratchpads.removeAll { $0.id == id }
    }

    func deleteAllScratchpads() throws {
        scratchpads.removeAll()
    }
}
