import SwiftUI

@main
struct StickyyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            PhaseOneSettingsView()
        }
    }
}

private struct PhaseOneSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppEnvironment.productName)
                .font(.title2.weight(.semibold))

            Text(AppEnvironment.tagline)
                .foregroundStyle(.secondary)

            Text("Settings arrive in a later phase.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 360)
    }
}
