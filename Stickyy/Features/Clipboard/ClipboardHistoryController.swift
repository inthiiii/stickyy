import AppKit
import Foundation
import Observation

enum ClipboardHistoryContent: Equatable {
    case text(String)
    case image(data: Data, pasteboardType: String, name: String)
    case files([URL])
}

enum ClipboardTextKind: Equatable {
    case text
    case link
    case email
    case phone

    var systemImage: String {
        switch self {
        case .text: "text.quote"
        case .link: "link"
        case .email: "envelope"
        case .phone: "phone"
        }
    }

    static func detect(in text: String) -> ClipboardTextKind {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .text }

        if value.range(
            of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#,
            options: .regularExpression
        ) != nil {
            return .email
        }

        let linkCandidate = value.hasPrefix("www.")
            ? "https://\(value)"
            : value
        if let url = URL(string: linkCandidate),
           let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           url.host != nil {
            return .link
        }

        let allowedPhoneCharacters = CharacterSet(
            charactersIn: "+0123456789()- ."
        )
        let digits = value.filter(\.isNumber)
        if digits.count >= 7,
           value.unicodeScalars.allSatisfy(
               allowedPhoneCharacters.contains
           ) {
            return .phone
        }

        return .text
    }
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
    private(set) var isEnabled: Bool
    private(set) var itemLimit: Int
    private(set) var hasPasteableText = false

    @ObservationIgnored
    private let pasteboard: NSPasteboard

    @ObservationIgnored
    private var monitorTask: Task<Void, Never>?

    @ObservationIgnored
    private var preferenceObserver: NSObjectProtocol?

    @ObservationIgnored
    private var lastChangeCount: Int

    @ObservationIgnored
    private let allowsBackgroundMonitoring: Bool

    init(
        pasteboard: NSPasteboard = .general,
        monitoringEnabled: Bool = true,
        initiallyEnabled: Bool? = nil,
        initialItemLimit: Int? = nil
    ) {
        self.pasteboard = pasteboard
        allowsBackgroundMonitoring = monitoringEnabled
        let enabled = initiallyEnabled
            ?? (monitoringEnabled
                ? StickyyPreferences.clipboardHistoryEnabled()
                : true)
        isEnabled = enabled
        itemLimit = Self.validatedItemLimit(
            initialItemLimit
                ?? (monitoringEnabled
                    ? StickyyPreferences.clipboardHistoryItemLimit()
                    : 5)
        )
        lastChangeCount = -1

        if monitoringEnabled {
            preferenceObserver = NotificationCenter.default.addObserver(
                forName: .clipboardHistoryPreferenceDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.setEnabled(
                        StickyyPreferences.clipboardHistoryEnabled()
                    )
                    self?.setItemLimit(
                        StickyyPreferences.clipboardHistoryItemLimit()
                    )
                }
            }
        }

        if monitoringEnabled {
            startMonitoring()
        }
    }

    func captureIfChanged() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        let content = readCurrentContent()
        if case .text(let text) = content, !text.isEmpty {
            hasPasteableText = true
        } else {
            hasPasteableText = false
        }
        if isEnabled, let content { record(content) }
    }

    @discardableResult
    func restore(_ item: ClipboardHistoryItem) -> Bool {
        pasteboard.clearContents()

        let succeeded: Bool
        switch item.content {
        case .text(let text):
            succeeded = pasteboard.setString(text, forType: .string)
        case .image(let data, let rawType, _):
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

    func clearHistory() {
        items.removeAll()
    }

    func setEnabled(_ enabled: Bool) {
        guard isEnabled != enabled else { return }
        isEnabled = enabled

        if enabled {
            lastChangeCount = -1
            startMonitoring()
        } else {
            clearHistory()
        }

        NotificationCenter.default.post(
            name: .clipboardHistoryStateDidChange,
            object: enabled
        )
    }

    func setItemLimit(_ limit: Int) {
        let validatedLimit = Self.validatedItemLimit(limit)
        guard itemLimit != validatedLimit else { return }
        itemLimit = validatedLimit
        trimToItemLimit()
    }

    func item(at index: Int) -> ClipboardHistoryItem? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    func currentTextForPasting() -> String? {
        let containsFiles = !(pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []).isEmpty
        let containsImage = pasteboard.data(forType: .png) != nil
            || pasteboard.data(forType: .tiff) != nil

        guard !containsFiles,
              !containsImage,
              let text = pasteboard.string(forType: .string),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    #if DEBUG
    func seedForUITesting(text: String) {
        seedForUITesting(texts: [text])
    }

    func seedForUITesting(texts: [String]) {
        guard let latestText = texts.last else { return }
        pasteboard.clearContents()
        _ = pasteboard.setString(latestText, forType: .string)
        lastChangeCount = pasteboard.changeCount
        hasPasteableText = !latestText.isEmpty
        if isEnabled {
            for text in texts where !text.isEmpty {
                record(.text(text))
            }
        }
    }
    #endif

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
                pasteboardType: NSPasteboard.PasteboardType.png.rawValue,
                name: String(localized: "Copied Image")
            )
        }

        if let tiffData = pasteboard.data(forType: .tiff) {
            return .image(
                data: tiffData,
                pasteboardType: NSPasteboard.PasteboardType.tiff.rawValue,
                name: String(localized: "Copied Image")
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation {
            return .image(
                data: tiffData,
                pasteboardType: NSPasteboard.PasteboardType.tiff.rawValue,
                name: String(localized: "Copied Image")
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
        trimToItemLimit()
    }

    private func trimToItemLimit() {
        if items.count > itemLimit {
            items.removeLast(items.count - itemLimit)
        }
    }

    private static func validatedItemLimit(_ proposedLimit: Int) -> Int {
        proposedLimit == 7 ? 7 : 5
    }

    private func startMonitoring() {
        guard allowsBackgroundMonitoring, monitorTask == nil else { return }
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(600))
                guard !Task.isCancelled, let self else { return }
                captureIfChanged()
            }
        }
    }
}
