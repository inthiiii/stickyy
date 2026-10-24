import AppKit
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
    func testNotesExportAndClipboardHistoryAreAvailable() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        let notesExport = app.buttons["exportToAppleNotes"]
        XCTAssertTrue(notesExport.exists)
        XCTAssertFalse(notesExport.isEnabled)
        XCTAssertTrue(
            app.descendants(matching: .any)["clipboardShelf"]
                .waitForExistence(timeout: 2)
        )

        editor.typeText("Send this thought to Notes")
        XCTAssertTrue(notesExport.isEnabled)
    }

    @MainActor
    func testExportOpensNativeShareDestinations() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeText("Share this thought")

        app.buttons["exportToAppleNotes"].click()
        XCTAssertTrue(
            app.menuItems.matching(
                NSPredicate(format: "identifier BEGINSWITH %@", "sharingService_")
            ).firstMatch.waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.menuItems["Shortcuts"].exists)
        XCTAssertFalse(app.menuItems["Add to Shortcuts"].exists)
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(editor.exists)
    }

    @MainActor
    func testThreeHyphensCreateDivider() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeText("---")

        let value = editor.value as? String
        XCTAssertTrue(value?.contains("────────────") == true)
        XCTAssertFalse(value?.contains("---") == true)
    }

    @MainActor
    func testHeaderTemporarilyShowsTheActiveNoteTitle() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        XCTAssertTrue(
            app.textViews["scratchpadEditor"].waitForExistence(timeout: 5)
        )
        let titleButton = app.buttons["scratchpadHeaderTitle"]
        XCTAssertTrue(titleButton.exists)
        XCTAssertEqual(titleButton.label, "Stickyy")

        titleButton.click()
        XCTAssertEqual(titleButton.label, "Untitled")

        titleButton.click()
        XCTAssertEqual(titleButton.label, "Stickyy")
    }

    @MainActor
    func testURLIsExposedAsAClickableLink() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeText("Visit https://stickyyformac.vercel.app today")

        XCTAssertTrue(
            app.links["https://stickyyformac.vercel.app"]
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testClipboardPasteButtonAndKeyboardShortcutInsertText() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-clipboard-text",
            "A clipboard thought",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        let pasteButton = app.buttons["pasteClipboardText_1"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2))
        pasteButton.click()
        XCTAssertEqual(editor.value as? String, "A clipboard thought")

        editor.click()
        editor.typeKey("a", modifierFlags: .command)
        editor.typeKey(.delete, modifierFlags: [])
        editor.typeKey("1", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, "A clipboard thought")
    }

    @MainActor
    func testDoubleClickingClipboardPillCopiesItAgain() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-clipboard-text",
            "Copy me again",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        XCTAssertTrue(
            app.textViews["scratchpadEditor"].waitForExistence(timeout: 5)
        )
        let pill = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@",
                    "clipboardHistoryItem_"
                )
            )
            .firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 2))

        NSPasteboard.general.clearContents()
        XCTAssertTrue(
            NSPasteboard.general.setString("Different text", forType: .string)
        )
        pill.doubleClick()

        XCTAssertEqual(
            NSPasteboard.general.string(forType: .string),
            "Copy me again"
        )
    }

    @MainActor
    func testSeventhClipboardShortcutPastesSeventhPill() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-clipboard-item-count",
            "7",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeKey("7", modifierFlags: .command)
        XCTAssertEqual(editor.value as? String, "Clipboard item 1")
    }

    @MainActor
    func testDisabledClipboardHistoryShowsOnlyDirectTextPaste() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-disable-clipboard-history",
            "--ui-testing-clipboard-text",
            "Paste without history",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertFalse(
            app.descendants(matching: .any)["clipboardShelf"].exists
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["emptyClipboardHistory"].exists
        )

        let directPaste = app.buttons["pasteCurrentClipboardText"]
        XCTAssertTrue(directPaste.waitForExistence(timeout: 2))
        directPaste.click()
        XCTAssertEqual(editor.value as? String, "Paste without history")
    }

    @MainActor
    func testScratchpadClosesWhenAppDeactivates() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
        finder.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        ).click()
        XCTAssertTrue(editor.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testScratchpadLibraryCreatesANewScratchpad() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Close scratchpad"].exists)

        let libraryButton = app.buttons["scratchpadLibrary"]
        XCTAssertTrue(libraryButton.exists)
        libraryButton.click()

        let newButton = app.buttons["newScratchpad"]
        XCTAssertTrue(newButton.waitForExistence(timeout: 2))
        newButton.click()

        XCTAssertTrue(editor.exists)
        editor.typeText("A second note")
        XCTAssertEqual(editor.value as? String, "A second note")
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

    @MainActor
    func testAutosavedTextSurvivesForcedTermination() {
        let crashedApp = XCUIApplication()
        crashedApp.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
            "--ui-testing-crash-after-edit",
        ]
        crashedApp.launch()

        let editor = crashedApp.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeText("Recovered after a crash")
        XCTAssertTrue(
            crashedApp.wait(for: .notRunning, timeout: 5)
        )

        let relaunchedApp = XCUIApplication()
        relaunchedApp.launchArguments = ["--ui-testing-open-scratchpad"]
        relaunchedApp.launch()

        let restoredEditor = relaunchedApp.textViews["scratchpadEditor"]
        XCTAssertTrue(restoredEditor.waitForExistence(timeout: 5))
        XCTAssertEqual(
            restoredEditor.value as? String,
            "Recovered after a crash"
        )
    }

    @MainActor
    func testSearchRenamePinAndDeleteWorkflow() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        app.buttons["scratchpadLibrary"].click()
        app.buttons["newScratchpad"].click()
        editor.typeText("Unique searchable phrase")

        app.buttons["scratchpadLibrary"].click()
        let search = app.textFields["scratchpadSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 2))
        search.typeText("Unique searchable")

        let actions = app.descendants(matching: .any)["Actions for Untitled"]
        XCTAssertTrue(actions.waitForExistence(timeout: 2))
        actions.click()
        app.menuItems["Edit Scratchpad Name…"].click()

        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.click()
        nameField.typeKey("a", modifierFlags: .command)
        nameField.typeText("Recovered Ideas")
        app.sheets.buttons["Rename"].click()

        let renamedActions = app.descendants(matching: .any)[
            "Actions for Recovered Ideas"
        ]
        XCTAssertTrue(renamedActions.waitForExistence(timeout: 2))
        renamedActions.click()
        app.menuItems["Pin"].click()

        let renamedRow = app.buttons["Recovered Ideas"]
        XCTAssertTrue(renamedRow.waitForExistence(timeout: 2))
        XCTAssertTrue((renamedRow.value as? String)?.contains("Pinned") == true)

        renamedActions.click()
        app.menuItems["Delete…"].click()
        let deleteButton = app.sheets.buttons["Delete Scratchpad"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.click()

        XCTAssertTrue(renamedRow.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testSettingsExposePhaseSixControls() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-persistence"]
        app.launch()
        app.typeKey(",", modifierFlags: .command)

        XCTAssertTrue(
            app.descendants(matching: .any)["launchAtLoginToggle"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["globalShortcutRecorder"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["liquidGlassToggle"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["clipboardHistoryToggle"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["clipboardHistoryLimitPicker"].exists
        )
        XCTAssertTrue(app.buttons["showUserGuide"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any)["floatingPanelToggle"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["floatingNoteModePicker"].exists
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["automaticUpdateChecksToggle"].exists
        )
        XCTAssertTrue(app.buttons["checkForUpdates"].exists)
    }

    @MainActor
    func testSettingsShowUserGuide() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-persistence"]
        app.launch()
        app.typeKey(",", modifierFlags: .command)

        let guideButton = app.buttons["showUserGuide"]
        XCTAssertTrue(guideButton.waitForExistence(timeout: 5))
        guideButton.click()

        XCTAssertTrue(
            app.staticTexts["Stickyy User Guide"].waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.staticTexts["Reuse clipboard items"].exists)
    }

    @MainActor
    func testFinishingOnboardingOpensWelcomeScratchpad() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-persistence"]
        app.launch()
        app.typeKey(",", modifierFlags: .command)

        let tourButton = app.buttons["showOnboarding"]
        XCTAssertTrue(tourButton.waitForExistence(timeout: 5))
        tourButton.click()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.click()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.click()
        XCTAssertTrue(
            app.descendants(matching: .any)["onboardingFloatingPreview"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2))
        continueButton.click()

        let startButton = app.buttons["Start catching thoughts"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.click()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(
            (editor.value as? String)?.contains("Welcome to Stickyy") == true
        )
    }

    @MainActor
    func testCustomShortcutRecorderCapturesKeys() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-persistence"]
        app.launch()
        app.typeKey(",", modifierFlags: .command)

        let recorder = app.buttons["globalShortcutRecorder"]
        XCTAssertTrue(recorder.waitForExistence(timeout: 5))
        recorder.click()
        app.typeKey("k", modifierFlags: [.control, .option])

        XCTAssertEqual(recorder.value as? String, "⌃⌥K")
    }

    @MainActor
    func testDefaultGlobalShortcutOpensScratchpad() async {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset-persistence"]
        app.launch()

        // Carbon can briefly retain the previous UI-test process's hot-key
        // registration while repeated app launches are settling.
        try? await Task.sleep(for: .milliseconds(500))
        app.typeKey(.space, modifierFlags: [.control, .option])

        let editor = app.textViews["floatingScratchpadEditor"]
        if !editor.waitForExistence(timeout: 2) {
            app.typeKey(.space, modifierFlags: [.control, .option])
        }
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["exportToAppleNotes"].exists)
        XCTAssertFalse(
            app.descendants(matching: .any)["clipboardShelf"].exists
        )
    }

    @MainActor
    func testDisablingFloatingPanelRestoresMenuBarShortcutBehavior() async {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-disable-floating-panel",
        ]
        app.launch()

        try? await Task.sleep(for: .milliseconds(500))
        app.typeKey(.space, modifierFlags: [.control, .option])

        let editor = app.textViews["scratchpadEditor"]
        if !editor.waitForExistence(timeout: 2) {
            app.typeKey(.space, modifierFlags: [.control, .option])
        }
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["exportToAppleNotes"].exists)
    }

    @MainActor
    func testFloatingPanelCanCreateANewNoteEveryTime() async {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-floating-mode-new",
            "--ui-testing-open-floating-panel",
        ]
        app.launch()

        let editor = app.textViews["floatingScratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.typeText("First floating thought")
        editor.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(editor.waitForNonExistence(timeout: 2))

        try? await Task.sleep(for: .milliseconds(300))
        app.typeKey(.space, modifierFlags: [.control, .option])
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "")
    }

    @MainActor
    func testFloatingPanelCanInsertTheLatestClipboardItem() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-clipboard-text",
            "Latest copied thought",
            "--ui-testing-open-floating-panel",
        ]
        app.launch()

        let editor = app.textViews["floatingScratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let clipboardButton = app.buttons["floatingRecentClipboard"]
        XCTAssertTrue(clipboardButton.waitForExistence(timeout: 2))
        clipboardButton.click()
        XCTAssertEqual(editor.value as? String, "Latest copied thought")
    }

    @MainActor
    func testExistingInstallReceivesTheLatestUpdateNote() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-existing-version",
            "1.1.1",
        ]
        app.launch()

        let editor = app.textViews["scratchpadEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(
            (editor.value as? String)?.contains("Stickyy 1.2.5 is ready")
                == true
        )
        app.buttons["scratchpadHeaderTitle"].click()
        XCTAssertEqual(
            app.buttons["scratchpadHeaderTitle"].label,
            "Latest update 1.2.5 and the features"
        )
    }

    @MainActor
    func testScratchpadPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing-reset-persistence",
            "--ui-testing-open-scratchpad",
        ]
        app.launch()

        XCTAssertTrue(
            app.textViews["scratchpadEditor"].waitForExistence(timeout: 5)
        )
        let handleSystemOwnedIssue = { (issue: XCUIAccessibilityAuditIssue) in
            // macOS exposes the system Touch Bar/candidate strip through the
            // app hierarchy. Stickyy does not create or control that element.
            if issue.element?.elementType == .touchBar {
                return true
            }
            if issue.element?.label == "emoji & symbols" {
                return true
            }
            if let element = issue.element,
               element.descendants(matching: .button)["siri"].exists
            {
                // The system Siri/Touch Bar candidate dialog is also exposed
                // as part of the app hierarchy on macOS 27.
                return true
            }
            print(
                "Accessibility audit: \(issue.compactDescription); "
                    + "\(issue.detailedDescription); "
                    + "element=\(String(describing: issue.element))"
            )
            return false
        }
        let auditCompleted: Bool
        do {
            try app.performAccessibilityAudit(
                for: .all,
                handleSystemOwnedIssue
            )
            auditCompleted = true
        } catch let error as NSError
            where error.domain == "com.apple.xcode.xctest.accessibilityAudit"
                && error.code == -56 {
            auditCompleted = false
            XCTAssertTrue(app.textViews["scratchpadEditor"].isHittable)
            XCTAssertTrue(app.buttons["scratchpadLibrary"].exists)
            XCTAssertTrue(app.buttons["exportToAppleNotes"].exists)
        }

        app.buttons["scratchpadLibrary"].click()
        XCTAssertTrue(
            app.textFields["scratchpadSearch"].waitForExistence(timeout: 2)
        )
        if auditCompleted {
            try app.performAccessibilityAudit(
                for: .all,
                handleSystemOwnedIssue
            )
        } else {
            XCTAssertTrue(app.textFields["scratchpadSearch"].isHittable)
            XCTAssertTrue(app.buttons["newScratchpad"].exists)
        }
    }

    @MainActor
    func testLaunchPerformance() {
        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
            app.terminate()
        }
    }
}
