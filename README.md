# Stickyy

**Catch a thought before it fades.**

Stickyy is a fast, local-first macOS menu-bar scratchpad built with SwiftUI, AppKit, and SwiftData.

## Current status

Phase 1 establishes the project foundation:

- Xcode 27 project
- Swift 6 language mode and complete concurrency checking
- macOS 26 deployment target
- App Sandbox and Hardened Runtime
- Menu-bar-only smoke build
- Swift Testing and UI-test targets

The interactive scratchpad begins in Phase 2. Persistence begins in Phase 3.

## Requirements

- macOS 26 or later
- Xcode 27 or later

## Running

1. Open `Stickyy.xcodeproj`.
2. Select the **Stickyy** scheme and **My Mac**.
3. Press Command-R.
4. Find the note icon in the macOS menu bar.

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

Stickyy is local-first and requires no network connection for its core functionality. The Phase 1 app requests no network, broad file-access, automation, accessibility, microphone, camera, contacts, calendar, or location entitlement.
