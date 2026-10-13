# Phase 7 — Production Release

Phase 7 turns the tested Stickyy baseline into a safe direct-download product.
The first distribution channel is a notarized disk image linked from a one-page
website. A Mac App Store release remains a later option.

## Release identity

| Field | Value |
| --- | --- |
| Product | Stickyy |
| Version | 1.0.0 |
| Build | 1 |
| Bundle ID | `com.inthiiii.Stickyy` |
| Team ID | `W646PJF57Y` |
| Minimum macOS | 26.0 |
| Distribution | Direct download |
| Package | Signed and notarized `.dmg` |

## Completed preparation

- Release version and copyright metadata are set.
- Hardened Runtime and App Sandbox remain enabled.
- A complete production AppIcon set is included.
- The privacy policy documents local storage and the absence of tracking.
- `Scripts/check-release-readiness.sh` audits the local release prerequisites.
- `Scripts/release.sh` archives, signs, packages, notarizes, staples, verifies,
  and checksums the disk image without storing credentials in the repository.
- `Config/ExportOptions-DeveloperID.plist` supports Xcode's Developer ID export
  workflow with automatic signing.
- The one-page website is ready for free deployment and automatically discovers
  the latest GitHub `.dmg` release.

## One-time Apple setup

Direct distribution requires an active Apple Developer Program membership and a
**Developer ID Application** certificate installed with its private key in
Keychain Access.

Create the notarization keychain profile once. The command prompts securely for
the app-specific password and stores it in Keychain; no credential belongs in
Git, shell history, or a configuration file.

```sh
xcrun notarytool store-credentials "Stickyy-Notary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "W646PJF57Y"
```

## Build the release

From the repository root:

```sh
Scripts/check-release-readiness.sh
Scripts/release.sh
```

The release script stops before building if the signing identity or notarization
profile is unavailable. On success it produces:

- `.build/Release/Stickyy-1.0.0.dmg`
- `.build/Release/Stickyy-1.0.0.dmg.sha256`

## Publish the GitHub release

1. Confirm the full automated suite passes from a clean checkout.
2. Run the release script and retain its successful notarization result.
3. Create the annotated tag `v1.0.0` from the approved release commit.
4. Create a GitHub release from that tag using the `1.0.0` changelog section.
5. Upload the notarized `.dmg` and `.sha256` files.
6. Download the public asset on a separate Mac and verify Gatekeeper acceptance.
7. Confirm the website changes its primary button to **Download Stickyy 1.0.0**.

Do not upload an unsigned, unstapled, or locally bypassed build as a public
release.

## Website hosting

The static site lives in `Website/`. Its GitHub Pages workflow deploys the site
after changes reach `main`. GitHub Pages must be configured once in repository
Settings → Pages with **GitHub Actions** as the source. Until the first public
`.dmg` exists, the site safely links visitors to the Releases page instead of a
missing asset.

## App Store option

The current direct-download build is not an App Store submission. A future App
Store phase should create the App Store Connect record, replace Developer ID
distribution with Mac App Distribution, prepare screenshots and store metadata,
complete App Privacy answers, validate sandbox behavior, and pass App Review.

## Remaining release gate

On October 13, 2026, Xcode successfully created the Release archive using the
installed Apple Development identity. The Developer ID export then reached Apple
and was rejected because team `W646PJF57Y` does not have a program membership
eligible for Developer ID distribution. No Developer ID Application identity is
available, and the `Stickyy-Notary` profile cannot be completed until the team is
eligible.

The Account Holder must activate or renew the Apple Developer Program membership.
After Apple marks the team eligible, install a Developer ID Application
certificate, create the notarization profile above, rerun the readiness check,
and run the release script. These credentials are intentionally never committed.

An unsigned or Apple Development-signed build is not a substitute for this gate:
it would force public testers to bypass Gatekeeper and is not published by the
release process.
