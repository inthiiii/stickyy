# Changelog

All notable Stickyy changes are documented here.

## 1.1.0 — Floating notes and in-app updates (prepared, not published)

- Added a movable, resizable, always-on-top floating note triggered by the
  global shortcut, including full-screen Space support.
- Added Settings controls to disable floating behavior or choose the active
  note versus a fresh note on each opening.
- Kept Clipboard Pills, the header, and sharing out of the floating panel while
  preserving the original menu-bar scratchpad.
- Added Sparkle 2.10 automatic updates, manual update checks, EdDSA update
  signing, sandboxed installer helpers, and a local appcast preparation flow.
- Updated the built-in User Guide and regression tests for the new workflows.

## 1.0.1 — Installer update

- Replaced the plain disk image with a polished drag-to-Applications installer
  window, clear visual guidance, and a first-launch notice.
- Added an interactive three-step installation guide to the download website.
- Migrated the public website from ChatGPT Sites to Vercel.
- Clarified that eliminating macOS Gatekeeper approval requires Apple Developer
  ID signing and notarization; the free public-test build remains ad-hoc signed.

## 1.0.0 — Release candidate

- Instant menu-bar scratchpad with a configurable global shortcut.
- Reliable local autosave, recovery, and multiple scratchpads.
- Search, rename, pin, and delete workflows.
- Minimal material design with optional Liquid Glass.
- Optional five- or seven-item Clipboard Pills for text, images, and files.
- Double-click clipboard restoration and Command-1 through Command-7 quick paste.
- Native macOS sharing, attachment previews, onboarding, and built-in User Guide.
- Accessibility, crash-recovery, performance, storage, and UI regression coverage.
- Free public-test DMG packaging and direct-download website, with a separate
  Developer ID notarization path ready for future use.
