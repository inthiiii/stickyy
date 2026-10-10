import SwiftData

@MainActor
final class PersistenceController {
    let container: ModelContainer
    let scratchpadStore: SwiftDataScratchpadStore

    init(isStoredInMemoryOnly: Bool = false) throws {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        container = try ModelContainer(
            for: ScratchpadRecord.self,
            configurations: configuration
        )
        scratchpadStore = SwiftDataScratchpadStore(
            context: container.mainContext
        )
    }
}
