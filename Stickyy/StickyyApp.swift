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
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(
                    Color.accentColor.opacity(0.10),
                    in: .rect(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(AppEnvironment.productName)
                    .font(.title2.weight(.semibold))

                Text(AppEnvironment.tagline)
                    .foregroundStyle(.secondary)

                Text("Right-click the menu-bar icon to quit Stickyy.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(width: 390)
    }
}
