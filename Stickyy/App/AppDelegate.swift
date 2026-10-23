import AppKit
import Carbon.HIToolbox
import Darwin

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var persistenceController: PersistenceController?
    private var scratchpadSession: ScratchpadSession?
    private var popoverController: PopoverController?
    private var statusItemController: StatusItemController?
    private var globalShortcutController: GlobalShortcutController?
    private var clipboardHistoryController: ClipboardHistoryController?
    private var onboardingController: OnboardingController?
    private var floatingPanelController: FloatingPanelController?
    private var onboardingObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        _ = UpdateController.shared

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
            // Preferences are independent of the SwiftData store. Reset them
            // first so a store cleanup failure cannot leak state between tests.
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.selectedScratchpadID
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.usesLiquidGlass
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.usesClipboardHistory
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.clipboardHistoryLimit
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.globalShortcut
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.usesFloatingPanelShortcut
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.floatingNoteMode
            )
            UserDefaults.standard.removeObject(
                forKey: StickyyPreferences.automaticallyChecksForUpdates
            )
            do {
                try store.deleteAllScratchpads()
            } catch {
                NSLog(
                    "Stickyy UI-test persistence reset failed: %@",
                    error.localizedDescription
                )
            }
        }
        if CommandLine.arguments.contains("--ui-testing-disable-floating-panel") {
            UserDefaults.standard.set(
                false,
                forKey: StickyyPreferences.usesFloatingPanelShortcut
            )
        }
        if CommandLine.arguments.contains("--ui-testing-floating-mode-new") {
            UserDefaults.standard.set(
                FloatingNoteMode.newEveryTime.rawValue,
                forKey: StickyyPreferences.floatingNoteMode
            )
        }
        #endif

        let session = ScratchpadSession(store: store)
        #if DEBUG
        let clipboardTestText: String? = if let argumentIndex =
            CommandLine.arguments.firstIndex(
            of: "--ui-testing-clipboard-text"
        ), CommandLine.arguments.indices.contains(argumentIndex + 1) {
            CommandLine.arguments[argumentIndex + 1]
        } else {
            nil
        }
        let clipboardTestItemCount: Int? = if let argumentIndex =
            CommandLine.arguments.firstIndex(
                of: "--ui-testing-clipboard-item-count"
            ), CommandLine.arguments.indices.contains(argumentIndex + 1) {
            Int(CommandLine.arguments[argumentIndex + 1])
        } else {
            nil
        }
        let clipboardHistoryDisabledForTesting = CommandLine.arguments.contains(
            "--ui-testing-disable-clipboard-history"
        )
        let clipboardHistoryController = ClipboardHistoryController(
            monitoringEnabled: clipboardTestText == nil
                && clipboardTestItemCount == nil,
            initiallyEnabled: clipboardHistoryDisabledForTesting ? false : nil,
            initialItemLimit: clipboardTestItemCount
        )
        if let clipboardTestText {
            clipboardHistoryController.seedForUITesting(text: clipboardTestText)
        } else if let clipboardTestItemCount {
            clipboardHistoryController.seedForUITesting(
                texts: (1...clipboardTestItemCount).map {
                    "Clipboard item \($0)"
                }
            )
        }
        #else
        let clipboardHistoryController = ClipboardHistoryController()
        #endif
        let popoverController = PopoverController(
            session: session,
            clipboardHistory: clipboardHistoryController
        )
        let floatingPanelController = FloatingPanelController(session: session)
        let statusItemController = StatusItemController(
            popoverController: popoverController,
            floatingPanelController: floatingPanelController
        )

        scratchpadSession = session
        self.popoverController = popoverController
        self.statusItemController = statusItemController
        self.floatingPanelController = floatingPanelController
        self.clipboardHistoryController = clipboardHistoryController

        let previousDefault = GlobalShortcut(
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(cmdKey | optionKey)
        ).storageValue
        if UserDefaults.standard.string(forKey: StickyyPreferences.globalShortcut) == previousDefault {
            UserDefaults.standard.set(
                GlobalShortcut.defaultShortcut.storageValue,
                forKey: StickyyPreferences.globalShortcut
            )
        }
        globalShortcutController = GlobalShortcutController {
            if StickyyPreferences.floatingPanelEnabled() {
                popoverController.close()
                floatingPanelController.toggle()
            } else {
                statusItemController.showScratchpad()
            }
        }

        let onboardingController = OnboardingController()
        self.onboardingController = onboardingController
        onboardingObserver = NotificationCenter.default.addObserver(
            forName: .onboardingDidFinish,
            object: nil,
            queue: .main
        ) { [weak session, weak statusItemController] _ in
            Task { @MainActor in
                session?.prepareWelcomeScratchpad()
                statusItemController?.showScratchpad()
            }
        }
        if !CommandLine.arguments.contains(where: { $0.hasPrefix("--ui-testing") }),
           !UserDefaults.standard.bool(forKey: StickyyPreferences.hasCompletedOnboarding) {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                onboardingController.show()
            }
        }

        #if DEBUG
        if CommandLine.arguments.contains("--ui-testing-open-scratchpad") {
            Task { @MainActor [weak statusItemController] in
                try? await Task.sleep(for: .milliseconds(150))
                statusItemController?.showScratchpad()
            }
        }

        if CommandLine.arguments.contains("--ui-testing-open-floating-panel") {
            Task { @MainActor [weak floatingPanelController] in
                try? await Task.sleep(for: .milliseconds(150))
                floatingPanelController?.show()
            }
        }

        if CommandLine.arguments.contains("--ui-testing-crash-after-edit") {
            Task { @MainActor [weak session] in
                while session?.text.isEmpty == true {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                var previousText = session?.text
                var stableChecks = 0
                while stableChecks < 10 {
                    try? await Task.sleep(for: .milliseconds(50))
                    if session?.text == previousText {
                        stableChecks += 1
                    } else {
                        previousText = session?.text
                        stableChecks = 0
                    }
                }
                Darwin._exit(99)
            }
        }
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        scratchpadSession?.flush()
    }
}
