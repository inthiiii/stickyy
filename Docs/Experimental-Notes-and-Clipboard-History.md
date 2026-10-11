# Notes and Clipboard History Experiment

This branch is an experiment built on the completed Phase 6 release. The Phase 6
snapshot remains unchanged on `main` at commit
`73de0feeee1816af5b8f1307db1eab0ae4cd4f91`.

## Export to Apple Notes

The share button in the scratchpad header opens the native macOS share sheet.
Choose Notes to create a note containing the scratchpad title followed by its
text. The button is disabled while the scratchpad is empty.

This approach stays within Apple's public sharing APIs and does not request
permission to automate the Notes app.

## Clipboard history

Stickyy watches the system clipboard while the app is running and keeps the five
most recent distinct entries in memory. It supports:

- Plain text
- PNG and TIFF images
- One or more file URLs copied together

Each entry appears as a compact, floating pill in a horizontally scrollable
shelf below the scratchpad. The shelf is visually separate from the note so the
main editor keeps its original minimal size and layout. Image entries include a
small circular preview and their file name when one is available.

Text entries have a Paste button that inserts their contents at the current
editor selection. The five newest entries can also be pasted with Command-1
through Command-5. Selecting the main part of any pill restores that entry to
the system clipboard and moves it to the front of the history. Text pills use
simple contextual icons for links, email addresses, and phone numbers.

Use the trash button at the end of the shelf to clear all five entries without
changing the current system clipboard. Clipboard History can be turned off in
Stickyy Settings whenever a distraction-free scratchpad is preferred. Turning
it off immediately clears the temporary history and hides the entire shelf;
turning it back on resumes monitoring new clipboard changes. While history is
off, a small clipboard button remains in the editor's bottom-right corner for
directly pasting plain text without storing any clipboard history. Images and
files are deliberately ignored by that direct-paste button.

Clipboard history is intentionally temporary in this experiment. It is not
written to Stickyy's scratchpad store, synced, or restored after the app quits.

## Returning to Phase 6

Switch back to `main`. The experiment lives only on
`experiment/notes-clipboard-history`, so no revert or destructive reset is
required.
