# Phase 3 — Persistence

> Status: Implemented and verified.

Phase 3 makes the primary scratchpad durable while preserving the editor-first behavior established in Phase 2.

## Architecture

- `ScratchpadRecord` is the SwiftData model for the primary scratchpad.
- `ScratchpadStoring` isolates the session from the persistence technology.
- `SwiftDataScratchpadStore` performs explicit fetch and save operations.
- `PersistenceController` owns the model container and supplies the main-actor store.
- `ScratchpadSession` restores text at startup, coalesces rapid edits, saves after 300 milliseconds of inactivity, and exposes storage failures to the UI.
- Closing the popover and terminating the application synchronously flush any pending edit.

The primary record uses a unique stable key. This avoids duplicate records now and gives the future multiple-scratchpad migration a deterministic record to adopt.

## Files

### Created

- `Stickyy/Persistence/ScratchpadRecord.swift`
- `Stickyy/Persistence/ScratchpadStoring.swift`
- `Stickyy/Persistence/SwiftDataScratchpadStore.swift`
- `Stickyy/Persistence/PersistenceController.swift`
- `StickyyTests/SwiftDataScratchpadStoreTests.swift`

### Modified

- `Stickyy/App/AppDelegate.swift`
- `Stickyy/App/PopoverController.swift`
- `Stickyy/App/StatusItemController.swift`
- `Stickyy/Features/Scratchpad/ScratchpadSession.swift`
- `Stickyy/Features/Scratchpad/ScratchpadView.swift`
- `Stickyy/Resources/Localizable.xcstrings`
- `StickyyTests/ScratchpadSessionTests.swift`
- `StickyyUITests/StickyyUITests.swift`
- `README.md`

## Save lifecycle

1. SwiftData restores the primary record when Stickyy launches.
2. An editor change cancels the previous pending save.
3. After 300 milliseconds without another edit, the latest complete string is saved.
4. Closing the popover cancels the delay and saves immediately.
5. Quitting Stickyy performs one final synchronous flush.
6. A storage error leaves the current text in memory and presents a non-destructive warning in the scratchpad.

## Verification

- Empty stores restore an empty scratchpad.
- Existing text restores into a new session.
- Debounced edits save automatically.
- Rapid edits are coalesced into one write.
- Popover/app lifecycle flushing saves the latest value immediately.
- Failed saves retain the current in-memory text and expose an error.
- Multiple saves update one primary SwiftData record instead of creating duplicates.
- Debug unit and UI tests pass.
- A clean Release build succeeds with the existing minimal sandbox entitlement.

## Out of scope

Multiple scratchpads, rename/delete/search/pin operations, configurable global shortcuts, launch at login, iCloud, and final visual polish remain assigned to later phases.
