import ServiceManagement
import SwiftUI

@main
struct StickyyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            StickyySettingsView()
        }
    }
}

struct StickyySettingsView: View {
    @AppStorage(StickyyPreferences.usesLiquidGlass)
    private var usesLiquidGlass = false

    @AppStorage(StickyyPreferences.globalShortcut)
    private var shortcut = GlobalShortcut.defaultShortcut.storageValue

    @AppStorage(StickyyPreferences.usesClipboardHistory)
    private var usesClipboardHistory = true

    @AppStorage(StickyyPreferences.clipboardHistoryLimit)
    private var clipboardHistoryLimit = 5

    @AppStorage(StickyyPreferences.usesPinnedClipboardItems)
    private var usesPinnedClipboardItems = false

    @AppStorage(StickyyPreferences.showsTextCount)
    private var showsTextCount = false

    @AppStorage(StickyyPreferences.textCountMode)
    private var textCountMode = TextCountMode.words.rawValue

    @AppStorage(StickyyPreferences.showsSectionNavigator)
    private var showsSectionNavigator = true

    @AppStorage(StickyyPreferences.usesFloatingPanelShortcut)
    private var usesFloatingPanelShortcut = true

    @AppStorage(StickyyPreferences.floatingNoteMode)
    private var floatingNoteMode = FloatingNoteMode.recent.rawValue

