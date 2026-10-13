#!/bin/zsh

set -u

readonly REPOSITORY_ROOT="${0:A:h:h}"
cd "${REPOSITORY_ROOT}"

failures=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    print "✓ ${label}"
  else
    print "✗ ${label}"
    failures=$((failures + 1))
  fi
}

check "Git working tree is clean" zsh -c '[[ -z "$(git status --porcelain)" ]]'
check "Release version is 1.0.0" zsh -c 'xcodebuild -project Stickyy.xcodeproj -scheme Stickyy -configuration Release -showBuildSettings | grep -q "MARKETING_VERSION = 1.0.0"'
check "Hardened Runtime is enabled" zsh -c 'xcodebuild -project Stickyy.xcodeproj -scheme Stickyy -configuration Release -showBuildSettings | grep -q "ENABLE_HARDENED_RUNTIME = YES"'
check "App Sandbox is enabled" zsh -c 'xcodebuild -project Stickyy.xcodeproj -scheme Stickyy -configuration Release -showBuildSettings | grep -q "ENABLE_APP_SANDBOX = YES"'
check "Production app icon is present" test -s Stickyy/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
check "Developer ID Application identity is installed" zsh -c 'security find-identity -v -p codesigning | grep -q "Developer ID Application"'
check "Notarization profile is usable" xcrun notarytool history --keychain-profile "${NOTARY_PROFILE:-Stickyy-Notary}"

if (( failures > 0 )); then
  print ""
  print "${failures} release requirement(s) still need attention."
  exit 1
fi

print ""
print "Stickyy is ready for a signed and notarized release build."
