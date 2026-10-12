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

    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemMessage: String?

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
                Text("Click the shortcut, then press your preferred key combination. The default is ⌘⌥Space.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Clipboard Pills") {
                Toggle("Clipboard History", isOn: $usesClipboardHistory)
                    .accessibilityIdentifier("clipboardHistoryToggle")
                Text(
                    usesClipboardHistory
                        ? String(
                            localized: "Shows the five latest clipboard items in a floating shelf below Stickyy."
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

                Button("Show Welcome Tour…") {
                    OnboardingController().show()
                }
                .accessibilityIdentifier("showOnboarding")
            }
        }
        .formStyle(.grouped)
        .padding(6)
        .frame(width: 450, height: 480)
        .navigationTitle("Stickyy Settings")
        .onAppear { refreshLoginItemState() }
        .onChange(of: usesClipboardHistory) {
            NotificationCenter.default.post(
                name: .clipboardHistoryPreferenceDidChange,
                object: nil
            )
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
