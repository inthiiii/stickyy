import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.8"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • The floating-note paste action now uses the newest copied text even when older Clipboard Pills are pinned above it.
        • Type “- ” at the beginning of a line to create a solid bullet and continue the list with Return.
        • Type “->” to create a clean right arrow.
        • Type “---” to divide a note into sections, then use the new dot navigator on the right edge to jump between them.
        • Liquid Glass now keeps a consistent blur while section navigation is visible.
        • The section navigator stays compact, can scroll through long notes, and can be hidden in Settings.
        • Stickyy now shows a brief ready indicator when it starts, and Settings opens correctly from the menu-bar icon.

        Thank you for testing Stickyy.
        """
    }
}
