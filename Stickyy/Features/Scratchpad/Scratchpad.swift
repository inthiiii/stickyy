import Foundation

struct Scratchpad: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var text: String
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String = String(localized: "Untitled"),
        text: String = "",
        isPinned: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
