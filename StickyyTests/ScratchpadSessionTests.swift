import Foundation
import Testing
@testable import Stickyy

@MainActor
struct ScratchpadSessionTests {
    @Test("A new scratchpad restores an empty value")
    func startsEmpty() {
        let store = RecordingScratchpadStore(text: "")
        let session = ScratchpadSession(store: store)

        #expect(session.text.isEmpty)
        #expect(session.persistenceError == nil)
        #expect(session.editorFocusRequest == 0)
    }

    @Test("Saved text is restored when a session starts")
    func restoresSavedText() {
        let store = RecordingScratchpadStore(text: "A remembered thought")
        let session = ScratchpadSession(store: store)

        #expect(session.text == "A remembered thought")
    }

    @Test("Flush immediately saves the latest text")
    func flushSavesLatestText() {
        let store = RecordingScratchpadStore(text: "Old text")
        let session = ScratchpadSession(store: store)

        session.text = "Latest text"
        session.flush()

        #expect(store.text == "Latest text")
        #expect(store.saveCount == 1)
    }

    @Test("Text is saved after the debounce interval")
    func autosavesAfterDelay() async throws {
        let store = RecordingScratchpadStore(text: "")
        let session = ScratchpadSession(
            store: store,
            autosaveDelay: .milliseconds(10)
        )

        session.text = "Automatically saved"
        try await Task.sleep(for: .milliseconds(50))

        #expect(store.text == "Automatically saved")
        #expect(store.saveCount == 1)
    }

    @Test("Rapid edits are coalesced into one save")
    func coalescesRapidEdits() async throws {
        let store = RecordingScratchpadStore(text: "")
        let session = ScratchpadSession(
            store: store,
            autosaveDelay: .milliseconds(20)
        )

        session.text = "One"
        session.text = "Two"
        session.text = "Three"
        try await Task.sleep(for: .milliseconds(70))

        #expect(store.text == "Three")
        #expect(store.saveCount == 1)
    }

    @Test("Reset clears and persists the scratchpad")
    func resetClearsText() {
        let store = RecordingScratchpadStore(text: "Temporary note")
        let session = ScratchpadSession(store: store)

        session.reset()
        session.flush()

        #expect(session.text.isEmpty)
        #expect(store.text.isEmpty)
    }

    @Test("Persistence failures are exposed without losing session text")
    func saveFailurePreservesText() {
        let store = RecordingScratchpadStore(text: "", failsOnSave: true)
        let session = ScratchpadSession(store: store)

        session.text = "Keep this in memory"
        session.flush()

        #expect(session.text == "Keep this in memory")
        #expect(session.persistenceError != nil)
    }

    @Test("Every focus request has a new generation")
    func focusRequestsAdvance() {
        let store = RecordingScratchpadStore(text: "")
        let session = ScratchpadSession(store: store)

        session.requestEditorFocus()
        session.requestEditorFocus()

        #expect(session.editorFocusRequest == 2)
    }
}

@MainActor
private final class RecordingScratchpadStore: ScratchpadStoring {
    var text: String
    var saveCount = 0
    var failsOnSave: Bool

    init(text: String, failsOnSave: Bool = false) {
        self.text = text
        self.failsOnSave = failsOnSave
    }

    func loadText() throws -> String {
        text
    }

    func saveText(_ text: String) throws {
        if failsOnSave {
            throw ScratchpadStoreError.unavailable
        }

        self.text = text
        saveCount += 1
    }
}
