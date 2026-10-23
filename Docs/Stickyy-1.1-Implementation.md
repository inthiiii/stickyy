# Stickyy 1.1 Implementation

Stickyy 1.1 is prepared locally and must not be published until release
approval is given.

## Floating note behavior

- The global shortcut opens a reusable `NSPanel` by default.
- The panel joins all Spaces, participates as a full-screen auxiliary window,
  stays above normal application windows, and remains visible when Stickyy is
  inactive.
- Escape or the global shortcut closes the panel.
- Its saved frame restores the user's last size and position.
- Settings can disable the floating behavior or choose between the active note
  and a newly created note on every opening.
- The menu-bar button always retains the original scratchpad behavior.

## Update system

- Sparkle 2.10 is embedded through Swift Package Manager.
- Update archives are verified with Stickyy's EdDSA public key. The private key
  is stored only in the developer's login Keychain.
- The appcast endpoint is
  `https://stickyyformac.vercel.app/appcast.xml`.
- The sandboxed installer and downloader XPC services are enabled without
  granting the main application general network access.
- `Scripts/prepare-sparkle-update.sh` signs the DMG entry and generates the
  local appcast. It does not upload or deploy anything.

## Release order

1. Run the complete test suite.
2. Build and verify `Stickyy-1.1.0.dmg`.
3. Run `Scripts/prepare-sparkle-update.sh`.
4. Create GitHub release `v1.1.0` and upload the DMG/checksum.
5. Only after the release asset exists, deploy `Website/dist/appcast.xml`.
6. Verify update checks from an installed v1.1 build before announcing v1.1.
