import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.7"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • Optional word or character counts now appear in the bottom-right corner of both note styles.
        • Bold, italic, and underline controls are available in the scratchpad and floating note.
        • Clipboard Pills can be pinned so important items remain while newer copies rotate through the remaining slots.
        • The floating note’s clipboard action is now a single compact icon and accepts text only.
        • Long notes remain anchored correctly while typing and scrolling.

        Thank you for testing Stickyy.
        """
    }
}
