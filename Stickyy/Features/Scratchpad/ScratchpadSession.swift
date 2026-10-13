import Foundation
import Observation

struct ScratchpadTextInsertion: Equatable {
    let id = UUID()
    let text: String
}

@MainActor
@Observable
final class ScratchpadSession {
    private(set) var scratchpads: [Scratchpad]
    private(set) var activeScratchpadID: String
    var searchQuery = ""

    var text: String {
        get { activeScratchpad?.text ?? "" }
        set {
            guard let index = activeIndex,
                  scratchpads[index].text != newValue else { return }
            scratchpads[index].text = newValue
            scratchpads[index].updatedAt = .now
            scheduleAutosave(for: scratchpads[index].id)
        }
    }

    var activeTitle: String {
        activeScratchpad?.title ?? String(localized: "Untitled")
    }

    var activeAttachments: [ScratchpadAttachment] {
        activeScratchpad?.attachments ?? []
    }

    var visibleScratchpads: [Scratchpad] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = query.isEmpty ? scratchpads : scratchpads.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.text.localizedCaseInsensitiveContains(query)
        }
        return matches.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private(set) var editorFocusRequest = 0
    private(set) var pendingTextInsertion: ScratchpadTextInsertion?
    private(set) var persistenceError: String?

    @ObservationIgnored
    private let store: any ScratchpadStoring

    @ObservationIgnored
    private let selectionStore: any ScratchpadSelectionStoring

    @ObservationIgnored
    private let autosaveDelay: Duration

    @ObservationIgnored
    private var autosaveTask: Task<Void, Never>?

    init(
        store: any ScratchpadStoring,
        selectionStore: any ScratchpadSelectionStoring = UserDefaultsScratchpadSelectionStore(),
        autosaveDelay: Duration = .milliseconds(300)
    ) {
        self.store = store
        self.selectionStore = selectionStore
        self.autosaveDelay = autosaveDelay

        do {
            var restored = try store.loadScratchpads()
            if restored.isEmpty {
                let scratchpad = Scratchpad()
                try store.save(scratchpad)
                restored = [scratchpad]
            }
            scratchpads = restored
            if let rememberedID = selectionStore.selectedScratchpadID,
               restored.contains(where: { $0.id == rememberedID }) {
                activeScratchpadID = rememberedID
            } else {
                activeScratchpadID = restored[0].id
            }
            selectionStore.selectedScratchpadID = activeScratchpadID
        } catch {
            let scratchpad = Scratchpad()
            scratchpads = [scratchpad]
            activeScratchpadID = scratchpad.id
            persistenceError = String(
                localized: "Stickyy couldn’t restore the saved scratchpads. New text will remain available until the app quits."
            )
        }
    }

    func requestEditorFocus() {
        editorFocusRequest &+= 1
    }

    func insertIntoEditor(_ text: String) {
        guard !text.isEmpty else { return }
        pendingTextInsertion = ScratchpadTextInsertion(text: text)
        requestEditorFocus()
    }

    func prepareWelcomeScratchpad() {
        if !text.isEmpty || !activeAttachments.isEmpty {
            createScratchpad()
        }
        renameScratchpad(
            id: activeScratchpadID,
            to: String(localized: "Welcome to Stickyy")
        )
        text = String(
            localized: """
            Welcome to Stickyy 👋

            Press ⌃⌥Space to open your scratchpad from anywhere.

            Copy text, images, or files to see them in Clipboard Pills. Double-click a pill to copy it again, or press ⌘1–⌘7 to paste it into this scratchpad.

            Your thoughts stay on this Mac.
            """
        )
        flush()
        requestEditorFocus()
    }

    func addAttachments(from content: ClipboardHistoryContent) {
        guard let index = activeIndex else { return }
        do {
            let additions = try AttachmentStore.makeAttachments(from: content)
            guard !additions.isEmpty else { return }
            scratchpads[index].attachments.append(contentsOf: additions)
            scratchpads[index].updatedAt = .now
            persist(scratchpads[index])
        } catch {
            persistenceError = String(localized: "Stickyy couldn’t save that attachment.")
        }
    }

    func removeAttachment(id: UUID) {
        guard let index = activeIndex else { return }
        scratchpads[index].attachments.removeAll { $0.id == id }
        scratchpads[index].updatedAt = .now
        persist(scratchpads[index])
    }

    @discardableResult
    func createScratchpad() -> String {
        flush()
        let scratchpad = Scratchpad()
        scratchpads.append(scratchpad)
        activeScratchpadID = scratchpad.id
        selectionStore.selectedScratchpadID = scratchpad.id
        persist(scratchpad)
        requestEditorFocus()
        return scratchpad.id
    }

    func selectScratchpad(id: String) {
        guard id != activeScratchpadID,
              scratchpads.contains(where: { $0.id == id }) else { return }
        flush()
        activeScratchpadID = id
        selectionStore.selectedScratchpadID = id
        requestEditorFocus()
    }

    func renameScratchpad(id: String, to proposedTitle: String) {
        guard let index = scratchpads.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = proposedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        scratchpads[index].title = trimmed.isEmpty
            ? String(localized: "Untitled")
            : trimmed
        scratchpads[index].updatedAt = .now
        persist(scratchpads[index])
    }

    func togglePin(id: String) {
        guard let index = scratchpads.firstIndex(where: { $0.id == id }) else { return }
        scratchpads[index].isPinned.toggle()
        scratchpads[index].updatedAt = .now
        persist(scratchpads[index])
    }

    func deleteScratchpad(id: String) {
        guard let index = scratchpads.firstIndex(where: { $0.id == id }) else { return }
        if id == activeScratchpadID {
            autosaveTask?.cancel()
            autosaveTask = nil
        }

        do {
            try store.deleteScratchpad(id: id)
            scratchpads.remove(at: index)

            if scratchpads.isEmpty {
                let replacement = Scratchpad()
                scratchpads = [replacement]
                activeScratchpadID = replacement.id
                try store.save(replacement)
            } else if id == activeScratchpadID {
                activeScratchpadID = visibleScratchpads.first?.id ?? scratchpads[0].id
            }

            selectionStore.selectedScratchpadID = activeScratchpadID
            persistenceError = nil
            requestEditorFocus()
        } catch {
            persistenceError = String(localized: "Stickyy couldn’t delete this scratchpad.")
        }
    }

    func flush() {
        autosaveTask?.cancel()
        autosaveTask = nil
        guard let scratchpad = activeScratchpad else { return }
        persist(scratchpad)
    }

    private var activeIndex: Int? {
        scratchpads.firstIndex { $0.id == activeScratchpadID }
    }

    private var activeScratchpad: Scratchpad? {
        guard let activeIndex else { return nil }
        return scratchpads[activeIndex]
    }

    private func scheduleAutosave(for scratchpadID: String) {
        guard autosaveTask == nil else { return }
        autosaveTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: autosaveDelay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            autosaveTask = nil
            guard activeScratchpadID == scratchpadID,
                  let current = activeScratchpad else { return }
            persist(current)
        }
    }

    private func persist(_ scratchpad: Scratchpad) {
        do {
            try store.save(scratchpad)
            persistenceError = nil
        } catch {
            persistenceError = String(
                localized: "Stickyy couldn’t save this scratchpad. Your current text will remain available until the app quits."
            )
        }
    }
}
