# Stickyy

**Catch a thought before it fades.**

Stickyy is a fast, local-first macOS menu-bar scratchpad built with SwiftUI, AppKit, and SwiftData.

## Current status

Phase 4 provides a polished, persistent Liquid Glass scratchpad:

- Xcode 27 project
- Swift 6 language mode and complete concurrency checking
- macOS 26 deployment target
- App Sandbox and Hardened Runtime
- Menu-bar-only application with a reusable popover
- Native AppKit text editor with focus, selection, undo/redo, and scrolling
- Debounced automatic saving with local SwiftData storage
- Text restoration after quitting, relaunching, or restarting macOS
- Immediate save flushing when the popover closes or the app quits
- Visible storage-failure handling without discarding current text
- Native Liquid Glass surface and interactive close control
- Adaptive semantic styling for Light Mode and Dark Mode
- Solid, high-contrast fallback for Reduce Transparency
- Motion that automatically respects Reduce Motion
- Refined typography, spacing, editor framing, and overlay scrolling
- Escape and outside-click dismissal
- Swift Testing and UI-test targets

Multiple scratchpads, search, pinning, and configurable shortcuts remain assigned to Phase 5.

## Requirements

- macOS 26 or later
- Xcode 27 or later

## Running

1. Open `Stickyy.xcodeproj`.
2. Select the **Stickyy** scheme and **My Mac**.
3. Press Command-R.
4. Find the note icon in the macOS menu bar.
5. Left-click the icon to toggle the scratchpad; right-click it to quit.

## Testing

Press Command-U in Xcode, or run:

```sh
xcodebuild \
  -project Stickyy.xcodeproj \
  -scheme Stickyy \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/DerivedData \
  clean test
```

## Privacy

Stickyy is local-first and requires no network connection for its core functionality. Scratchpad text is stored in the app's sandbox using SwiftData. The app requests no network, broad file-access, automation, accessibility, microphone, camera, contacts, calendar, or location entitlement.
