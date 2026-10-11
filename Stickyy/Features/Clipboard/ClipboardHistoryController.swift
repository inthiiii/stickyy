import AppKit
import Foundation
import Observation

enum ClipboardHistoryContent: Equatable {
    case text(String)
    case image(data: Data, pasteboardType: String)
    case files([URL])
}

struct ClipboardHistoryItem: Identifiable, Equatable {
    let id: UUID
    let content: ClipboardHistoryContent
    let capturedAt: Date

    init(
        id: UUID = UUID(),
        content: ClipboardHistoryContent,
        capturedAt: Date = .now
    ) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
    }
}

@MainActor
@Observable
final class ClipboardHistoryController {
    private(set) var items: [ClipboardHistoryItem] = []

    @ObservationIgnored
    private let pasteboard: NSPasteboard

    @ObservationIgnored
    private var monitorTask: Task<Void, Never>?

    @ObservationIgnored
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        monitoringEnabled: Bool = true
    ) {
        self.pasteboard = pasteboard
        lastChangeCount = monitoringEnabled ? -1 : pasteboard.changeCount

        if monitoringEnabled {
            monitorTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled, let self else { return }
                    captureIfChanged()
                }
            }
        }
    }

    func captureIfChanged() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard let content = readCurrentContent() else { return }
        record(content)
    }

    @discardableResult
    func restore(_ item: ClipboardHistoryItem) -> Bool {
        pasteboard.clearContents()

        let succeeded: Bool
        switch item.content {
        case .text(let text):
            succeeded = pasteboard.setString(text, forType: .string)
        case .image(let data, let rawType):
            succeeded = pasteboard.setData(
                data,
                forType: NSPasteboard.PasteboardType(rawType)
            )
        case .files(let urls):
            succeeded = pasteboard.writeObjects(urls.map { $0 as NSURL })
        }

        lastChangeCount = pasteboard.changeCount
        if succeeded {
            record(item.content)
        }
        return succeeded
    }

    private func readCurrentContent() -> ClipboardHistoryContent? {
        let fileObjects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []
        let fileURLs = fileObjects.compactMap { object -> URL? in
            guard let fileURL = object as? NSURL else { return nil }
            return fileURL as URL
        }
        if !fileURLs.isEmpty {
            return .files(fileURLs)
        }

        if let pngData = pasteboard.data(forType: .png) {
            return .image(
                data: pngData,
                pasteboardType: NSPasteboard.PasteboardType.png.rawValue
            )
        }

        if let tiffData = pasteboard.data(forType: .tiff) {
            return .image(
                data: tiffData,
                pasteboardType: NSPasteboard.PasteboardType.tiff.rawValue
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation {
            return .image(
                data: tiffData,
                pasteboardType: NSPasteboard.PasteboardType.tiff.rawValue
            )
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return .text(text)
        }

        return nil
    }

    private func record(_ content: ClipboardHistoryContent) {
        items.removeAll { $0.content == content }
        items.insert(ClipboardHistoryItem(content: content), at: 0)
        if items.count > 5 {
            items.removeLast(items.count - 5)
        }
    }
}
