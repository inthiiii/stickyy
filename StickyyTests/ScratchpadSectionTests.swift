import Foundation
import Testing
@testable import Stickyy

@MainActor
struct ScratchpadSectionTests {
    @Test("Each divider creates a navigable section anchor")
    func createsSectionAnchors() {
        let divider = ScratchpadSections.divider
        let text = "First\n\(divider)\nSecond\n\(divider)\nThird"
        let anchors = ScratchpadSections.anchors(in: text)
        let source = text as NSString

        #expect(anchors.count == 3)
        #expect(anchors[0] == 0)
        #expect(source.substring(from: anchors[1]).hasPrefix("Second"))
        #expect(source.substring(from: anchors[2]).hasPrefix("Third"))
    }

    @Test("A divider at the end still exposes the new blank section")
    func includesTrailingBlankSection() {
        let text = "First\n\(ScratchpadSections.divider)\n"
        let anchors = ScratchpadSections.anchors(in: text)

        #expect(anchors == [0, (text as NSString).length])
    }
}
