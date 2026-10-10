import XCTest

final class StickyyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testApplicationLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertNotEqual(app.state, .notRunning)
    }

    @MainActor
    func testScratchpadAcceptsTextAndClosesWithEscape() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-open-scratchpad"]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        editor.typeText("Catch this thought")
        XCTAssertEqual(editor.value as? String, "Catch this thought")

        editor.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(editor.waitForNonExistence(timeout: 2))
    }
}
