import SwiftUI

struct FloatingScratchpadView: View {
    @Bindable var session: ScratchpadSession
    @Bindable var clipboardHistory: ClipboardHistoryController
    let onDismiss: () -> Void

    @State private var formattingRequest: ScratchpadFormattingRequest?
    @State private var sectionNavigationRequest:
        ScratchpadSectionNavigationRequest?

    @AppStorage(StickyyPreferences.showsTextCount)
    private var showsTextCount = false

    @AppStorage(StickyyPreferences.showsSectionNavigator)
    private var showsSectionNavigator = true

    @AppStorage(StickyyPreferences.textCountMode)
    private var textCountMode = TextCountMode.words.rawValue

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
                    richTextData: $session.richTextData,
                    focusRequest: session.editorFocusRequest,
                    insertionRequest: session.pendingTextInsertion,
                    formattingRequest: formattingRequest,
                    sectionNavigationRequest: sectionNavigationRequest,
                    onQuickPaste: quickPaste,
                    onPasteAttachment: session.addAttachments,
                    onEscape: onDismiss,
                    accessibilityIdentifier: "floatingScratchpadEditor",
                    onInsertionApplied: session.didApplyTextInsertion,
                    onFormattingApplied: didApplyFormatting
                )
                .accessibilityLabel("Floating scratchpad")
                .accessibilityIdentifier("floatingScratchpadEditor")

                if showsSectionNavigator {
                    ScratchpadSectionNavigator(
                        text: session.text,
                        accessibilityPrefix: "floatingScratchpad"
                    ) { location in
                        sectionNavigationRequest =
                            ScratchpadSectionNavigationRequest(
                                location: location
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )
                }

                HStack(alignment: .bottom, spacing: 8) {
                    ScratchpadFormattingControls { action in
                        formattingRequest = ScratchpadFormattingRequest(
                            action: action
                        )
                    }

                    Spacer(minLength: 8)

                    if showsTextCount {
                        ScratchpadTextCountLabel(
                            text: session.text,
                            mode: selectedTextCountMode
                        )
                    }

                    if clipboardHistory.isEnabled,
                       let latestItem = clipboardHistory.latestTextItem {
                        Button {
                            insert(latestItem)
                        } label: {
                            Image(systemName: "text.quote")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                        .stickyyPillSurface(Circle())
                        .overlay {
                            Circle().strokeBorder(Color.primary.opacity(0.1))
                        }
                        .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                        .help("Add the latest copied text to this note")
                        .accessibilityLabel("Add latest copied text")
                        .accessibilityIdentifier("floatingRecentClipboard")
                    }
                }
                .padding(10)
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
        guard case .text = item.content else {
            NSSound.beep()
            return
        }
        insert(item)
    }

    private func insert(_ item: ClipboardHistoryItem) {
        switch item.content {
        case .text(let text):
            session.insertIntoEditor(text)
        case .files, .image:
            NSSound.beep()
        }
    }

    private var selectedTextCountMode: TextCountMode {
        TextCountMode(rawValue: textCountMode) ?? .words
    }

    private func didApplyFormatting(_ id: UUID) {
        guard formattingRequest?.id == id else { return }
        formattingRequest = nil
    }
}
