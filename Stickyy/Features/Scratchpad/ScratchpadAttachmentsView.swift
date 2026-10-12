import AppKit
import SwiftUI

struct ScratchpadAttachmentsView: View {
    let attachments: [ScratchpadAttachment]
    let onRemove: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 7) {
                ForEach(attachments) { attachment in
                    attachmentCard(attachment)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .scrollIndicators(.hidden)
        .frame(height: 58)
        .accessibilityLabel("Scratchpad attachments")
    }

    private func attachmentCard(_ attachment: ScratchpadAttachment) -> some View {
        HStack(spacing: 7) {
            preview(attachment)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.displayName)
                    .font(.caption.weight(.medium)).lineLimit(1)
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([attachment.url])
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.tint)
            }
            .frame(maxWidth: 130, alignment: .leading)

            Button {
                onRemove(attachment.id)
            } label: {
                Image(systemName: "xmark").font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Remove attachment")
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .stickyyPillSurface(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.09)) }
    }

    @ViewBuilder
    private func preview(_ attachment: ScratchpadAttachment) -> some View {
        if attachment.kind == .image, let image = NSImage(contentsOf: attachment.url) {
            Image(nsImage: image).resizable().scaledToFill()
        } else {
            Image(nsImage: NSWorkspace.shared.icon(forFile: attachment.url.path))
                .resizable().scaledToFit().padding(4)
        }
    }
}
