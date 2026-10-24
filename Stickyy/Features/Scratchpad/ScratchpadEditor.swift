import AppKit
import SwiftUI

struct ScratchpadEditor: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    let insertionRequest: ScratchpadTextInsertion?
    let onQuickPaste: (Int) -> Void
    let onPasteAttachment: (ClipboardHistoryContent) -> Void
    let onEscape: () -> Void
    var onCreateScratchpad: (() -> Void)? = nil
    var accessibilityIdentifier = "scratchpadEditor"
    var onInsertionApplied: (UUID) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.setAccessibilityLabel(
            String(localized: "Scratchpad editor")
        )
        scrollView.setAccessibilityIdentifier("\(accessibilityIdentifier)ScrollView")

        let textView = EscapeHandlingTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.textContainerInset = NSSize(
            width: StickyyMetrics.editorInset,
            height: StickyyMetrics.editorInset
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        textView.onEscape = onEscape
        textView.onQuickPaste = onQuickPaste
        textView.onPasteAttachment = onPasteAttachment
        textView.onCreateScratchpad = onCreateScratchpad
        textView.setAccessibilityLabel(String(localized: "Scratchpad"))
        textView.setAccessibilityIdentifier(accessibilityIdentifier)

        context.coordinator.textView = textView
        context.coordinator.refreshDetectedLinks()
        context.coordinator.lastFocusRequest = focusRequest
        context.coordinator.lastInsertionID = insertionRequest?.id
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? EscapeHandlingTextView else {
            return
        }

        context.coordinator.parent = self
        textView.onEscape = onEscape
        textView.onQuickPaste = onQuickPaste
        textView.onPasteAttachment = onPasteAttachment
        textView.onCreateScratchpad = onCreateScratchpad

        if textView.string != text {
            let selection = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(
                NSRange(
                    location: min(selection.location, text.utf16.count),
                    length: 0
                )
            )
            context.coordinator.refreshDetectedLinks()
        }

        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            textView.window?.makeFirstResponder(textView)
        }

        if let insertionRequest,
           context.coordinator.lastInsertionID != insertionRequest.id {
            context.coordinator.lastInsertionID = insertionRequest.id
            guard insertionRequest.consume() else { return }
            textView.window?.makeFirstResponder(textView)
            textView.insertText(
                insertionRequest.text,
                replacementRange: textView.selectedRange()
            )
            let insertionID = insertionRequest.id
            Task { @MainActor in
                onInsertionApplied(insertionID)
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScratchpadEditor
        weak var textView: NSTextView?
        var lastFocusRequest = 0
        var lastInsertionID: UUID?

        init(parent: ScratchpadEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            refreshDetectedLinks()
            parent.text = textView.string
        }

        func refreshDetectedLinks() {
            guard let textView,
                  let textStorage = textView.textStorage else { return }
            let fullRange = NSRange(
                location: 0,
                length: (textView.string as NSString).length
            )
            textStorage.beginEditing()
            textStorage.removeAttribute(.link, range: fullRange)
            if let detector = try? NSDataDetector(
                types: NSTextCheckingResult.CheckingType.link.rawValue
            ) {
                detector.enumerateMatches(
                    in: textView.string,
                    range: fullRange
                ) { result, _, _ in
                    guard let result, let url = result.url else { return }
                    textStorage.addAttribute(
                        .link,
                        value: url,
                        range: result.range
                    )
                }
            }
            textStorage.endEditing()
        }
    }
}

@MainActor
private final class EscapeHandlingTextView: NSTextView {
    var onEscape: () -> Void = {}
    var onQuickPaste: (Int) -> Void = { _ in }
    var onPasteAttachment: (ClipboardHistoryContent) -> Void = { _ in }
    var onCreateScratchpad: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        onEscape()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(
            .deviceIndependentFlagsMask
        )
        if modifiers == .command,
           let characters = event.charactersIgnoringModifiers,
           characters.lowercased() == "n",
           let onCreateScratchpad {
            onCreateScratchpad()
            return true
        }
        if modifiers == .command,
           let characters = event.charactersIgnoringModifiers,
           let number = Int(characters),
           (1...7).contains(number) {
            onQuickPaste(number - 1)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        if let string = insertString as? String,
           string == "-",
           selectedRange().length == 0,
           selectedRange().location >= 2 {
            let source = self.string as NSString
            let previousRange = NSRange(location: selectedRange().location - 2, length: 2)
            if source.substring(with: previousRange) == "--" {
                super.insertText("\n────────────\n", replacementRange: previousRange)
                return
            }
        }
        super.insertText(insertString, replacementRange: replacementRange)
    }

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]
        ) ?? []
        let urls = objects.compactMap { ($0 as? NSURL) as URL? }
        if !urls.isEmpty {
            onPasteAttachment(.files(urls))
            return
        }
        if let data = pasteboard.data(forType: .png) {
            onPasteAttachment(.image(data: data, pasteboardType: NSPasteboard.PasteboardType.png.rawValue, name: String(localized: "Pasted Image")))
            return
        }
        if let data = pasteboard.data(forType: .tiff) {
            onPasteAttachment(.image(data: data, pasteboardType: NSPasteboard.PasteboardType.tiff.rawValue, name: String(localized: "Pasted Image")))
            return
        }
        super.paste(sender)
    }
}
