# Phase 6 — Testing and Optimization

Phase 6 turns Stickyy's Phase 5 feature set into a measured, regression-tested release candidate. The work focuses on data safety, end-to-end workflows, accessibility, and resource use; it does not change the minimal default design.

## What changed

- Expanded the test suite to 43 tests: 33 unit, storage, preference, and performance tests plus 10 UI tests.
- Added coverage for invalid selection recovery, failed loads/saves/deletes, switching-note flushes, delete edge cases, pin sorting, empty rename handling, and 1 MB notes.
- Added preference and native shortcut mapping tests.
- Added full UI workflows for search, rename, pin, delete, Settings, the default global shortcut, relaunch recovery, and forced-process-exit recovery.
- Added a native XCTest accessibility audit and explicit labels, values, hints, and identifiers for the editor, library rows, row actions, Settings controls, and navigation controls.
- Reworked autosave from trailing-edge debounce to a coalesced fixed save window. Continuous typing now receives periodic durable saves instead of indefinitely delaying the first write; popover close, note switching, and application termination still flush immediately.
- Added XCTest performance measurements for searching 5,000 scratchpads and saving/loading a 1 MB scratchpad.

## Validation environment

- Date: October 11, 2026
- macOS 27.0 (26A428), Apple silicon
- Xcode 27.0 toolchain
- Debug tests; optimized Release build for live-process resource checks

## Final results

| Gate | Result |
| --- | --- |
| Complete automated suite | 43 passed, 0 failed |
| UI suite | 10 passed, 0 failed |
| Xcode static analysis | Passed |
| Address Sanitizer | 31 applicable non-performance tests passed; no sanitizer findings |
| Thread Sanitizer | 31 applicable non-performance tests passed; no sanitizer findings |
| Optimized Release build | Passed |
| Apple `leaks` inspection | 0 leaks, 0 leaked bytes |
| Accessibility audit | Passed for Stickyy-owned scratchpad UI |
| Forced-termination recovery | Exact edited text restored after an immediate `_exit` test crash |

The accessibility test ignores only macOS-owned Touch Bar, Siri, and emoji-candidate elements that XCTest exposes beneath Stickyy's process hierarchy. Stickyy-created controls remain in scope.

## Measured baselines

XCTest records five samples for each benchmark:

| Benchmark | Measurements | Average | Regression ceiling |
| --- | --- | ---: | ---: |
| Search 5,000 scratchpads | 8.78, 8.67, 9.04, 8.55, 8.42 ms | 8.69 ms | 12 ms |
| Save and load a 1 MB scratchpad | 4.16, 3.89, 3.82, 3.80, 3.84 ms | 3.90 ms | 6 ms |
| Warm launch until responsive | approximately 390–420 ms across repeated UI-test launches | approximately 410 ms | 600 ms |

The release app was also sampled for five idle seconds:

- CPU: 0.0% in every sample
- Resident memory reported by `ps`: 83.5 MB
- Physical footprint reported by Apple `leaks`: 18.4 MB, with an 18.6 MB peak
- Detected leaks: 0 bytes

These values are development-machine baselines, not guarantees across all Macs. Re-profile after substantial storage, rendering, or background-work changes. Treat a sustained result above a listed ceiling, idle CPU above 1%, idle physical footprint above 30 MB, or any detected leak as a regression to investigate.

## Crash-recovery contract

Stickyy saves the latest active text at most once per coalescing window while typing. It additionally flushes synchronously when switching scratchpads, closing the popover, or terminating normally. The forced-exit UI test bypasses normal termination callbacks and confirms that a completed autosave is durable in SwiftData.

## Running the suite

From the repository root:

```sh
xcodebuild \
  -project Stickyy.xcodeproj \
  -scheme Stickyy \
  -destination 'platform=macOS' \
  -derivedDataPath .build/Phase6 \
  test
```

Run static analysis from Xcode with **Product → Analyze**, or use `xcodebuild` with the same project, scheme, and destination followed by `analyze`. Address Sanitizer and Thread Sanitizer can be enabled from the scheme's Test diagnostics when investigating future changes.

## Phase 6 exit criteria

- All core scratchpad behavior has deterministic automated coverage.
- The complete test suite passes from a clean derived-data location.
- Crash recovery is verified without relying on normal shutdown.
- Stickyy-owned UI passes the native accessibility audit.
- Static analysis and both sanitizers report no defects.
- The optimized build has measured performance and resource baselines.
- The default appearance remains the original minimal material; Liquid Glass remains optional and layout-neutral.

Phase 6 is complete.
