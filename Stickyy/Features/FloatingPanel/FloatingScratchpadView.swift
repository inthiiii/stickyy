import SwiftUI

struct FloatingScratchpadView: View {
    @Bindable var session: ScratchpadSession
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

            ZStack(alignment: .topLeading) {
                ScratchpadEditor(
                    text: $session.text,
                    focusRequest: session.editorFocusRequest,
                    insertionRequest: session.pendingTextInsertion,
                    onQuickPaste: { _ in },
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
}
