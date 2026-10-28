import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.8.1"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • Restored the native Liquid Glass appearance in the menu-bar scratchpad, floating note, and compact controls.
        • Liquid Glass now stays stable while section navigation and other editor overlays appear or change.
        • The original minimal material remains unchanged when Liquid Glass is turned off.

        Thank you for testing Stickyy.
        """
    }
}
