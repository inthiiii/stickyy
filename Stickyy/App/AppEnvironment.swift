import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.10"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • Clipboard Pills now scroll freely from side to side.
        • Stickyy Timer adds a smooth countdown for up to 60 minutes, a menu-bar timer pill, and a notification when time is up.
        • Numbered lists continue automatically when you press Return.

        Thank you for testing Stickyy.
        """
    }
}
