import SwiftUI

struct ScratchpadView: View {
    @Bindable var session: ScratchpadSession
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.colorScheme)
    private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            header

            if let persistenceError = session.persistenceError {
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(persistenceError)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Color.orange.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    in: .rect(cornerRadius: 12)
                )
                .padding(.horizontal, StickyyMetrics.editorOuterInset)
                .padding(.bottom, 8)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("persistenceError")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            editor
        }
        .frame(
            width: StickyyMetrics.popoverWidth,
            height: StickyyMetrics.popoverHeight
        )
        .stickyySurface()
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.18),
            value: session.persistenceError != nil
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(
                    width: StickyyMetrics.headerIconSize,
                    height: StickyyMetrics.headerIconSize
                )
                .background(
                    Color.accentColor.opacity(
                        colorScheme == .dark ? 0.15 : 0.10
                    ),
                    in: .rect(cornerRadius: 9)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(AppEnvironment.productName)
                    .font(.system(size: 14, weight: .semibold))

                Text(AppEnvironment.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            closeButton
        }
        .padding(.horizontal, StickyyMetrics.headerHorizontalPadding)
        .padding(.vertical, StickyyMetrics.headerVerticalPadding)
    }

    @ViewBuilder
    private var closeButton: some View {
        let button = Button(action: onDismiss) {
            Label("Close scratchpad", systemImage: "xmark")
                .labelStyle(.iconOnly)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .frame(
            width: StickyyMetrics.closeButtonSize,
            height: StickyyMetrics.closeButtonSize
        )
        .contentShape(.circle)
        .help("Close scratchpad")
        .accessibilityIdentifier("closeScratchpad")
        .keyboardShortcut(.escape, modifiers: [])

        if reduceTransparency {
            button.background(Color.primary.opacity(0.08), in: .circle)
        } else {
            button.glassEffect(.regular.interactive(), in: .circle)
        }
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
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, StickyyMetrics.editorInset)
                    .padding(.vertical, StickyyMetrics.editorInset + 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(
                cornerRadius: StickyyMetrics.editorCornerRadius,
                style: .continuous
            )
            .fill(
                Color.primary.opacity(colorScheme == .dark ? 0.045 : 0.025)
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: StickyyMetrics.editorCornerRadius,
                style: .continuous
            )
            .strokeBorder(Color.primary.opacity(0.075))
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: StickyyMetrics.editorCornerRadius,
                style: .continuous
            )
        )
        .padding(.horizontal, StickyyMetrics.editorOuterInset)
        .padding(.bottom, StickyyMetrics.editorOuterInset)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.12),
            value: session.text.isEmpty
        )
    }
}
