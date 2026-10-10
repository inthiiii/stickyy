import Foundation
import SwiftData

@MainActor
final class SwiftDataScratchpadStore: ScratchpadStoring {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadScratchpads() throws -> [Scratchpad] {
        let descriptor = FetchDescriptor<ScratchpadRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { record in
            Scratchpad(
                id: record.key,
                title: record.title ?? legacyTitle(for: record),
                text: record.text,
                isPinned: record.isPinned ?? false,
                createdAt: record.createdAt ?? record.updatedAt,
                updatedAt: record.updatedAt
            )
        }
    }

    func save(_ scratchpad: Scratchpad) throws {
        if let record = try record(id: scratchpad.id) {
            record.title = scratchpad.title
            record.text = scratchpad.text
            record.isPinned = scratchpad.isPinned
            record.createdAt = scratchpad.createdAt
            record.updatedAt = scratchpad.updatedAt
        } else {
            context.insert(
                ScratchpadRecord(
                    key: scratchpad.id,
                    title: scratchpad.title,
                    text: scratchpad.text,
                    isPinned: scratchpad.isPinned,
                    createdAt: scratchpad.createdAt,
                    updatedAt: scratchpad.updatedAt
                )
            )
        }

        try context.save()
    }

    func deleteScratchpad(id: String) throws {
        if let record = try record(id: id) {
            context.delete(record)
            try context.save()
        }
    }

    func deleteAllScratchpads() throws {
        try context.delete(model: ScratchpadRecord.self)
        try context.save()
    }

    private func record(id: String) throws -> ScratchpadRecord? {
        var descriptor = FetchDescriptor<ScratchpadRecord>(
            predicate: #Predicate { record in
                record.key == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func legacyTitle(for record: ScratchpadRecord) -> String {
        record.key == ScratchpadRecord.primaryKey
            ? String(localized: "Scratchpad")
            : String(localized: "Untitled")
    }
}
