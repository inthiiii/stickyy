import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @Bindable var history: ClipboardHistoryController
    let onPasteText: (String) -> Void

    var body: some View {
        HStack(spacing: 5) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 5) {
                    if history.items.isEmpty {
                        emptyPill
                    } else {
                        ForEach(
                            Array(history.items.enumerated()),
                            id: \.element.id
                        ) { index, item in
                            pill(for: item, position: index + 1)
                        }
                    }
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 3)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Clipboard History")
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("clipboardHistory")

            if !history.items.isEmpty {
                Button {
                    history.clearHistory()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .stickyyPillSurface(Circle())
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(0.1))
                }
                .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                .help("Clear Clipboard History")
                .accessibilityLabel("Clear Clipboard History")
                .accessibilityIdentifier("clearClipboardHistory")
            }
        }
        .frame(
            width: StickyyMetrics.popoverWidth,
            height: StickyyMetrics.clipboardShelfHeight
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Clipboard History")
        .accessibilityIdentifier("clipboardShelf")
    }

    private var emptyPill: some View {
        Label("Clipboard is ready", systemImage: "clipboard")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .stickyyPillSurface(Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.1))
            }
            .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
            .accessibilityIdentifier("emptyClipboardHistory")
    }

    private func pill(
        for item: ClipboardHistoryItem,
        position: Int
    ) -> some View {
        HStack(spacing: 5) {
            Button {
                history.restore(item)
            } label: {
                HStack(spacing: 5) {
                    preview(for: item)
                        .frame(width: 18, height: 18)

                    Text(title(for: item))
                        .font(.caption2)
                        .lineLimit(1)
                        .frame(maxWidth: 125, alignment: .leading)

                    Text("⌘\(position)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help("Copy this item again")
            .accessibilityLabel(accessibilityLabel(for: item))
            .accessibilityHint("Copies this item back to the clipboard")
            .accessibilityIdentifier("clipboardHistoryItem_\(item.id)")

            if case .text(let text) = item.content {
                Button("Paste") {
                    onPasteText(text)
                }
                .buttonStyle(.borderless)
                .font(.caption2.weight(.semibold))
                .help("Paste into Stickyy")
                .accessibilityIdentifier("pasteClipboardText_\(position)")
            }
        }
        .padding(.leading, 7)
        .padding(.trailing, 8)
        .frame(height: 32)
        .stickyyPillSurface(Capsule())
        .overlay {
            Capsule().strokeBorder(Color.primary.opacity(0.1))
        }
        .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel(for: item))
    }

    @ViewBuilder
    private func preview(for item: ClipboardHistoryItem) -> some View {
        switch item.content {
        case .text(let text):
            Image(systemName: ClipboardTextKind.detect(in: text).systemImage)
                .foregroundStyle(.secondary)
        case .image(let data, _, _):
            if let image = NSImage(data: data) {
                circularImage(image)
            } else {
                fallbackImageIcon
            }
        case .files(let urls):
            if urls.count == 1,
               let image = NSImage(contentsOf: urls[0]) {
                circularImage(image)
            } else {
                Image(systemName: urls.count == 1 ? "doc" : "doc.on.doc")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func circularImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .clipShape(.circle)
            .overlay {
                Circle().strokeBorder(Color.primary.opacity(0.12))
            }
    }

    private var fallbackImageIcon: some View {
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    }

    private func title(for item: ClipboardHistoryItem) -> String {
        switch item.content {
        case .text(let text):
            return String(
                text
                    .split(whereSeparator: \.isNewline)
                    .joined(separator: " ")
                    .prefix(80)
            )
        case .image(_, _, let name):
            return name
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
            String(localized: "Clipboard image: \(title(for: item))")
        case .files(let urls):
            String(
                localized: "Clipboard files: \(urls.map(\.lastPathComponent).joined(separator: ", "))"
            )
        }
    }
}
