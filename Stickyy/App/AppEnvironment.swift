import Foundation

enum AppEnvironment {
    static let productName = String(localized: "Stickyy")
    static let tagline = String(localized: "Catch a thought before it fades.")

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.2.1"
    }

    static var latestUpdateTitle: String {
        "Latest update \(version) and the features"
    }

    static var latestUpdateNotes: String {
        """
        Stickyy \(version) is ready ✨

        • URLs now appear as highlighted, clickable links.
        • Click “Stickyy” in the scratchpad header to briefly reveal the current note title.
        • Your latest clipboard item is available inside the floating panel.
        • First-time setup and the Drag to Applications installer are clearer and more reliable.
        • Every future update can introduce itself in a dedicated note like this one.

        Thank you for testing Stickyy.
        """
    }
}