    @AppStorage(StickyyPreferences.automaticallyChecksForUpdates)
    private var automaticallyChecksForUpdates = true

    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemMessage: String?
    @State private var showsUserGuide = false
    @State private var pinnedClipboardItems: [ClipboardHistoryItem] = []

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch Stickyy at login", isOn: launchAtLoginBinding)
                    .accessibilityIdentifier("launchAtLoginToggle")
                if let loginItemMessage {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Keyboard Shortcut") {
                LabeledContent("Show Stickyy") {
                    ShortcutRecorderView(storageValue: $shortcut)
                        .frame(width: 150, height: 24)
                }
                Text("Click the shortcut, then press your preferred key combination. The default is ⌃⌥Space.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Floating Note") {
                Toggle(
                    "Open a Floating Note with the Shortcut",
                    isOn: $usesFloatingPanelShortcut
                )
                .accessibilityIdentifier("floatingPanelToggle")

                Picker("When Opened", selection: $floatingNoteMode) {
                    ForEach(FloatingNoteMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .disabled(!usesFloatingPanelShortcut)
                .accessibilityIdentifier("floatingNoteModePicker")

                Text(
                    usesFloatingPanelShortcut
                        ? String(
                            localized: "The shortcut opens a movable note above every app. Clipboard Pills, the header, and sharing stay hidden."
                        )
                        : String(
                            localized: "The shortcut opens the regular menu-bar scratchpad."
                        )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Editor") {
                Toggle("Show Word or Character Count", isOn: $showsTextCount)
                    .accessibilityIdentifier("textCountToggle")
                Picker("Count", selection: $textCountMode) {
                    ForEach(TextCountMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!showsTextCount)
                .accessibilityIdentifier("textCountModePicker")
                Toggle(
                    "Show Section Dot Navigator",
                    isOn: $showsSectionNavigator
                )
                .accessibilityIdentifier("sectionNavigatorToggle")
                Text("Bold, italic, and underline controls are available at the bottom of every note.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Clipboard Pills") {
                Toggle("Clipboard History", isOn: $usesClipboardHistory)
                    .accessibilityIdentifier("clipboardHistoryToggle")
                Picker("Number of Pills", selection: $clipboardHistoryLimit) {
                    Text("5").tag(5)
                    Text("7").tag(7)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("clipboardHistoryLimitPicker")

                Toggle("Allow Pinned Pills", isOn: $usesPinnedClipboardItems)
                    .disabled(!usesClipboardHistory)
                    .accessibilityIdentifier("pinnedClipboardToggle")

                if usesPinnedClipboardItems && !pinnedClipboardItems.isEmpty {
                    ForEach(pinnedClipboardItems) { item in
                        HStack {
                            Label(
                                pinnedClipboardTitle(for: item),
                                systemImage: "pin.fill"
                            )
                            .lineLimit(1)
                            Spacer()
                            Button("Remove") {
                                PinnedClipboardStore.remove(id: item.id)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button("Remove All Pinned Pills", role: .destructive) {
                        PinnedClipboardStore.removeAll()
                    }
                }
                Text(
                    usesClipboardHistory
                        ? String(
                            localized: "Shows your latest clipboard items in a floating shelf below Stickyy. Double-click a pill to copy it again."
                        )
                        : String(
                            localized: "Clipboard monitoring is off and the scratchpad stays completely minimal."
                        )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Appearance") {
                if #available(macOS 26.0, *) {
                    Toggle("Use Liquid Glass", isOn: $usesLiquidGlass)
                        .accessibilityIdentifier("liquidGlassToggle")
                    Text(
                        usesLiquidGlass
                            ? String(
                                localized: "Liquid Glass changes only the window surface. The minimal layout stays the same."
                            )
                            : String(
                                localized: "The original minimal material is the default."
                            )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text("The original minimal material is used on this version of macOS. Liquid Glass is available on macOS 26 or later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("liquidGlassUnavailableMessage")
                }
            }

            Section("Updates") {
                Toggle(
                    "Automatically Check for Updates",
                    isOn: $automaticallyChecksForUpdates
                )
                .accessibilityIdentifier("automaticUpdateChecksToggle")

                Button("Check for Updates…") {
                    UpdateController.shared.checkForUpdates()
                }
                .accessibilityIdentifier("checkForUpdates")

                Text("Stickyy securely checks the update feed and can install future releases without downloading another DMG manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Help") {
                Button("Show Welcome Tour…") {
                    OnboardingController().show()
                }
                .accessibilityIdentifier("showOnboarding")

                Button("User Guide…") {
                    showsUserGuide = true
                }
                .accessibilityIdentifier("showUserGuide")
            }
        }
        .formStyle(.grouped)
        .padding(6)
        .frame(width: 470, height: 700)
        .navigationTitle("Stickyy Settings")
        .onAppear { refreshLoginItemState() }
        .onAppear { reloadPinnedClipboardItems() }
        .onChange(of: usesClipboardHistory) {
            NotificationCenter.default.post(
                name: .clipboardHistoryPreferenceDidChange,
                object: nil
            )
        }
        .onChange(of: clipboardHistoryLimit) {
            NotificationCenter.default.post(
                name: .clipboardHistoryPreferenceDidChange,
                object: nil
            )
        }
        .onChange(of: usesPinnedClipboardItems) {
            NotificationCenter.default.post(
                name: .clipboardHistoryPreferenceDidChange,
                object: nil
            )
            reloadPinnedClipboardItems()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .pinnedClipboardItemsDidChange
            )
        ) { _ in
            reloadPinnedClipboardItems()
        }
        .onAppear {
            UpdateController.shared.setAutomaticChecks(
                automaticallyChecksForUpdates
            )
        }
        .onChange(of: automaticallyChecksForUpdates) {
            UpdateController.shared.setAutomaticChecks(
                automaticallyChecksForUpdates
            )
        }
        .sheet(isPresented: $showsUserGuide) {
            StickyyUserGuideView()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchesAtLogin },
            set: { updateLaunchAtLogin($0) }
        )
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLoginItemState()
        } catch {
            refreshLoginItemState()
            loginItemMessage = error.localizedDescription
        }
    }

    private func refreshLoginItemState() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchesAtLogin = true
            loginItemMessage = nil
        case .requiresApproval:
            launchesAtLogin = false
            loginItemMessage = String(
                localized: "Allow Stickyy in System Settings → General → Login Items."
            )
        case .notRegistered, .notFound:
            launchesAtLogin = false
            loginItemMessage = nil
        @unknown default:
            launchesAtLogin = false
            loginItemMessage = nil
        }
    }

    private func reloadPinnedClipboardItems() {
        pinnedClipboardItems = PinnedClipboardStore.load()
    }

    private func pinnedClipboardTitle(
        for item: ClipboardHistoryItem
    ) -> String {
        switch item.content {
        case .text(let text):
            return String(
                text
                    .split(whereSeparator: \.isNewline)
                    .joined(separator: " ")
                    .prefix(44)
            )
        case .image(_, _, let name):
            return name
        case .files(let urls):
            return urls.count == 1
                ? urls[0].lastPathComponent
                : "\(urls.count) files"
        }
    }
}

private struct StickyyUserGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Stickyy User Guide", systemImage: "book.pages")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            guideRow(
                icon: "keyboard",
                title: "Open from anywhere",
                detail: "Press ⌃⌥Space to toggle the floating note. Disable Floating Note in Settings to use the regular menu-bar scratchpad instead."
            )
            guideRow(
                icon: "macwindow.on.rectangle",
                title: "Keep a note above every app",
                detail: "Move and resize the floating note anywhere. Choose whether the shortcut opens your recent note or creates a new one."
            )
            guideRow(
                icon: "clipboard",
                title: "Reuse clipboard items",
                detail: "Double-click a pill to copy it again. Press ⌘1 through ⌘7 to paste a numbered pill directly into Stickyy."
            )
            guideRow(
                icon: "doc.on.doc",
                title: "Paste images and files",
                detail: "Paste normally to add a preview, then use Show in Finder whenever you need the original file."
            )
            guideRow(
                icon: "square.and.arrow.up",
                title: "Share a thought",
                detail: "Use the share button to send the current scratchpad to Notes, Messages, or another available app."
            )
            guideRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Stay up to date",
                detail: "Use Check for Updates in Settings. Automatic update checks can be turned on or off at any time."
            )
        }
        .padding(24)
        .frame(width: 500)
        .accessibilityIdentifier("userGuide")
    }

    private func guideRow(
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary)
            }
        }
    }
}
