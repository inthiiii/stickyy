import SwiftData
import Testing
@testable import Stickyy

@MainActor
struct SwiftDataScratchpadStoreTests {
    @Test("SwiftData stores and restores multiple scratchpads")
    func roundTripsScratchpads() throws {
        let persistence = try PersistenceController(
            isStoredInMemoryOnly: true
        )

        let first = Scratchpad(title: "First", text: "Saved locally")
        let second = Scratchpad(title: "Second", text: "Another note", isPinned: true)
        try persistence.scratchpadStore.save(first)
        try persistence.scratchpadStore.save(second)

        let restored = try persistence.scratchpadStore.loadScratchpads()
        #expect(Set(restored.map(\.id)) == Set([first.id, second.id]))
        #expect(restored.first(where: { $0.id == second.id })?.isPinned == true)
    }

    @Test("Repeated saves update one primary record")
    func updatesPrimaryRecordWithoutDuplicates() throws {
        let persistence = try PersistenceController(
            isStoredInMemoryOnly: true
        )

        var scratchpad = Scratchpad(title: "First")
        try persistence.scratchpadStore.save(scratchpad)
        scratchpad.title = "Second"
        try persistence.scratchpadStore.save(scratchpad)

        let records = try persistence.container.mainContext.fetch(
            FetchDescriptor<ScratchpadRecord>()
        )
        #expect(records.count == 1)
        #expect(records.first?.key == scratchpad.id)
        #expect(records.first?.title == "Second")
    }

    @Test("SwiftData deletes only the requested scratchpad")
    func deletesScratchpad() throws {
        let persistence = try PersistenceController(isStoredInMemoryOnly: true)
        let first = Scratchpad(title: "Keep")
        let second = Scratchpad(title: "Delete")
        try persistence.scratchpadStore.save(first)
        try persistence.scratchpadStore.save(second)

        try persistence.scratchpadStore.deleteScratchpad(id: second.id)

        let restored = try persistence.scratchpadStore.loadScratchpads()
        #expect(restored.map(\.id) == [first.id])
    }

    @Test("A legacy primary record receives a readable title")
    func migratesLegacyRecord() throws {
        let persistence = try PersistenceController(isStoredInMemoryOnly: true)
        persistence.container.mainContext.insert(
            ScratchpadRecord(text: "Legacy text")
        )
        try persistence.container.mainContext.save()

        let restored = try persistence.scratchpadStore.loadScratchpads()

        #expect(restored.first?.title == "Scratchpad")
        #expect(restored.first?.text == "Legacy text")
    }
}
