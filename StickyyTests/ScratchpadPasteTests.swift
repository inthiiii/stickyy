import AppKit
import Testing
@testable import Stickyy

@MainActor
struct ScratchpadPasteTests {
    @Test("Plain-text paste ignores rich clipboard formatting")
    func plainTextWinsOverRichText() throws {
        let pasteboard = NSPasteboard(
            name: .init("StickyyPasteTests.\(UUID().uuidString)")
        )
        pasteboard.declareTypes([.string, .rtf], owner: nil)
        #expect(
            pasteboard.setString(
                "A formatted thought",
                forType: .string
            )
        )

        let attributed = NSAttributedString(
            string: "A formatted thought",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.systemBlue,
            ]
        )
        let rtf = try #require(
            attributed.rtf(
                from: NSRange(location: 0, length: attributed.length),
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf
                ]
            )
        )
        #expect(pasteboard.setData(rtf, forType: .rtf))

        #expect(
            ScratchpadPasteboardContent.plainText(from: pasteboard)
                == "A formatted thought"
        )
    }

    @Test("RTF-only clipboard content is converted to plain text")
    func convertsRTFOnlyContent() throws {
        let pasteboard = NSPasteboard(
            name: .init("StickyyPasteTests.\(UUID().uuidString)")
        )
        pasteboard.declareTypes([.rtf], owner: nil)

        let attributed = NSAttributedString(
            string: "Text from a formatted document",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.systemPurple,
            ]
        )
        let rtf = try #require(
            attributed.rtf(
                from: NSRange(location: 0, length: attributed.length),
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf
                ]
            )
        )
        #expect(pasteboard.setData(rtf, forType: .rtf))

        #expect(
            ScratchpadPasteboardContent.plainText(from: pasteboard)
                == "Text from a formatted document"
        )
    }

    @Test("Plain-text paste returns nil without textual clipboard content")
    func rejectsNonTextClipboardContent() {
        let pasteboard = NSPasteboard(
            name: .init("StickyyPasteTests.\(UUID().uuidString)")
        )
        pasteboard.clearContents()

        #expect(
            ScratchpadPasteboardContent.plainText(from: pasteboard) == nil
        )
    }
}
