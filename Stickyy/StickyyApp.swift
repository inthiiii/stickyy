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

private struct StickyySettingsView: View {
    @AppStorage(StickyyPreferences.usesLiquidGlass)
    private var usesLiquidGlass = false

    @AppStorage(StickyyPreferences.globalShortcut)
    private var shortcut = GlobalShortcut.defaultShortcut.storageValue

    @AppStorage(StickyyPreferences.usesClipboardHistory)
    private var usesClipboardHistory = true

    @AppStorage(StickyyPreferences.clipboardHistoryLimit)
    private var clipboardHistoryLimit = 5

    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemMessage: String?
    @State private var showsUserGuide = false

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

            Section("Clipboard Pills") {
                Toggle("Clipboard History", isOn: $usesClipboardHistory)
                    .accessibilityIdentifier("clipboardHistoryToggle")
                Picker("Number of Pills", selection: $clipboardHistoryLimit) {
                    Text("5").tag(5)
                    Text("7").tag(7)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("clipboardHistoryLimitPicker")
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
        .frame(width: 450, height: 540)
        .navigationTitle("Stickyy Settings")
        .onAppear { refreshLoginItemState() }
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
                detail: "Press ⌃⌥Space. You can record another shortcut in Settings."
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
