import Foundation

struct Scratchpad: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var text: String
    var richTextData: Data?
    var isPinned: Bool
    var attachments: [ScratchpadAttachment]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String = String(localized: "Untitled"),
        text: String = "",
        richTextData: Data? = nil,
        isPinned: Bool = false,
        attachments: [ScratchpadAttachment] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.richTextData = richTextData
        self.isPinned = isPinned
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ScratchpadAttachment: Identifiable, Equatable, Codable, Sendable {
    enum Kind: String, Codable, Sendable { case image, file }

    let id: UUID
    let kind: Kind
    let url: URL
    let displayName: String

    init(id: UUID = UUID(), kind: Kind, url: URL, displayName: String) {
        self.id = id
        self.kind = kind
        self.url = url
        self.displayName = displayName
    }
}
