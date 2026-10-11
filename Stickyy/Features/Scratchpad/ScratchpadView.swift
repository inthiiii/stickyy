import SwiftUI

struct ScratchpadView: View {
    @Bindable var session: ScratchpadSession
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
        }
        .padding(StickyyMetrics.headerPadding)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            ScratchpadEditor(
                text: $session.text,
                focusRequest: session.editorFocusRequest,
                onEscape: onDismiss
            )
            .accessibilityLabel("Scratchpad")
            .accessibilityIdentifier("scratchpadEditor")

            if session.text.isEmpty {
                Text("Start typing…")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, StickyyMetrics.editorInset + 4)
                    .padding(.vertical, StickyyMetrics.editorInset + 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
