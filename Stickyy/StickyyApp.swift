import SwiftUI

@main
struct StickyyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            PhaseTwoSettingsView()
        }
    }
}

private struct PhaseTwoSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppEnvironment.productName)
                .font(.title2.weight(.semibold))

            Text(AppEnvironment.tagline)
                .foregroundStyle(.secondary)

            Text("Right-click the menu-bar icon to quit Stickyy.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 360)
    }
}
