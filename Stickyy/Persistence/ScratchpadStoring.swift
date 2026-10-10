import Foundation

@MainActor
protocol ScratchpadStoring: AnyObject {
    func loadScratchpads() throws -> [Scratchpad]
    func save(_ scratchpad: Scratchpad) throws
    func deleteScratchpad(id: String) throws
    func deleteAllScratchpads() throws
}

enum ScratchpadStoreError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        String(localized: "Scratchpad storage is unavailable.")
    }
}

@MainActor
final class UnavailableScratchpadStore: ScratchpadStoring {
    func loadScratchpads() throws -> [Scratchpad] {
        throw ScratchpadStoreError.unavailable
    }

    func save(_ scratchpad: Scratchpad) throws {
        throw ScratchpadStoreError.unavailable
    }

    func deleteScratchpad(id: String) throws {
        throw ScratchpadStoreError.unavailable
    }

    func deleteAllScratchpads() throws {
        throw ScratchpadStoreError.unavailable
    }
}
