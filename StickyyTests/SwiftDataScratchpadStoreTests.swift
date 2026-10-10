import SwiftData
import Testing
@testable import Stickyy

@MainActor
struct SwiftDataScratchpadStoreTests {
    @Test("SwiftData stores and restores scratchpad text")
    func roundTripsText() throws {
        let persistence = try PersistenceController(
            isStoredInMemoryOnly: true
        )

        try persistence.scratchpadStore.saveText("Saved locally")

        #expect(
            try persistence.scratchpadStore.loadText() == "Saved locally"
        )
    }

    @Test("Repeated saves update one primary record")
    func updatesPrimaryRecordWithoutDuplicates() throws {
        let persistence = try PersistenceController(
            isStoredInMemoryOnly: true
        )

        try persistence.scratchpadStore.saveText("First")
        try persistence.scratchpadStore.saveText("Second")

        let records = try persistence.container.mainContext.fetch(
            FetchDescriptor<ScratchpadRecord>()
        )
        #expect(records.count == 1)
        #expect(records.first?.key == ScratchpadRecord.primaryKey)
        #expect(records.first?.text == "Second")
    }
}
