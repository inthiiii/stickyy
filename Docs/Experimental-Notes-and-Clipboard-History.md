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

Each entry appears as a compact pill below the editor in a vertically scrollable
list. Selecting a pill places that entry back on the clipboard and moves it to
the front of the history.

Clipboard history is intentionally temporary in this experiment. It is not
written to Stickyy's scratchpad store, synced, or restored after the app quits.

## Returning to Phase 6

Switch back to `main`. The experiment lives only on
`experiment/notes-clipboard-history`, so no revert or destructive reset is
required.
