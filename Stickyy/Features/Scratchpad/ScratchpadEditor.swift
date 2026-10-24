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
        textView.typingBottomClearance = 50
        textView.setAccessibilityLabel(String(localized: "Scratchpad"))
        textView.setAccessibilityIdentifier(accessibilityIdentifier)

        textView.frame = scrollView.contentView.bounds
        context.coordinator.applyModelContent(to: textView)

        context.coordinator.textView = textView
        context.coordinator.lastFocusRequest = focusRequest
        context.coordinator.lastInsertionID = insertionRequest?.id
        context.coordinator.lastFormattingID = formattingRequest?.id
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
        context.coordinator.ensureVisibleEditorHeight(
            textView,
            in: scrollView
        )

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
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ScratchpadEditor
        fileprivate weak var textView: EscapeHandlingTextView?
        var lastFocusRequest = 0
        var lastInsertionID: UUID?
        var lastFormattingID: UUID?
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
            textView.refreshDocumentHeight()
            textView.keepSelectionAboveTypingControls()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView, !isApplyingModelContent else { return }
            textView.keepSelectionAboveTypingControls()
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
            textView.refreshDocumentHeight()
        }

        fileprivate func ensureVisibleEditorHeight(
            _ textView: EscapeHandlingTextView,
            in scrollView: NSScrollView
        ) {
            let visibleSize = scrollView.contentSize
            let sizeChanged = abs(
                textView.minimumDocumentHeight - visibleSize.height
            ) > 0.5 || abs(textView.frame.width - visibleSize.width) > 0.5
            guard sizeChanged else { return }

            textView.minimumDocumentHeight = visibleSize.height
            textView.minSize = NSSize(width: 0, height: visibleSize.height)
            if let textContainer = textView.textContainer,
               abs(textContainer.containerSize.width - visibleSize.width) > 0.5 {
                textContainer.containerSize = NSSize(
                    width: visibleSize.width,
                    height: CGFloat.greatestFiniteMagnitude
                )
            }
            if abs(textView.frame.width - visibleSize.width) > 0.5
                || textView.frame.height < visibleSize.height {
                textView.setFrameSize(
                    NSSize(
                        width: visibleSize.width,
                        height: max(textView.frame.height, visibleSize.height)
                    )
                )
            }
            textView.refreshDocumentHeight()
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
    var typingBottomClearance: CGFloat = 0
    var minimumDocumentHeight: CGFloat = 0
    private var caretVisibilityUpdateIsScheduled = false

    func refreshDocumentHeight() {
        guard let layoutManager, let textContainer else { return }
        layoutManager.ensureLayout(for: textContainer)
        let usedHeight = ceil(
            layoutManager.usedRect(for: textContainer).height
        )
        let requiredHeight = usedHeight
            + (textContainerInset.height * 2)
            + typingBottomClearance
        let targetHeight = max(minimumDocumentHeight, requiredHeight)
        guard abs(frame.height - targetHeight) > 0.5 else { return }
        setFrameSize(NSSize(width: frame.width, height: targetHeight))
    }

    func keepSelectionAboveTypingControls() {
        guard typingBottomClearance > 0,
              window?.firstResponder === self,
              !caretVisibilityUpdateIsScheduled else { return }
        caretVisibilityUpdateIsScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            caretVisibilityUpdateIsScheduled = false
            guard window?.firstResponder === self,
                  let scrollView = enclosingScrollView,
                  let layoutManager,
                  let textContainer else { return }
            layoutManager.ensureLayout(for: textContainer)

            let textLength = textStorage?.length ?? 0
            let selectionEnd = min(
                NSMaxRange(selectedRange()),
                textLength
            )
            let caretRect: NSRect
            if selectionEnd == textLength,
               layoutManager.extraLineFragmentTextContainer != nil {
                caretRect = layoutManager.extraLineFragmentRect
            } else if layoutManager.numberOfGlyphs > 0 {
                let characterIndex = min(
                    selectionEnd,
                    max(textLength - 1, 0)
                )
                let glyphIndex = min(
                    layoutManager.glyphIndexForCharacter(
                        at: characterIndex
                    ),
                    layoutManager.numberOfGlyphs - 1
                )
                caretRect = layoutManager.lineFragmentUsedRect(
                    forGlyphAt: glyphIndex,
                    effectiveRange: nil
                )
            } else {
                caretRect = NSRect(
                    x: 0,
                    y: 0,
                    width: 1,
                    height: font?.pointSize ?? 14
                )
            }

            let caretBottom = caretRect.maxY + textContainerInset.height
            let safeBottom = visibleRect.maxY - typingBottomClearance
            guard caretBottom > safeBottom else { return }

            let clipView = scrollView.contentView
            var origin = clipView.bounds.origin
            let maximumOriginY = max(
                0,
                frame.height - clipView.bounds.height
            )
            origin.y = min(
                maximumOriginY,
                origin.y + caretBottom - safeBottom
            )
            clipView.scroll(to: origin)
            scrollView.reflectScrolledClipView(clipView)
        }
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
