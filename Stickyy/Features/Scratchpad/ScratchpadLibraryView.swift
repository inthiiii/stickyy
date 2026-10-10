import SwiftUI

struct ScratchpadLibraryView: View {
    @Bindable var session: ScratchpadSession
    let onSelect: () -> Void

    @State private var renameTarget: Scratchpad?
    @State private var renameText = ""
    @State private var deleteTarget: Scratchpad?

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Search scratchpads", text: $session.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("scratchpadSearch")

                Button(action: createScratchpad) {
                    Label("New scratchpad", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("newScratchpad")
            }

            if session.visibleScratchpads.isEmpty {
                ContentUnavailableView.search(text: session.searchQuery)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(session.visibleScratchpads) { scratchpad in
                            row(for: scratchpad)
                        }
                    }
                }
                .frame(maxHeight: 230)
            }
        }
        .padding(12)
        .frame(width: 300)
        .alert("Rename Scratchpad", isPresented: renamePresented) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renameTarget = nil }
            Button("Rename") { finishRename() }
        }
        .confirmationDialog(
            "Delete this scratchpad?",
            isPresented: deletePresented,
            titleVisibility: .visible
        ) {
            Button("Delete Scratchpad", role: .destructive) {
                if let deleteTarget {
                    session.deleteScratchpad(id: deleteTarget.id)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func row(for scratchpad: Scratchpad) -> some View {
        Button {
            session.selectScratchpad(id: scratchpad.id)
            onSelect()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: scratchpad.isPinned ? "pin.fill" : "note.text")
                    .foregroundStyle(scratchpad.isPinned ? Color.accentColor : .secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scratchpad.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(preview(for: scratchpad))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if scratchpad.id == session.activeScratchpadID {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .background(
            scratchpad.id == session.activeScratchpadID
                ? Color.accentColor.opacity(0.10)
                : .clear,
            in: .rect(cornerRadius: 7)
        )
        .accessibilityIdentifier("scratchpadRow_\(scratchpad.id)")
        .contextMenu {
            Button(
                scratchpad.isPinned
                    ? String(localized: "Unpin")
                    : String(localized: "Pin")
            ) {
                session.togglePin(id: scratchpad.id)
            }
            Button("Rename…") { beginRename(scratchpad) }
            Divider()
            Button("Delete…", role: .destructive) { deleteTarget = scratchpad }
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )
    }

    private var deletePresented: Binding<Bool> {
        Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )
    }

    private func preview(for scratchpad: Scratchpad) -> String {
        let preview = scratchpad.text
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return preview.isEmpty ? String(localized: "No text") : preview
    }

    private func createScratchpad() {
        session.createScratchpad()
        onSelect()
    }

    private func beginRename(_ scratchpad: Scratchpad) {
        renameTarget = scratchpad
        renameText = scratchpad.title
    }

    private func finishRename() {
        guard let renameTarget else { return }
        session.renameScratchpad(id: renameTarget.id, to: renameText)
        self.renameTarget = nil
    }
}
