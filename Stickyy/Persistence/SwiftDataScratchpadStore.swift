import Foundation
import SwiftData

@MainActor
final class SwiftDataScratchpadStore: ScratchpadStoring {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadText() throws -> String {
        try primaryRecord()?.text ?? ""
    }

    func saveText(_ text: String) throws {
        if let record = try primaryRecord() {
            record.text = text
            record.updatedAt = .now
        } else {
            context.insert(ScratchpadRecord(text: text))
        }

        try context.save()
    }

    private func primaryRecord() throws -> ScratchpadRecord? {
        let primaryKey = ScratchpadRecord.primaryKey
        var descriptor = FetchDescriptor<ScratchpadRecord>(
            predicate: #Predicate { record in
                record.key == primaryKey
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
