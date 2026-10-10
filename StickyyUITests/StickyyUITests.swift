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
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        editor.typeText("Catch this thought")
        XCTAssertEqual(editor.value as? String, "Catch this thought")

        editor.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(editor.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testCloseControlDismissesScratchpad() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        let closeButton = app.buttons["Close scratchpad"]
        XCTAssertTrue(closeButton.exists)
        closeButton.click()

        XCTAssertTrue(editor.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testScratchpadRestoresTextAfterRelaunch() {
        let firstLaunch = XCUIApplication()
        firstLaunch.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        firstLaunch.launch()

        let firstEditor = firstLaunch.textViews["scratchpadEditor"]
        XCTAssertTrue(firstEditor.waitForExistence(timeout: 5))
        firstEditor.typeText("Survives relaunch")
        firstEditor.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(firstEditor.waitForNonExistence(timeout: 2))
        firstLaunch.terminate()

        let secondLaunch = XCUIApplication()
        secondLaunch.launchArguments = ["--ui-testing-open-scratchpad"]
        secondLaunch.launch()

        let restoredEditor = secondLaunch.textViews["scratchpadEditor"]
        XCTAssertTrue(restoredEditor.waitForExistence(timeout: 5))
        XCTAssertEqual(restoredEditor.value as? String, "Survives relaunch")
    }
}
