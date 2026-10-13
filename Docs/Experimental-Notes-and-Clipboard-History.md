# Notes and Clipboard History

This feature set was stabilized after Phase 6 and merged into `main` before
Phase 7 began.

## Export to Apple Notes

The share button in the scratchpad header uses native macOS sharing services in
a menu that remains reliable inside the menu-bar popover. Notes, Messages, and
other compatible destinations are available; Shortcuts is intentionally hidden.
The button is disabled while the scratchpad is empty.

This approach stays within Apple's public sharing APIs and does not request
permission to automate the Notes app.

## Clipboard history

Stickyy watches the system clipboard while the app is running and keeps the five
or seven most recent distinct entries in memory, according to the user's setting.
It supports:

- Plain text
- PNG and TIFF images
- One or more file URLs copied together

Each entry appears as a compact, floating pill in a horizontally scrollable
shelf below the scratchpad. The shelf is visually separate from the note so the
main editor keeps its original minimal size and layout. Image entries include a
small circular preview and their file name when one is available.

Text entries have a Paste button that inserts their contents at the current
editor selection. Numbered entries can also be pasted with Command-1 through
Command-7. Double-clicking the main part of any pill restores that entry to the
system clipboard and moves it to the front of the history. Text pills use simple
contextual icons for links, email addresses, and phone numbers.

Use the trash button at the end of the shelf to clear all entries without
changing the current system clipboard. Clipboard History can be turned off in
Stickyy Settings whenever a distraction-free scratchpad is preferred. Turning
it off immediately clears the temporary history and hides the entire shelf;
turning it back on resumes monitoring new clipboard changes. While history is
off, a small clipboard button appears in the editor's bottom-right corner only
when plain text is currently available to paste, without storing any clipboard
history. Images and files are deliberately ignored by that direct-paste button.

Liquid Glass now applies consistently to the optional clipboard pills as well
as the scratchpad surface. The shelf is positioned against the visible edge of
the scratchpad and uses the same opening animation.

## Additional experiment features

- A recordable keyboard shortcut with Control–Option–Space as the default
- `---` expands into a visual divider in the editor
- Pasted images and files appear as compact attachment previews with a Show in
  Finder action
- A three-page interactive onboarding tour that finishes with a welcome note
- A compact User Guide available from Settings
- The header tagline has been removed to keep the editor visually quiet

Clipboard history is intentionally temporary in this experiment. It is not
written to Stickyy's scratchpad store, synced, or restored after the app quits.

This stable version is the release baseline used by Phase 7.
