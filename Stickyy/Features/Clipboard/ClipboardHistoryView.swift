import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @Bindable var history: ClipboardHistoryController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Label("Clipboard", systemImage: "clipboard")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Last 5")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if history.items.isEmpty {
                Text("Copy text, an image, or a file to begin.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .accessibilityIdentifier("emptyClipboardHistory")
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 6) {
                        ForEach(history.items) { item in
                            pill(for: item)
                        }
                    }
                }
                .scrollIndicators(.visible)
                .accessibilityIdentifier("clipboardHistory")
            }
        }
        .padding(.horizontal, StickyyMetrics.headerPadding)
        .padding(.vertical, 10)
        .frame(height: StickyyMetrics.clipboardHistoryHeight)
    }

    private func pill(for item: ClipboardHistoryItem) -> some View {
        Button {
            history.restore(item)
        } label: {
            HStack(spacing: 8) {
                preview(for: item)
                    .frame(width: 22, height: 22)

                Text(title(for: item))
                    .font(.caption)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Image(systemName: "arrow.up.doc")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(.capsule)
            .background(Color.primary.opacity(0.065), in: .capsule)
        }
        .buttonStyle(.plain)
        .help("Copy this item again")
        .accessibilityLabel(accessibilityLabel(for: item))
        .accessibilityHint("Copies this item back to the clipboard")
        .accessibilityIdentifier("clipboardHistoryItem_\(item.id)")
    }

    @ViewBuilder
    private func preview(for item: ClipboardHistoryItem) -> some View {
        switch item.content {
        case .text:
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)
        case .image(let data, _):
            if let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(.rect(cornerRadius: 5))
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        case .files(let urls):
            Image(systemName: urls.count == 1 ? "doc" : "doc.on.doc")
                .foregroundStyle(.secondary)
        }
    }

    private func title(for item: ClipboardHistoryItem) -> String {
        switch item.content {
        case .text(let text):
            return String(
                text
                .split(whereSeparator: \.isNewline)
                .joined(separator: " ")
                .prefix(120)
            )
        case .image:
            return String(localized: "Image")
        case .files(let urls):
            if urls.count == 1 {
                return urls[0].lastPathComponent
            }
            return String(localized: "\(urls.count) files")
        }
    }

    private func accessibilityLabel(for item: ClipboardHistoryItem) -> String {
        switch item.content {
        case .text:
            String(localized: "Clipboard text: \(title(for: item))")
        case .image:
            String(localized: "Clipboard image")
        case .files(let urls):
            String(localized: "Clipboard files: \(urls.map(\.lastPathComponent).joined(separator: ", "))")
        }
    }
}
