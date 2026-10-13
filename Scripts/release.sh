#!/bin/zsh

set -euo pipefail

readonly SCRIPT_DIR="${0:A:h}"
readonly REPOSITORY_ROOT="${SCRIPT_DIR:h}"
readonly PROJECT_PATH="${REPOSITORY_ROOT}/Stickyy.xcodeproj"
readonly SCHEME="Stickyy"
readonly ARCHIVE_ROOT="${REPOSITORY_ROOT}/.build/Release"
readonly ARCHIVE_PATH="${ARCHIVE_ROOT}/Stickyy.xcarchive"
readonly STAGING_PATH="${ARCHIVE_ROOT}/dmg-root"

cd "${REPOSITORY_ROOT}"

if [[ -n "$(git status --porcelain)" && "${ALLOW_DIRTY_RELEASE:-0}" != "1" ]]; then
  print -u2 "Release stopped: commit or stash all changes first."
  exit 1
fi

readonly VERSION="${VERSION:-$(xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME}" -configuration Release -showBuildSettings | awk '/MARKETING_VERSION/ { print $3; exit }')}"
readonly BUILD_NUMBER="${BUILD_NUMBER:-$(xcodebuild -project "${PROJECT_PATH}" -scheme "${SCHEME}" -configuration Release -showBuildSettings | awk '/CURRENT_PROJECT_VERSION/ { print $3; exit }')}"
readonly TEAM_ID="${TEAM_ID:-W646PJF57Y}"
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-Stickyy-Notary}"
readonly SIGNING_IDENTITY="${SIGNING_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -1)}"

if [[ -z "${SIGNING_IDENTITY}" ]]; then
  print -u2 "Release stopped: no Developer ID Application identity is installed."
  print -u2 "Install it in Keychain Access, then run this script again."
  exit 1
fi

if ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
  print -u2 "Release stopped: notarization profile '${NOTARY_PROFILE}' is unavailable or invalid."
  print -u2 "Create it with xcrun notarytool store-credentials before retrying."
  exit 1
fi

readonly APP_PATH="${ARCHIVE_PATH}/Products/Applications/Stickyy.app"
readonly DMG_PATH="${ARCHIVE_ROOT}/Stickyy-${VERSION}.dmg"
readonly CHECKSUM_PATH="${DMG_PATH}.sha256"

rm -rf "${ARCHIVE_PATH}" "${STAGING_PATH}"
rm -f "${DMG_PATH}" "${CHECKSUM_PATH}"
mkdir -p "${ARCHIVE_ROOT}" "${STAGING_PATH}"

print "Archiving Stickyy ${VERSION} (${BUILD_NUMBER})…"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "${ARCHIVE_PATH}" \
  DEVELOPMENT_TEAM="${TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
  archive

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

ditto "${APP_PATH}" "${STAGING_PATH}/Stickyy.app"
ln -s /Applications "${STAGING_PATH}/Applications"

print "Creating and signing ${DMG_PATH:t}…"
hdiutil create \
  -volname "Stickyy" \
  -srcfolder "${STAGING_PATH}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"
codesign --force --timestamp --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"

print "Submitting to Apple's notary service…"
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

xcrun stapler staple "${DMG_PATH}"
xcrun stapler validate "${DMG_PATH}"
spctl --assess --type open --context context:primary-signature --verbose=2 "${DMG_PATH}"

shasum -a 256 "${DMG_PATH}" > "${CHECKSUM_PATH}"

print ""
print "Release artifact ready:"
print "  ${DMG_PATH}"
print "  ${CHECKSUM_PATH}"
print "Upload both files to the GitHub release tagged v${VERSION}."
