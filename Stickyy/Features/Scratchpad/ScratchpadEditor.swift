import AppKit
import SwiftUI

struct ScratchpadEditor: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    let insertionRequest: ScratchpadTextInsertion?
    let onQuickPaste: (Int) -> Void
    let onEscape: () -> Void

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
        scrollView.setAccessibilityIdentifier("scratchpadScrollView")

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
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.onEscape = onEscape
        textView.onQuickPaste = onQuickPaste
        textView.setAccessibilityLabel(String(localized: "Scratchpad"))
        textView.setAccessibilityIdentifier("scratchpadEditor")

        context.coordinator.textView = textView
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

        if textView.string != text {
            let selection = textView.selectedRange()
            textView.string = text
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
            textView.window?.makeFirstResponder(textView)
            textView.insertText(
                insertionRequest.text,
                replacementRange: textView.selectedRange()
            )
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
            parent.text = textView.string
        }
    }
}

@MainActor
private final class EscapeHandlingTextView: NSTextView {
    var onEscape: () -> Void = {}
    var onQuickPaste: (Int) -> Void = { _ in }

    override func cancelOperation(_ sender: Any?) {
        onEscape()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(
            .deviceIndependentFlagsMask
        )
        if modifiers == .command,
           let characters = event.charactersIgnoringModifiers,
           let number = Int(characters),
           (1...5).contains(number) {
            onQuickPaste(number - 1)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
