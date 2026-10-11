import AppKit
import Testing
@testable import Stickyy

@MainActor
struct ClipboardHistoryTests {
    @Test("Clipboard history keeps the newest five text items")
    func keepsNewestFiveItems() {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )

        for index in 1...6 {
            pasteboard.clearContents()
            #expect(pasteboard.setString("Item \(index)", forType: .string))
            history.captureIfChanged()
        }

        #expect(history.items.count == 5)
        #expect(text(from: history.items[0]) == "Item 6")
        #expect(text(from: history.items[4]) == "Item 2")
    }

    @Test("Copying the same item again moves it to the front")
    func movesDuplicateToFront() {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )

        for value in ["First", "Second", "First"] {
            pasteboard.clearContents()
            #expect(pasteboard.setString(value, forType: .string))
            history.captureIfChanged()
        }

        #expect(history.items.count == 2)
        #expect(text(from: history.items[0]) == "First")
        #expect(text(from: history.items[1]) == "Second")
    }

    @Test("A text pill restores its exact clipboard contents")
    func restoresText() throws {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )

        pasteboard.clearContents()
        #expect(pasteboard.setString("Restore me", forType: .string))
        history.captureIfChanged()
        pasteboard.clearContents()

        #expect(history.restore(try #require(history.items.first)))
        #expect(pasteboard.string(forType: .string) == "Restore me")
    }

    @Test("Image clipboard data is captured and restored")
    func restoresImage() throws {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )
        let image = NSImage(size: NSSize(width: 4, height: 4))
        image.lockFocus()
        NSColor.systemBlue.setFill()
        NSRect(origin: .zero, size: image.size).fill()
        image.unlockFocus()

        pasteboard.clearContents()
        #expect(pasteboard.writeObjects([image]))
        history.captureIfChanged()
        pasteboard.clearContents()

        let item = try #require(history.items.first)
        guard case .image = item.content else {
            Issue.record("Expected image clipboard content")
            return
        }
        #expect(history.restore(item))
        #expect(NSImage(pasteboard: pasteboard) != nil)
    }

    @Test("File URLs are captured together and restored")
    func restoresFiles() throws {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )
        let urls = [
            URL(fileURLWithPath: "/tmp/first.txt"),
            URL(fileURLWithPath: "/tmp/second.png"),
        ]

        pasteboard.clearContents()
        #expect(pasteboard.writeObjects(urls.map { $0 as NSURL }))
        history.captureIfChanged()
        pasteboard.clearContents()

        let item = try #require(history.items.first)
        #expect(item.content == .files(urls))
        #expect(history.restore(item))
        let restoredObjects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []
        let restored = restoredObjects.compactMap { object -> URL? in
            guard let fileURL = object as? NSURL else { return nil }
            return fileURL as URL
        }
        #expect(restored == urls)
    }

    @Test("Clearing history removes every item without changing the clipboard")
    func clearsHistory() {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )
        pasteboard.clearContents()
        #expect(pasteboard.setString("Keep on clipboard", forType: .string))
        history.captureIfChanged()

        history.clearHistory()

        #expect(history.items.isEmpty)
        #expect(pasteboard.string(forType: .string) == "Keep on clipboard")
    }

    @Test("Disabling clipboard history clears it and pauses capture")
    func disablesAndReenablesHistory() {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )
        pasteboard.clearContents()
        #expect(pasteboard.setString("Before", forType: .string))
        history.captureIfChanged()

        history.setEnabled(false)
        pasteboard.clearContents()
        #expect(pasteboard.setString("While disabled", forType: .string))
        history.captureIfChanged()

        #expect(history.items.isEmpty)

        history.setEnabled(true)
        history.captureIfChanged()
        #expect(text(from: history.items[0]) == "While disabled")
    }

    @Test("Smart clipboard labels recognize common text types")
    func detectsTextKind() {
        #expect(
            ClipboardTextKind.detect(in: "https://example.com/path") == .link
        )
        #expect(
            ClipboardTextKind.detect(in: "hello@example.com") == .email
        )
        #expect(
            ClipboardTextKind.detect(in: "+1 (415) 555-0123") == .phone
        )
        #expect(ClipboardTextKind.detect(in: "A normal thought") == .text)
    }

    @Test("Direct paste accepts text but rejects images and files")
    func directPasteIsTextOnly() {
        let pasteboard = makePasteboard()
        let history = ClipboardHistoryController(
            pasteboard: pasteboard,
            monitoringEnabled: false
        )

        pasteboard.clearContents()
        #expect(pasteboard.setString("Paste this", forType: .string))
        #expect(history.currentTextForPasting() == "Paste this")

        let image = NSImage(size: NSSize(width: 2, height: 2))
        pasteboard.clearContents()
        #expect(pasteboard.writeObjects([image]))
        #expect(history.currentTextForPasting() == nil)

        pasteboard.clearContents()
        #expect(
            pasteboard.writeObjects([
                URL(fileURLWithPath: "/tmp/not-text.png") as NSURL,
            ])
        )
        #expect(history.currentTextForPasting() == nil)
    }

    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: .init("StickyyTests.\(UUID().uuidString)"))
    }

    private func text(from item: ClipboardHistoryItem) -> String? {
        guard case .text(let text) = item.content else { return nil }
        return text
    }
}
