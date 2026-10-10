import Observation

@MainActor
@Observable
final class ScratchpadSession {
    var text: String
    private(set) var editorFocusRequest = 0

    init(text: String = "") {
        self.text = text
    }

    func requestEditorFocus() {
        editorFocusRequest &+= 1
    }

    func reset() {
        text = ""
    }
}
