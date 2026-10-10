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
    private var shortcut = GlobalShortcutChoice.defaultChoice.rawValue

    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemMessage: String?

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch Stickyy at login", isOn: launchAtLoginBinding)
                if let loginItemMessage {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Keyboard Shortcut") {
                Picker("Show Stickyy", selection: $shortcut) {
                    ForEach(GlobalShortcutChoice.allCases) { choice in
                        Text(choice.title).tag(choice.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Appearance") {
                Toggle("Use Liquid Glass", isOn: $usesLiquidGlass)
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
        }
        .formStyle(.grouped)
        .padding(6)
        .frame(width: 430, height: 300)
        .navigationTitle("Stickyy Settings")
        .onAppear { refreshLoginItemState() }
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
