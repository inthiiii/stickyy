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
    var failsOnSave = false

    init(_ scratchpads: [Scratchpad] = []) {
        self.scratchpads = scratchpads
    }

    func loadScratchpads() throws -> [Scratchpad] {
        scratchpads
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
        if failsOnSave { throw ScratchpadStoreError.unavailable }
        scratchpads.removeAll { $0.id == id }
    }

    func deleteAllScratchpads() throws {
        scratchpads.removeAll()
    }
}
