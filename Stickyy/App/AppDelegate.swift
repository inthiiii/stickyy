import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var scratchpadSession: ScratchpadSession?
    private var popoverController: PopoverController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let session = ScratchpadSession()
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
}
