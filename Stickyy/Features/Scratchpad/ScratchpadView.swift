import AppKit
import SwiftUI

struct ScratchpadView: View {
    @Bindable var session: ScratchpadSession
    @Bindable var clipboardHistory: ClipboardHistoryController
    let onDismiss: () -> Void

    @State private var showsLibrary = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let persistenceError = session.persistenceError {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(persistenceError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, StickyyMetrics.headerPadding)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.08))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("persistenceError")

                Divider()
            }

            editor
        }
        .frame(
            width: StickyyMetrics.popoverWidth,
            height: StickyyMetrics.popoverHeight
        )
        .stickyySurface()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                showsLibrary.toggle()
            } label: {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Scratchpads")
            .accessibilityLabel("Scratchpads")
            .accessibilityHint("Show all scratchpads")
            .accessibilityIdentifier("scratchpadLibrary")
            .popover(isPresented: $showsLibrary, arrowEdge: .bottom) {
                ScratchpadLibraryView(session: session) {
                    showsLibrary = false
                }
            }

            Text(AppEnvironment.productName)
                .font(.headline)

            Spacer()

            Text(AppEnvironment.tagline)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ShareLink(
                item: notesExportText,
                subject: Text(verbatim: session.activeTitle)
            ) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .disabled(session.text.isEmpty)
            .help("Export to Apple Notes")
            .accessibilityLabel("Export to Apple Notes")
            .accessibilityHint("Opens the macOS share sheet; choose Notes")
            .accessibilityIdentifier("exportToAppleNotes")
        }
        .padding(StickyyMetrics.headerPadding)
    }

    private var notesExportText: String {
        "\(session.activeTitle)\n\n\(session.text)"
    }

    private var editor: some View {
        ZStack(alignment: .bottomTrailing) {
            ScratchpadEditor(
                text: $session.text,
                focusRequest: session.editorFocusRequest,
                insertionRequest: session.pendingTextInsertion,
                onQuickPaste: quickPaste,
                onEscape: onDismiss
            )
            .accessibilityLabel("Scratchpad")
            .accessibilityIdentifier("scratchpadEditor")

            if session.text.isEmpty {
                Text("Start typing…")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, StickyyMetrics.editorInset + 4)
                    .padding(.vertical, StickyyMetrics.editorInset + 2)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            if !clipboardHistory.isEnabled {
                Button {
                    pasteCurrentClipboardText()
                } label: {
                    Image(systemName: "clipboard")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .background(.regularMaterial, in: .circle)
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(0.1))
                }
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                .padding(10)
                .help("Paste into Stickyy")
                .accessibilityLabel("Paste into Stickyy")
                .accessibilityIdentifier("pasteCurrentClipboardText")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pasteCurrentClipboardText() {
        guard let text = clipboardHistory.currentTextForPasting() else {
            NSSound.beep()
            return
        }
        session.insertIntoEditor(text)
    }

    private func quickPaste(_ index: Int) {
        guard let item = clipboardHistory.item(at: index) else {
            NSSound.beep()
            return
        }

        switch item.content {
        case .text(let text):
            session.insertIntoEditor(text)
        case .files(let urls):
            session.insertIntoEditor(
                urls.map(\.path).joined(separator: "\n")
            )
        case .image:
            clipboardHistory.restore(item)
            NSSound.beep()
        }
    }
}
