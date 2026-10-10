# Phase 4 — Liquid Glass Design

> Status: Implemented and verified.

Phase 4 gives Stickyy a focused native macOS identity while preserving its instant open-type-close workflow.

## Design direction

- One primary Liquid Glass surface keeps rendering restrained and visually coherent.
- A single interactive glass close control provides subtle native feedback without adding a toolbar.
- The scratchpad editor sits on a quiet semantic layer for legibility over changing desktop content.
- System label, accent, and background colors adapt automatically to Light Mode and Dark Mode.
- Typography follows the macOS system font and preserves the user's system text choices.
- Spacing and corner radii are centralized in `StickyyMetrics`.
- No gradients, decorative animation, custom theme, or visual feature outside the Phase 4 brief is introduced.

## Accessibility behavior

- Reduce Transparency replaces glass with an opaque system window background and a contrast-aware border.
- Reduce Motion disables custom error and placeholder transitions.
- The popover's native animation remains disabled when the system Reduce Motion preference is active.
- The close control has a localized accessibility label, tooltip, keyboard equivalent, and stable UI-test identifier.
- All text and borders use semantic colors so increased contrast and appearance changes remain system-driven.

## Interaction and layout

- The popover is 440 × 350 points, providing more writing room without becoming a document window.
- The brand block is compact and left aligned; the editor remains the visual priority.
- The editor uses overlay scrolling, consistent 16-point text insets, and increased line spacing.
- Escape, the close control, clicking outside the popover, and clicking the menu-bar item all retain their expected behavior.
- Phase 3 autosave and restoration behavior is unchanged.

## Files

### Created

- `Stickyy/DesignSystem/StickyySurface.swift`

### Modified

- `Stickyy/DesignSystem/StickyyMetrics.swift`
- `Stickyy/Features/Scratchpad/ScratchpadView.swift`
- `Stickyy/Features/Scratchpad/ScratchpadEditor.swift`
- `Stickyy/App/AppEnvironment.swift`
- `Stickyy/App/StatusItemController.swift`
- `Stickyy/StickyyApp.swift`
- `Stickyy/Resources/Localizable.xcstrings`
- `StickyyUITests/StickyyUITests.swift`
- `README.md`

## Verification

- The installed macOS SDK's native SwiftUI `glassEffect` API is used directly.
- Light and Dark appearances use semantic system colors rather than fixed palettes.
- Reduce Transparency and Reduce Motion have explicit fallbacks.
- UI coverage verifies the accessible close control and existing editor behavior.
- Persistence restoration continues to be tested across an actual application relaunch.
- Debug tests and a clean Release build pass.

## Out of scope

Multiple scratchpads, search, pinning, configurable shortcuts, and settings controls remain assigned to Phase 5. Performance profiling and the full accessibility audit remain assigned to Phase 6.
