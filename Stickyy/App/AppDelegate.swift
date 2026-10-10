import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var persistenceController: PersistenceController?
    private var scratchpadSession: ScratchpadSession?
    private var popoverController: PopoverController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let store: any ScratchpadStoring

        do {
            let persistenceController = try PersistenceController()
            self.persistenceController = persistenceController
            store = persistenceController.scratchpadStore
        } catch {
            NSLog(
                "Stickyy persistence setup failed: %@",
                error.localizedDescription
            )
            store = UnavailableScratchpadStore()
        }

        #if DEBUG
        if CommandLine.arguments.contains("--ui-testing-reset-persistence") {
            do {
                try store.saveText("")
            } catch {
                NSLog(
                    "Stickyy UI-test persistence reset failed: %@",
                    error.localizedDescription
                )
            }
        }
        #endif

        let session = ScratchpadSession(store: store)
        let popoverController = PopoverController(session: session)
        let statusItemController = StatusItemController(
            popoverController: popoverController
        )

        scratchpadSession = session
        self.popoverController = popoverController
        self.statusItemController = statusItemController

        #if DEBUG
        if CommandLine.arguments.contains("--ui-testing-open-scratchpad") {
            Task { @MainActor [weak statusItemController] in
                try? await Task.sleep(for: .milliseconds(150))
                statusItemController?.showScratchpad()
            }
        }
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        scratchpadSession?.flush()
    }
}
