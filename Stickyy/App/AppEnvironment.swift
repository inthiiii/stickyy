import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.9"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • The floating note now captures clicks, typing, and scrolling even after you have been working in another app.
        • Pasted text automatically drops website and document formatting so it matches your note.
        • Paste as Plain Text is also available from the editor menu or with Command–Option–Shift–V.

        Thank you for testing Stickyy.
        """
    }
}
