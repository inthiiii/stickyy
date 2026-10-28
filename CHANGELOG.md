# Changelog

All notable Stickyy changes are documented here.

## 1.2.8.1 — Liquid Glass hotfix

- Restored the native Liquid Glass appearance in the menu-bar scratchpad,
  floating note, and compact controls.
- Isolated the glass backdrop from dynamic editor overlays so section
  navigation no longer changes or invalidates the window surface.
- Preserved the original minimal material path when Liquid Glass is disabled.

## 1.2.8 — Faster structure and accurate recent paste

- Fixed the floating-note paste action so it inserts the most recently copied
  text instead of the first pinned Clipboard Pill.
- Added automatic solid bullets when `- ` is typed at the beginning of a line,
  including Return-to-continue and an empty-bullet exit.
- Added `->` expansion into a right arrow.
- Turned `---` dividers into navigable note sections with a compact dot
  navigator in both the menu-bar scratchpad and floating panel.
- Kept Liquid Glass blur stable when the section navigator appears.
- Bounded long section navigators to a compact scrollable control and added an
  Editor setting for hiding the navigator.
- Repaired Settings access from the menu-bar icon's contextual menu.
- Added a three-second ready card when Stickyy launches or starts at login.
- Added an isolated UI-test command that uses a separate bundle identifier and
  storage container, protecting data in an installed Stickyy app during tests.

## 1.2.7 — Richer notes and pinned Clipboard Pills

- Added optional live word or character counts to the menu-bar scratchpad and
  floating note.
- Added persistent bold, italic, and underline formatting to both editors.
- Added optional pinned Clipboard Pills. Pinned items stay available while the
  remaining five- or seven-item capacity continues to rotate.
- Clipboard clearing now preserves pinned items, which can be managed from
  Settings.
- Simplified the floating note clipboard action to one text-only icon.
- Fixed the long-note layout issue that could push text toward the middle or
  bottom of the editor while typing.

## 1.2.6 — Faster note creation

- Press Command-N while the menu-bar scratchpad is open to create and switch to
  a new blank scratchpad immediately.
- Removed the temporary updater-repair notice from the public download page.

## 1.2.5 — Updater repair

- Fixed the sandbox permission used to connect Stickyy to Sparkle's installer.
- Added release-time verification that rejects unresolved Sparkle service names
  before a DMG can be published.
- Versions older than build 6 now receive an informational update that directs
  them to the website for the one-time manual repair install.
- Once 1.2.5 is installed, future signed updates can be installed from inside
  Stickyy normally.

## 1.2.1 — Links, context, and smoother updates

- URLs in scratchpads now appear as blue, underlined, clickable links.
- Clicking the Stickyy header briefly reveals the active note title, then
  automatically returns to the app name after five seconds.
- Floating notes now offer the latest clipboard item in a compact bottom-right
  button without bringing the full Clipboard Pills shelf into the panel.
- First-time users reliably receive the onboarding tour and welcome note.
- Existing users receive a dedicated “Latest update” scratchpad once per app
  version, without replacing their current notes.
- The public DMG now uses a Finder-compatible HFS+ layout and verifies that the
  custom Drag to Applications design is saved before packaging.

## 1.1.1 — Compatibility and onboarding update

- Expanded compatibility from macOS 26 to macOS 14 and guarded Liquid Glass
  behind its macOS 26 availability requirement.
- Fixed public-build startup by signing Stickyy and every embedded Sparkle
  component with one consistent identity.
- Added a dedicated floating-note preview to the welcome tour.
- Moved public downloads and the Sparkle update archive onto the Stickyy domain.
- Removed public GitHub navigation and source links from the website.

## 1.1.0 — Floating notes and in-app updates

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
