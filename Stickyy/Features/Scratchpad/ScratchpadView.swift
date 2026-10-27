import AppKit
import SwiftUI

struct ScratchpadView: View {
    @Bindable var session: ScratchpadSession
    @Bindable var clipboardHistory: ClipboardHistoryController
    let onDismiss: () -> Void

    @State private var showsLibrary = false
    @State private var showsActiveTitle = false
    @State private var titleResetTask: Task<Void, Never>?
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
        .onDisappear {
            titleResetTask?.cancel()
            titleResetTask = nil
            showsActiveTitle = false
        }
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

            Button {
                toggleHeaderTitle()
            } label: {
                Text(
                    showsActiveTitle
                        ? session.activeTitle
                        : AppEnvironment.productName
                )
                .font(.headline)
                .lineLimit(1)
                .contentTransition(.opacity)
            }
            .buttonStyle(.plain)
            .help(
                showsActiveTitle
                    ? "Show Stickyy"
                    : "Show the current note title"
            )
            .accessibilityLabel(
                showsActiveTitle
                    ? session.activeTitle
                    : AppEnvironment.productName
            )
            .accessibilityIdentifier("scratchpadHeaderTitle")

            Spacer()

            NativeShareButton(text: notesExportText, isEnabled: !session.text.isEmpty)
                .frame(width: 24, height: 24)
                .disabled(session.text.isEmpty)
        }
        .padding(StickyyMetrics.headerPadding)
    }

    private var notesExportText: String {
        "\(session.activeTitle)\n\n\(session.text)"
    }

    private var editor: some View {
        VStack(spacing: 0) {
            editorCanvas
            if !session.activeAttachments.isEmpty {
                Divider()
                ScratchpadAttachmentsView(
                    attachments: session.activeAttachments,
                    onRemove: session.removeAttachment
                )
            }
        }
    }

    private var editorCanvas: some View {
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
                onCreateScratchpad: { _ = session.createScratchpad() },
                onInsertionApplied: session.didApplyTextInsertion,
                onFormattingApplied: didApplyFormatting
            )
            .accessibilityLabel("Scratchpad")
            .accessibilityIdentifier("scratchpadEditor")

            if showsSectionNavigator {
                ScratchpadSectionNavigator(
                    text: session.text,
                    accessibilityPrefix: "scratchpad"
                ) { location in
                    sectionNavigationRequest =
                        ScratchpadSectionNavigationRequest(location: location)
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

                if !clipboardHistory.isEnabled
                    && clipboardHistory.hasPasteableText {
                    Button {
                        pasteCurrentClipboardText()
                    } label: {
                        Image(systemName: "clipboard")
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .stickyyPillSurface(Circle())
                    .overlay {
                        Circle().strokeBorder(Color.primary.opacity(0.1))
                    }
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .help("Paste into Stickyy")
                    .accessibilityLabel("Paste into Stickyy")
                    .accessibilityIdentifier("pasteCurrentClipboardText")
                }
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectedTextCountMode: TextCountMode {
        TextCountMode(rawValue: textCountMode) ?? .words
    }

    private func didApplyFormatting(_ id: UUID) {
        guard formattingRequest?.id == id else { return }
        formattingRequest = nil
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
            session.addAttachments(from: .files(urls))
        case .image(let data, let pasteboardType, let name):
            session.addAttachments(
                from: .image(data: data, pasteboardType: pasteboardType, name: name)
            )
        }
    }

    private func toggleHeaderTitle() {
        titleResetTask?.cancel()
        titleResetTask = nil

        if showsActiveTitle {
            withAnimation(.easeInOut(duration: 0.18)) {
                showsActiveTitle = false
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            showsActiveTitle = true
        }
        titleResetTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showsActiveTitle = false
                }
                titleResetTask = nil
            }
        }
    }
}
