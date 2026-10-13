# Phase 7 — Production Release

Phase 7 turns the tested Stickyy baseline into a direct-download product. The
first public test is an ad-hoc-signed disk image linked from the one-page website.
It requires no paid Apple Developer Program membership. A notarized Developer ID
release remains available later if the team enrolls.

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
| Package | Ad-hoc-signed public-test `.dmg` |

## Completed preparation

- Release version and copyright metadata are set.
- Hardened Runtime and App Sandbox remain enabled.
- A complete production AppIcon set is included.
- The privacy policy documents local storage and the absence of tracking.
- `Scripts/check-release-readiness.sh` audits the local release prerequisites.
- `Scripts/build-public-test-dmg.sh` builds, ad-hoc signs, verifies, packages,
  and checksums a no-membership public test release.
- `Scripts/release.sh` archives, signs, packages, notarizes, staples, verifies,
  and checksums the disk image without storing credentials in the repository.
- `Config/ExportOptions-DeveloperID.plist` supports Xcode's Developer ID export
  workflow with automatic signing.
- The one-page website is ready for free deployment and automatically discovers
  the latest GitHub `.dmg` release.

## Build the free public test

From the repository root:

```sh
Scripts/build-public-test-dmg.sh
```

On success it produces:

- `.build/PublicTest/Stickyy-1.0.0.dmg`
- `.build/PublicTest/Stickyy-1.0.0.dmg.sha256`

The app is ad-hoc signed and is not notarized. On first launch, a tester must:

1. Drag Stickyy into Applications.
2. Control-click Stickyy in Applications and choose **Open**.
3. Confirm **Open** in the macOS prompt.

After this one-time approval, Stickyy opens normally. The website and GitHub
release must keep this disclosure visible.

## Optional notarized production release

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

### Build the notarized release

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
2. Run the free public-test script, or the production script if Developer ID is
   available.
3. Create the annotated tag `v1.0.0` from the approved release commit.
4. Create a GitHub release from that tag using the `1.0.0` changelog section.
5. Upload the `.dmg` and `.sha256` files.
6. Download the public asset on a separate Mac and verify its documented opening
   flow.
7. Confirm the website changes its primary button to **Download Stickyy 1.0.0**.

For the free build, release notes must say that it is ad-hoc signed and not
notarized. Never describe it as Apple-verified or notarized.

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

## Notarized-release gate

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

This gate applies only to the optional notarized release. The public-test path
uses an ad-hoc signature and the documented Control-click opening flow instead.
