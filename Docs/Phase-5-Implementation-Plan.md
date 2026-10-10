# Phase 5 — Advanced Scratchpads and Settings

## Goal

Turn Stickyy from a single persistent note into a practical scratchpad library without compromising the fast, minimal menu-bar experience.

## Delivered

### Scratchpad library

- Multiple locally stored scratchpads
- New scratchpad creation with immediate selection
- Rename workflow with whitespace cleanup and an `Untitled` fallback
- Pin and unpin actions, with pinned scratchpads sorted first
- Case-insensitive search across titles and note bodies
- Delete confirmation before destructive removal
- Automatic blank scratchpad creation when the final item is deleted
- Last-active scratchpad restoration across launches
- Safe migration of the original Phase 3/4 `primary` record

The existing note icon in the header opens the library, so no extra toolbar or editor chrome was introduced.

### Appearance

- The pre-Liquid-Glass 420 × 320 design is the default
- The original horizontal header, divider, and uninterrupted editor are retained
- No close button or inset editor card
- Liquid Glass is optional in Settings
- Enabling Liquid Glass changes only the outer surface material; layout and controls remain identical
- Reduce Transparency always receives an opaque semantic background

### App settings

- Launch at Login toggle powered by `SMAppService`
- Global shortcut presets, with Control–Option–Space as the default
- Shortcut can be changed or disabled without restarting Stickyy
- Appearance toggle for Liquid Glass
- Settings is available from the menu-bar icon's right-click menu

### Persistence and reliability

- Each scratchpad has a stable identifier, title, body, pin state, creation date, and update date
- The active note retains the 300 ms debounced autosave behavior
- Switching notes flushes the outgoing note before selection changes
- Storage errors remain visible without discarding in-memory text
- All content remains inside the app sandbox; no network or Accessibility permission is used

## Verification

- Unit coverage for creation, remembered selection, autosave coalescing, search, pin ordering, rename, deletion, and failure handling
- In-memory SwiftData coverage for multiple records, updates, deletion, and legacy migration
- UI coverage for launch, editing, Escape dismissal, creating a second scratchpad, and relaunch restoration
- Debug test suite and Release build must pass before Phase 5 is considered complete

## Phase 6 handoff

Phase 6 should focus on performance profiling, accessibility audits, long-note stress testing, migration testing against archived stores, and crash-free soak testing.
