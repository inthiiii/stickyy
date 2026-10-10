# Phase 2 — Menu Bar Scratchpad

Phase 2 turns the verified project shell into a usable, single-session scratchpad. It deliberately does not write note text to disk; persistence belongs to Phase 3.

## Outcome

At the end of this phase, clicking the Stickyy menu-bar icon opens a compact scratchpad beneath the icon, places the insertion point in the editor, and clicking again closes it. The text remains available while the app continues running. Standard editing commands, keyboard navigation, undo/redo, scrolling, Escape-to-close, and a safe quit path all work.

## Architecture

- `AppDelegate` remains the composition root and owns the long-lived controllers.
- `StatusItemController` owns the `NSStatusItem`, its click handling, and its small context menu.
- `PopoverController` owns one reusable `NSPopover` and its SwiftUI hosting controller.
- `ScratchpadSession` is the single in-memory source of truth for Phase 2 text.
- `ScratchpadView` supplies the SwiftUI layout.
- `ScratchpadEditor` wraps `NSTextView` so focus, undo, text selection, keyboard commands, and large-note scrolling behave like a native Mac editor.
- Controllers and UI state are `@MainActor`. No background task is needed in this phase.

This boundary lets Phase 3 replace the in-memory session storage with a persistence service without coupling storage to AppKit window management.

## Files

### Modify

- `Stickyy/App/AppDelegate.swift` — create and retain the session, popover controller, and status-item controller.
- `Stickyy/StickyyApp.swift` — keep the settings scene lightweight and provide the normal application command surface where appropriate.
- `Stickyy/Resources/Localizable.xcstrings` — add user-facing editor, status-item, and quit strings.
- `StickyyTests/StickyyTests.swift` — retain the Phase 1 identity test and add session behavior tests.
- `StickyyUITests/StickyyUITests.swift` — replace the launch-only test with menu-bar open/close and editor-focus coverage where macOS UI automation can address the controls reliably.

### Create

- `Stickyy/App/StatusItemController.swift`
- `Stickyy/App/PopoverController.swift`
- `Stickyy/Features/Scratchpad/ScratchpadSession.swift`
- `Stickyy/Features/Scratchpad/ScratchpadView.swift`
- `Stickyy/Features/Scratchpad/ScratchpadEditor.swift`
- `Stickyy/DesignSystem/StickyyMetrics.swift`
- `StickyyTests/ScratchpadSessionTests.swift`

No package dependency, database model, network entitlement, accessibility entitlement, login item, or global shortcut is added in Phase 2. The configurable global shortcut is part of Phase 5 in the approved roadmap.

## Ten implementation steps

1. **Create a Phase 2 branch.** Start from the verified `main` branch with `git switch -c phase-2-menu-bar`.
2. **Add the in-memory session.** Implement a small observable `@MainActor` model containing only the current text and explicit reset behavior. It must not access `UserDefaults`, files, SwiftData, or the network.
3. **Build the native editor bridge.** Wrap an `NSTextView` inside `NSScrollView`; bind its text to the session; enable undo, selection, find, spelling behavior, keyboard navigation, and natural scrolling; expose a focus request and an Escape callback.
4. **Build the scratchpad view.** Add a compact editor-first SwiftUI layout with a sensible minimum size, accessibility labels, and no decorative controls that compete with typing.
5. **Create the popover controller.** Own one reusable `NSPopover`, host `ScratchpadView`, use transient behavior, anchor it to the status-item button, and expose `show`, `close`, and `toggle` operations.
6. **Create the status-item controller.** Install the template `note.text` symbol, tooltip, accessibility description, left-click toggle behavior, and a right-click menu containing About/phase information and Quit.
7. **Wire the composition root.** Update `AppDelegate` to construct and retain the session and both controllers after setting accessory activation policy. Avoid singletons and global mutable state.
8. **Handle focus and lifecycle edges.** Focus the text view after presentation, return focus on every reopen, close on Escape or outside click, and behave correctly across Light/Dark Mode, Space changes, and multiple displays.
9. **Test and inspect.** Add unit tests for session initialization/reset, UI smoke coverage for launch and opening, then manually verify copy/paste, selection, undo/redo, scrolling, repeated toggling, focus, and quit behavior.
10. **Release-check and merge.** Run Debug tests and a clean Release build, inspect the built bundle and entitlements, review the diff, commit, push the branch, and merge only after every exit criterion below passes.

## Verification commands

```sh
xcodebuild \
  -project Stickyy.xcodeproj \
  -scheme Stickyy \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/StickyyPhase2DerivedData \
  clean test

xcodebuild \
  -project Stickyy.xcodeproj \
  -scheme Stickyy \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/StickyyPhase2Release \
  clean build
```

## Manual test matrix

- Launch shows a single Stickyy icon and no Dock icon.
- Left-click opens beneath the correct menu-bar icon.
- A second left-click closes it; repeated toggling never creates duplicate windows.
- The editor is first responder on every open, so typing works immediately.
- Escape and clicking outside close the popover.
- Typed text remains after closing and reopening during the same app session.
- Command-X/C/V/A/Z and Shift-Command-Z behave normally.
- Arrow keys, Option/Command navigation, selection, and smooth scrolling work.
- A large temporary note remains responsive.
- Light Mode, Dark Mode, Reduce Motion, and Reduce Transparency remain usable.
- The popover positions correctly on every attached display and after changing Spaces.
- Right-click exposes Quit, and quitting leaves no helper process behind.
- No network or new privacy-sensitive entitlement appears in the signed bundle.

## Exit criteria

Phase 2 is complete only when:

- the status icon reliably toggles one scratchpad popover;
- typing is immediate because the editor receives focus automatically;
- native editing and keyboard interactions work;
- text survives popover close/reopen for the current process lifetime;
- closing and reopening does not leak or duplicate controllers;
- all automated tests pass;
- a clean Release build succeeds; and
- persistence, multiple scratchpads, global shortcuts, launch at login, and final Liquid Glass polish remain out of scope for their assigned phases.

## Phase 3 handoff

Phase 3 will introduce a storage protocol and a local SwiftData implementation, debounce automatic saves, restore the most recent text at startup, flush pending changes during termination, and add data-integrity and recovery tests. The Phase 2 editor and controllers should not need to know which persistence technology is used.
