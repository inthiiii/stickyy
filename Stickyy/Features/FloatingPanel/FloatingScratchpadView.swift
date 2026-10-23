import SwiftUI

struct FloatingScratchpadView: View {
    @Bindable var session: ScratchpadSession
    @Bindable var clipboardHistory: ClipboardHistoryController
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let persistenceError = session.persistenceError {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(persistenceError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, StickyyMetrics.editorInset)
                .padding(.vertical, 9)
                .background(Color.orange.opacity(0.08))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("floatingPanelPersistenceError")

                Divider()
            }

            ZStack(alignment: .bottomTrailing) {
                ScratchpadEditor(
                    text: $session.text,
                    focusRequest: session.editorFocusRequest,
                    insertionRequest: session.pendingTextInsertion,
                    onQuickPaste: quickPaste,
                    onPasteAttachment: session.addAttachments,
                    onEscape: onDismiss,
                    accessibilityIdentifier: "floatingScratchpadEditor",
                    onInsertionApplied: session.didApplyTextInsertion
                )
                .accessibilityLabel("Floating scratchpad")
                .accessibilityIdentifier("floatingScratchpadEditor")

                if session.text.isEmpty {
                    Text("Start typing…")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, StickyyMetrics.editorInset + 4)
                        .padding(.vertical, StickyyMetrics.editorInset + 2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                if clipboardHistory.isEnabled,
                   let latestItem = clipboardHistory.items.first {
                    Button {
                        insert(latestItem)
                    } label: {
                        Label(
                            floatingClipboardTitle(for: latestItem),
                            systemImage: floatingClipboardIcon(for: latestItem)
                        )
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: 142)
                        .padding(.horizontal, 9)
                        .frame(height: 28)
                    }
                    .buttonStyle(.plain)
                    .stickyyPillSurface(Capsule())
                    .overlay {
                        Capsule().strokeBorder(Color.primary.opacity(0.1))
                    }
                    .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                    .padding(10)
                    .help("Add the latest clipboard item to this note")
                    .accessibilityLabel("Add latest clipboard item")
                    .accessibilityIdentifier("floatingRecentClipboard")
                }
            }

            if !session.activeAttachments.isEmpty {
                Divider()
                ScratchpadAttachmentsView(
                    attachments: session.activeAttachments,
                    onRemove: session.removeAttachment
                )
            }
        }
        .frame(
            minWidth: StickyyMetrics.floatingPanelMinWidth,
            minHeight: StickyyMetrics.floatingPanelMinHeight
        )
        .stickyySurface()
        .clipShape(
            RoundedRectangle(
                cornerRadius: StickyyMetrics.floatingPanelCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: StickyyMetrics.floatingPanelCornerRadius,
                style: .continuous
            )
            .strokeBorder(Color.primary.opacity(0.12))
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("floatingScratchpadPanel")
    }

    private func quickPaste(_ index: Int) {
        guard let item = clipboardHistory.item(at: index) else {
            NSSound.beep()
            return
        }
        insert(item)
    }

    private func insert(_ item: ClipboardHistoryItem) {
        switch item.content {
        case .text(let text):
            session.insertIntoEditor(text)
        case .files(let urls):
            session.addAttachments(from: .files(urls))
        case .image(let data, let pasteboardType, let name):
            session.addAttachments(
                from: .image(
                    data: data,
                    pasteboardType: pasteboardType,
                    name: name
                )
            )
        }
    }

    private func floatingClipboardIcon(
        for item: ClipboardHistoryItem
    ) -> String {
        switch item.content {
        case .text(let text):
            ClipboardTextKind.detect(in: text).systemImage
        case .image:
            "photo"
        case .files(let urls):
            urls.count == 1 ? "doc" : "doc.on.doc"
        }
    }

    private func floatingClipboardTitle(
        for item: ClipboardHistoryItem
    ) -> String {
        switch item.content {
        case .text(let text):
            String(
                text
                    .split(whereSeparator: \.isNewline)
                    .joined(separator: " ")
                    .prefix(36)
            )
        case .image(_, _, let name):
            name
        case .files(let urls):
            urls.count == 1
                ? urls[0].lastPathComponent
                : String(localized: "\(urls.count) files")
        }
    }
}
