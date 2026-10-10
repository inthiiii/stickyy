import Foundation
import Observation

@MainActor
@Observable
final class ScratchpadSession {
    var text: String {
        didSet {
            guard text != oldValue else { return }
            scheduleAutosave()
        }
    }

    private(set) var editorFocusRequest = 0
    private(set) var persistenceError: String?

    @ObservationIgnored
    private let store: any ScratchpadStoring

    @ObservationIgnored
    private let autosaveDelay: Duration

    @ObservationIgnored
    private var autosaveTask: Task<Void, Never>?

    @ObservationIgnored
    private var lastSavedText: String?

    init(
        store: any ScratchpadStoring,
        autosaveDelay: Duration = .milliseconds(300)
    ) {
        self.store = store
        self.autosaveDelay = autosaveDelay

        do {
            let restoredText = try store.loadText()
            text = restoredText
            lastSavedText = restoredText
        } catch {
            text = ""
            lastSavedText = nil
            persistenceError = String(
                localized: "Stickyy couldn’t restore the saved scratchpad. New text will remain available until the app quits."
            )
        }
    }

    func requestEditorFocus() {
        editorFocusRequest &+= 1
    }

    func reset() {
        text = ""
    }

    func flush() {
        autosaveTask?.cancel()
        autosaveTask = nil
        persistCurrentText()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: autosaveDelay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            persistCurrentText()
        }
    }

    private func persistCurrentText() {
        guard text != lastSavedText else { return }

        do {
            try store.saveText(text)
            lastSavedText = text
            persistenceError = nil
        } catch {
            persistenceError = String(
                localized: "Stickyy couldn’t save this scratchpad. Your current text will remain available until the app quits."
            )
        }
    }
}
