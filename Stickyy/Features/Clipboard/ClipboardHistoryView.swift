import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    @Bindable var history: ClipboardHistoryController
    let onPasteText: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme

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
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .stickyyPillSurface(Circle())
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(0.1))
                }
                .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
                .help(
                    history.pinningEnabled
                        ? "Clear unpinned Clipboard Pills"
                        : "Clear Clipboard History"
                )
                .accessibilityLabel(
                    history.pinningEnabled
                        ? "Clear unpinned Clipboard Pills"
                        : "Clear Clipboard History"
                )
                .accessibilityIdentifier("clearClipboardHistory")
            }
        }
        .padding(.trailing, 7)
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
            .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(colorScheme == .dark ? Color.black : Color.white, in: Capsule())
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
            Button(action: {}) {
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
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    history.restore(item)
                }
            )
            .help("Double-click to copy this item again")
            .accessibilityLabel(accessibilityLabel(for: item))
            .accessibilityHint("Double-click to copy this item back to the clipboard")
            .accessibilityAction {
                history.restore(item)
            }
            .accessibilityIdentifier("clipboardHistoryItem_\(item.id)")

            if history.pinningEnabled {
                Button {
                    history.togglePin(item)
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 16, height: 18)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin this pill" : "Pin this pill")
                .accessibilityLabel(
                    item.isPinned ? "Unpin Clipboard Pill" : "Pin Clipboard Pill"
                )
            }

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
