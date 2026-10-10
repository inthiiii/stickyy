import Testing
@testable import Stickyy

@MainActor
struct ScratchpadSessionTests {
    @Test("A new scratchpad starts empty")
    func startsEmpty() {
        let session = ScratchpadSession()

        #expect(session.text.isEmpty)
        #expect(session.editorFocusRequest == 0)
    }

    @Test("Existing in-memory text is preserved")
    func acceptsInitialText() {
        let session = ScratchpadSession(text: "A thought")

        #expect(session.text == "A thought")
    }

    @Test("Reset clears the current scratchpad")
    func resetClearsText() {
        let session = ScratchpadSession(text: "Temporary note")

        session.reset()

        #expect(session.text.isEmpty)
    }

    @Test("Every focus request has a new generation")
    func focusRequestsAdvance() {
        let session = ScratchpadSession()

        session.requestEditorFocus()
        session.requestEditorFocus()

        #expect(session.editorFocusRequest == 2)
    }
}
