import AppKit
import SwiftUI

enum ScratchpadFormattingAction: Sendable {
    case bold
    case italic
    case underline
}

struct ScratchpadFormattingRequest: Equatable, Sendable {
    let id = UUID()
    let action: ScratchpadFormattingAction
}

struct ScratchpadEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var richTextData: Data?
    let focusRequest: Int
    let insertionRequest: ScratchpadTextInsertion?
    let formattingRequest: ScratchpadFormattingRequest?
    let sectionNavigationRequest: ScratchpadSectionNavigationRequest?
    let onQuickPaste: (Int) -> Void
    let onPasteAttachment: (ClipboardHistoryContent) -> Void
    let onEscape: () -> Void
    var onCreateScratchpad: (() -> Void)? = nil
    var accessibilityIdentifier = "scratchpadEditor"
    var onInsertionApplied: (UUID) -> Void = { _ in }
    var onFormattingApplied: (UUID) -> Void = { _ in }

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
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(
            top: 0,
            left: 0,
            bottom: 50,
            right: 0
        )
        scrollView.setAccessibilityLabel(
            String(localized: "Scratchpad editor")
        )
        scrollView.setAccessibilityIdentifier("\(accessibilityIdentifier)ScrollView")

        let textView = EscapeHandlingTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
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
        textView.minSize = NSSize(
            width: 0,
            height: scrollView.contentSize.height
        )
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = true
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
        textView.placeholder = String(localized: "Start typing…")
        textView.setAccessibilityLabel(String(localized: "Scratchpad"))
        textView.setAccessibilityIdentifier(accessibilityIdentifier)

        textView.frame = scrollView.contentView.bounds
        context.coordinator.applyModelContent(to: textView)

        context.coordinator.textView = textView
        context.coordinator.lastFocusRequest = focusRequest
        context.coordinator.lastInsertionID = insertionRequest?.id
        context.coordinator.lastFormattingID = formattingRequest?.id
        context.coordinator.lastSectionNavigationID = sectionNavigationRequest?.id
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

        if context.coordinator.shouldApplyModelContent(
            text: text,
            richTextData: richTextData
        ) {
            let selection = textView.selectedRange()
            context.coordinator.applyModelContent(to: textView)
            textView.setSelectedRange(
                NSRange(
                    location: min(selection.location, text.utf16.count),
                    length: 0
                )
            )
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

        if let formattingRequest,
           context.coordinator.lastFormattingID != formattingRequest.id {
            context.coordinator.lastFormattingID = formattingRequest.id
            textView.window?.makeFirstResponder(textView)
            context.coordinator.applyFormatting(
                formattingRequest.action,
                to: textView
            )
            let formattingID = formattingRequest.id
            Task { @MainActor in
                onFormattingApplied(formattingID)
            }
        }

        if let sectionNavigationRequest,
           context.coordinator.lastSectionNavigationID
               != sectionNavigationRequest.id {
            context.coordinator.lastSectionNavigationID =
                sectionNavigationRequest.id
            context.coordinator.navigate(
                to: sectionNavigationRequest.location,
                in: textView
            )
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScratchpadEditor
        fileprivate weak var textView: EscapeHandlingTextView?
        var lastFocusRequest = 0
        var lastInsertionID: UUID?
        var lastFormattingID: UUID?
        var lastSectionNavigationID: UUID?
        var lastPushedRichTextData: Data?
        var isApplyingModelContent = false
        private var richTextSyncTask: Task<Void, Never>?

        init(parent: ScratchpadEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView, !isApplyingModelContent else { return }
            parent.text = textView.string
            scheduleRichTextSync(from: textView)
        }

        func shouldApplyModelContent(
            text: String,
            richTextData: Data?
        ) -> Bool {
            guard let textView else { return true }
            return textView.string != text
                || (richTextData != nil
                    && richTextData != lastPushedRichTextData)
        }

        fileprivate func applyModelContent(
            to textView: EscapeHandlingTextView
        ) {
            richTextSyncTask?.cancel()
            richTextSyncTask = nil
            isApplyingModelContent = true
            defer { isApplyingModelContent = false }

            let attributedText: NSAttributedString
            if let data = parent.richTextData,
               let restored = NSAttributedString(
                   rtf: data,
                   documentAttributes: nil
               ),
               restored.string == parent.text {
                attributedText = restored
                lastPushedRichTextData = data
            } else {
                attributedText = NSAttributedString(
                    string: parent.text,
                    attributes: [
                        .font: NSFont.preferredFont(forTextStyle: .body),
                        .foregroundColor: NSColor.labelColor,
                    ]
                )
                lastPushedRichTextData = nil
            }
            textView.textStorage?.setAttributedString(attributedText)
        }

        func applyFormatting(
            _ action: ScratchpadFormattingAction,
            to textView: NSTextView
        ) {
            switch action {
            case .bold:
                toggleFontTrait(.boldFontMask, in: textView)
            case .italic:
                toggleFontTrait(.italicFontMask, in: textView)
            case .underline:
                toggleUnderline(in: textView)
            }
            textDidChange(Notification(name: NSText.didChangeNotification))
        }

        func navigate(to location: Int, in textView: NSTextView) {
            let safeLocation = min(max(location, 0), textView.string.utf16.count)
            textView.scrollRangeToVisible(
                NSRange(location: safeLocation, length: 0)
            )
        }

        private func toggleFontTrait(
            _ trait: NSFontTraitMask,
            in textView: NSTextView
        ) {
            let range = textView.selectedRange()
            let fontManager = NSFontManager.shared
            if range.length == 0 {
                let current = textView.typingAttributes[.font] as? NSFont
                    ?? NSFont.preferredFont(forTextStyle: .body)
                let hasTrait = fontManager.traits(of: current).contains(trait)
                var attributes = textView.typingAttributes
                attributes[.font] = hasTrait
                    ? fontManager.convert(current, toNotHaveTrait: trait)
                    : fontManager.convert(current, toHaveTrait: trait)
                textView.typingAttributes = attributes
                return
            }

            guard let textStorage = textView.textStorage else { return }
            var everyRunHasTrait = true
            textStorage.enumerateAttribute(
                .font,
                in: range
            ) { value, _, _ in
                let font = value as? NSFont
                    ?? NSFont.preferredFont(forTextStyle: .body)
                if !fontManager.traits(of: font).contains(trait) {
                    everyRunHasTrait = false
                }
            }
            textStorage.enumerateAttribute(
                .font,
                in: range
            ) { value, runRange, _ in
                let font = value as? NSFont
                    ?? NSFont.preferredFont(forTextStyle: .body)
                let converted = everyRunHasTrait
                    ? fontManager.convert(font, toNotHaveTrait: trait)
                    : fontManager.convert(font, toHaveTrait: trait)
                textStorage.addAttribute(.font, value: converted, range: runRange)
            }
        }

        private func toggleUnderline(in textView: NSTextView) {
            let range = textView.selectedRange()
            if range.length == 0 {
                var attributes = textView.typingAttributes
                let current = attributes[.underlineStyle] as? Int ?? 0
                attributes[.underlineStyle] = current == 0
                    ? NSUnderlineStyle.single.rawValue
                    : 0
                textView.typingAttributes = attributes
                return
            }

            guard let textStorage = textView.textStorage else { return }
            var everyRunIsUnderlined = true
            textStorage.enumerateAttribute(
                .underlineStyle,
                in: range
            ) { value, _, _ in
                if (value as? Int ?? 0) == 0 {
                    everyRunIsUnderlined = false
                }
            }
            textStorage.addAttribute(
                .underlineStyle,
                value: everyRunIsUnderlined
                    ? 0
                    : NSUnderlineStyle.single.rawValue,
                range: range
            )
        }

        private func serializedRichText(from textView: NSTextView) -> Data? {
            guard let textStorage = textView.textStorage else { return nil }
            return textStorage.rtf(
                from: NSRange(location: 0, length: textStorage.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
        }

        private func scheduleRichTextSync(
            from textView: EscapeHandlingTextView
        ) {
            richTextSyncTask?.cancel()
            richTextSyncTask = Task { @MainActor [weak self, weak textView] in
                do {
                    try await Task.sleep(for: .milliseconds(120))
                } catch {
                    return
                }
                guard !Task.isCancelled,
                      let self,
                      let textView,
                      !isApplyingModelContent else { return }
                let data = serializedRichText(from: textView)
                lastPushedRichTextData = data
                parent.richTextData = data
                richTextSyncTask = nil
            }
        }
    }
}

@MainActor
fileprivate final class EscapeHandlingTextView: NSTextView {
    var onEscape: () -> Void = {}
    var onQuickPaste: (Int) -> Void = { _ in }
    var onPasteAttachment: (ClipboardHistoryContent) -> Void = { _ in }
    var onCreateScratchpad: (() -> Void)?
    var placeholder = ""

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, !placeholder.isEmpty else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: font ?? NSFont.preferredFont(forTextStyle: .body),
                .foregroundColor: NSColor.tertiaryLabelColor,
                .paragraphStyle: paragraphStyle,
            ]
        )
        let linePadding = textContainer?.lineFragmentPadding ?? 0
        attributedPlaceholder.draw(
            at: NSPoint(
                x: textContainerOrigin.x + linePadding,
                y: textContainerOrigin.y
            )
        )
    }

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
        guard let insertedText = insertString as? String,
              selectedRange().length == 0 else {
            super.insertText(insertString, replacementRange: replacementRange)
            return
        }

        let cursor = selectedRange().location
        let source = string as NSString

        if insertedText == "-", cursor >= 2 {
            let previousRange = NSRange(location: cursor - 2, length: 2)
            if source.substring(with: previousRange) == "--" {
                let hasTextBeforeDivider = previousRange.location > 0
                    && source.character(at: previousRange.location - 1) != 10
                    && source.character(at: previousRange.location - 1) != 13
                let prefix = hasTextBeforeDivider ? "\n" : ""
                super.insertText(
                    "\(prefix)\(ScratchpadSections.divider)\n",
                    replacementRange: previousRange
                )
                return
            }
        }

        if insertedText == ">", cursor >= 1 {
            let previousRange = NSRange(location: cursor - 1, length: 1)
            if source.substring(with: previousRange) == "-" {
                super.insertText("→", replacementRange: previousRange)
                return
            }
        }

        if insertedText == " ", cursor >= 1 {
            let hyphenRange = NSRange(location: cursor - 1, length: 1)
            let startsLine = hyphenRange.location == 0
                || source.character(at: hyphenRange.location - 1) == 10
                || source.character(at: hyphenRange.location - 1) == 13
            if startsLine, source.substring(with: hyphenRange) == "-" {
                super.insertText("• ", replacementRange: hyphenRange)
                return
            }
        }

        super.insertText(insertString, replacementRange: replacementRange)
    }

    override func insertNewline(_ sender: Any?) {
        let source = string as NSString
        let cursor = selectedRange().location
        let lineRange = source.lineRange(
            for: NSRange(location: min(cursor, source.length), length: 0)
        )
        let contentEnd = min(cursor, NSMaxRange(lineRange))
        let contentRange = NSRange(
            location: lineRange.location,
            length: max(0, contentEnd - lineRange.location)
        )
        let currentLine = source.substring(with: contentRange)

        if currentLine == "• " {
            super.insertText("\n", replacementRange: contentRange)
            return
        }
        if currentLine.hasPrefix("• ") {
            super.insertText("\n• ", replacementRange: selectedRange())
            return
        }
        super.insertNewline(sender)
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
