import Foundation
import SwiftData

@Model
final class ScratchpadRecord {
    static let primaryKey = "primary"

    @Attribute(.unique) var key: String
    var text: String
    var updatedAt: Date

    init(
        key: String = ScratchpadRecord.primaryKey,
        text: String = "",
        updatedAt: Date = .now
    ) {
        self.key = key
        self.text = text
        self.updatedAt = updatedAt
    }
}
