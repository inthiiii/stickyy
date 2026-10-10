import Foundation

@MainActor
protocol ScratchpadStoring: AnyObject {
    func loadText() throws -> String
    func saveText(_ text: String) throws
}

enum ScratchpadStoreError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        String(localized: "Scratchpad storage is unavailable.")
    }
}

@MainActor
final class UnavailableScratchpadStore: ScratchpadStoring {
    func loadText() throws -> String {
        throw ScratchpadStoreError.unavailable
    }

    func saveText(_ text: String) throws {
        throw ScratchpadStoreError.unavailable
    }
}
