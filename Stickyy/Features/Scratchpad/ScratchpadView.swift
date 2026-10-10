import SwiftUI

struct ScratchpadView: View {
    @Bindable var session: ScratchpadSession
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)

                Text(AppEnvironment.productName)
                    .font(.headline)

                Spacer()

                Text(AppEnvironment.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(StickyyMetrics.headerPadding)

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
        }
        .frame(
            width: StickyyMetrics.popoverWidth,
            height: StickyyMetrics.popoverHeight
        )
        .background {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                Rectangle().fill(.regularMaterial)
            }
        }
    }
}
