import XCTest
@testable import Stickyy

@MainActor
final class StickyyPerformanceTests: XCTestCase {
    func testSearchingFiveThousandScratchpads() {
        let scratchpads = (0..<5_000).map { index in
            Scratchpad(
                id: "note-\(index)",
                title: "Scratchpad \(index)",
                text: index == 4_999 ? "unique search target" : "ordinary note"
            )
        }
        let session = ScratchpadSession(
            store: PerformanceScratchpadStore(scratchpads),
            selectionStore: PerformanceSelectionStore()
        )

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            session.searchQuery = "unique search target"
            XCTAssertEqual(session.visibleScratchpads.count, 1)
            session.searchQuery = ""
        }
    }

    func testPersistingOneMegabyteScratchpad() throws {
        let persistence = try PersistenceController(isStoredInMemoryOnly: true)
        let text = String(repeating: "0123456789", count: 100_000)
        var scratchpad = Scratchpad(text: text)

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            scratchpad.updatedAt = .now
            try! persistence.scratchpadStore.save(scratchpad)
            XCTAssertEqual(
                try! persistence.scratchpadStore.loadScratchpads().first?.text.count,
                text.count
            )
        }
    }
}

@MainActor
private final class PerformanceSelectionStore: ScratchpadSelectionStoring {
    var selectedScratchpadID: String?
}

@MainActor
private final class PerformanceScratchpadStore: ScratchpadStoring {
    private var scratchpads: [Scratchpad]

    init(_ scratchpads: [Scratchpad]) {
        self.scratchpads = scratchpads
    }

    func loadScratchpads() throws -> [Scratchpad] { scratchpads }

    func save(_ scratchpad: Scratchpad) throws {
        if let index = scratchpads.firstIndex(where: { $0.id == scratchpad.id }) {
            scratchpads[index] = scratchpad
        } else {
            scratchpads.append(scratchpad)
        }
    }

    func deleteScratchpad(id: String) throws {
        scratchpads.removeAll { $0.id == id }
    }

    func deleteAllScratchpads() throws {
        scratchpads.removeAll()
    }
}
