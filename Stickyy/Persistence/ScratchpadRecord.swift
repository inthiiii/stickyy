import Foundation
import SwiftData

@Model
final class ScratchpadRecord {
    static let primaryKey = "primary"

    @Attribute(.unique) var key: String
    var text: String
    var richTextData: Data?
    var updatedAt: Date
    var title: String?
    var createdAt: Date?
    var isPinned: Bool?
    var attachmentsData: Data?

    init(
        key: String = ScratchpadRecord.primaryKey,
        title: String? = nil,
        text: String = "",
        richTextData: Data? = nil,
        isPinned: Bool? = nil,
        attachmentsData: Data? = nil,
        createdAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.title = title
        self.text = text
        self.richTextData = richTextData
        self.isPinned = isPinned
        self.attachmentsData = attachmentsData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
