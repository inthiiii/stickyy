# Stickyy

**Catch a thought before it fades.**

Stickyy is a fast, local-first macOS menu-bar scratchpad built with SwiftUI, AppKit, and SwiftData.

## Current status

Stickyy 1.2.8.1 is a stable local-first scratchpad with automated quality, recovery, accessibility, and performance coverage while preserving its original minimal design. Its editors support rich-text emphasis, optional live counts, lightweight list transformations, and section navigation, while pinned Clipboard Pills keep important copied items available.

- Xcode 27 project
- Swift 6 language mode and complete concurrency checking
- macOS 14 deployment target, with Liquid Glass available on macOS 26 or later
- App Sandbox and Hardened Runtime
- Menu-bar-only application with a reusable popover
- Native AppKit text editor with focus, selection, undo/redo, and scrolling
- Coalesced automatic saving with local SwiftData storage
- Periodic durable saves during continuous typing to bound crash-loss risk
- Text restoration after quitting, relaunching, or restarting macOS
- Immediate save flushing when the popover closes or the app quits
- Visible storage-failure handling without discarding current text
- Multiple independent scratchpads with remembered selection
- Command-N creates a fresh scratchpad while the menu-bar note is open
- Create, rename, pin, search, and delete workflows
- Destructive delete confirmation and automatic blank-note replacement
- Recordable global keyboard shortcut (Control–Option–Space by default)
- Optional movable, resizable floating note that stays above apps and full-screen Spaces
- Choose whether the floating shortcut reuses the active note or creates a new one
- Optional launch at login
- A real Settings window available from the menu-bar context menu
- Original minimal material appearance by default
- Optional Liquid Glass that changes only the surface—not the layout
- Adaptive semantic styling for Light Mode and Dark Mode
- Solid, high-contrast fallback for Reduce Transparency
- Escape and outside-click dismissal
- Native Notes, Messages, and system sharing without the Shortcuts destination
- Optional clipboard pills with a user-selected five- or seven-item history
- Double-click any pill to copy it again; use Command-1 through Command-7 to paste into Stickyy
- Image/file attachment previews with Show in Finder links
- Three-hyphen quick dividers
- Interactive four-page welcome tour that opens a saved welcome scratchpad
- Built-in User Guide in Settings
- 50+ automated unit, storage, preference, performance, accessibility, and UI tests
- Forced-termination recovery coverage
- Xcode static analysis plus Address Sanitizer and Thread Sanitizer validation
- Release-build CPU, memory, and leak baselines
- Production AppIcon, privacy policy, direct-download release tooling, and one-page website
- Signed Sparkle update feed with automatic checks and a manual Check for Updates action
- Version-aware in-app release notes that appear as a new scratchpad after an update
- Clickable URL highlighting and a temporary active-note title in the main header
- Compact latest-clipboard insertion inside the floating note

## Requirements

- macOS 14 or later
- Xcode 27 or later

## Running

1. Open `Stickyy.xcodeproj`.
2. Select the **Stickyy** scheme and **My Mac**.
3. Press Command-R.
4. Find the note icon in the macOS menu bar.
5. Left-click the icon to toggle the scratchpad.
6. Click the note icon inside the scratchpad to open the scratchpad library.
7. Right-click the menu-bar icon to open Settings or quit.

The default global shortcut is **Control–Option–Space**. Click its recorder in Settings and press any preferred modified key combination to change it.

## Direct-download releases

Stickyy supports two direct-download paths. The free public-test build is uniformly development-signed and does not require an Apple Developer Program membership:

```sh
Scripts/build-public-test-dmg.sh
```

Because Apple does not notarize this build, macOS may block its first launch. After attempting to open Stickyy, go to **System Settings → Privacy & Security**, click **Open Anyway** beside Stickyy, and confirm **Open**. This is disclosed in the installer, on the download page, and in the release notes.

For a future Developer ID-signed and Apple-notarized production disk image, run:

```sh
Scripts/check-release-readiness.sh
Scripts/release.sh
```

The production release script requires a valid Developer ID Application identity and a `Stickyy-Notary` keychain profile. It creates, notarizes, staples, verifies, and checksums the `.dmg` without storing credentials in the repository.

The complete process is documented in [Docs/Phase-7-Production-Release.md](Docs/Phase-7-Production-Release.md). The source for the public [Stickyy website](https://stickyyformac.vercel.app) lives in [Website](Website).

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

The full Phase 6 validation record, measured baselines, and regression targets are in [Docs/Phase-6-Testing-and-Optimization.md](Docs/Phase-6-Testing-and-Optimization.md).

## Privacy

Stickyy is local-first and requires no network connection for its core functionality. Scratchpad text is stored in the app's sandbox using SwiftData. The app requests no network, broad file-access, automation, accessibility, microphone, camera, contacts, calendar, or location entitlement.

Read the full [Stickyy Privacy Policy](PRIVACY.md).
