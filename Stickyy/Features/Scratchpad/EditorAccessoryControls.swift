import SwiftUI

struct ScratchpadFormattingControls: View {
    let onSelect: (ScratchpadFormattingAction) -> Void

    var body: some View {
        HStack(spacing: 2) {
            formattingButton("bold", label: "Bold", action: .bold)
            formattingButton("italic", label: "Italic", action: .italic)
            formattingButton("underline", label: "Underline", action: .underline)
        }
        .padding(3)
        .stickyyPillSurface(Capsule())
        .overlay {
            Capsule().strokeBorder(Color.primary.opacity(0.1))
        }
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    private func formattingButton(
        _ systemImage: String,
        label: LocalizedStringKey,
        action: ScratchpadFormattingAction
    ) -> some View {
        Button {
            onSelect(action)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 22)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

struct ScratchpadTextCountLabel: View {
    let text: String
    let mode: TextCountMode

    var body: some View {
        Text(TextCount.label(for: text, mode: mode))
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .frame(height: 28)
            .stickyyPillSurface(Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.08))
            }
            .accessibilityIdentifier("scratchpadTextCount")
    }
}
