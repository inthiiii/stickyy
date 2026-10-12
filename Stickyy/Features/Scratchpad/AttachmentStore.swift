import AppKit
import Foundation

enum AttachmentStore {
    static func makeAttachments(from content: ClipboardHistoryContent) throws -> [ScratchpadAttachment] {
        switch content {
        case .text:
            return []
        case .files(let urls):
            return urls.map { url in
                ScratchpadAttachment(
                    kind: NSImage(contentsOf: url) == nil ? .file : .image,
                    url: url,
                    displayName: url.lastPathComponent
                )
            }
        case .image(let data, let rawType, let name):
            let directory = try attachmentDirectory()
            let ext = rawType == NSPasteboard.PasteboardType.png.rawValue ? "png" : "tiff"
            let url = directory.appendingPathComponent("\(UUID().uuidString).\(ext)")
            try data.write(to: url, options: .atomic)
            return [ScratchpadAttachment(kind: .image, url: url, displayName: "\(name).\(ext)")]
        }
    }

    private static func attachmentDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("Stickyy/Attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
