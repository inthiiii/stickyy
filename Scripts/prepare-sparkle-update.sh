#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h:h}"
build_dir="$root_dir/.build/PublicTest"
updates_dir="$root_dir/.build/Updates"
derived_data="$build_dir/DerivedData"
sparkle_tools="$derived_data/SourcePackages/artifacts/sparkle/Sparkle/bin"
version="$(xcodebuild -project "$root_dir/Stickyy.xcodeproj" -scheme Stickyy -configuration Release -showBuildSettings | awk '/MARKETING_VERSION/ { print $3; exit }')"
dmg_name="Stickyy-$version.dmg"
dmg_path="$build_dir/$dmg_name"
release_notes="$root_dir/Docs/Release-Notes-$version.md"
appcast_path="$updates_dir/appcast.xml"

if [[ ! -f "$dmg_path" ]]; then
  print -u2 "Missing $dmg_path"
  print -u2 "Run Scripts/build-public-test-dmg.sh first."
  exit 1
fi

if [[ ! -x "$sparkle_tools/generate_appcast" ]]; then
  xcodebuild \
    -resolvePackageDependencies \
    -project "$root_dir/Stickyy.xcodeproj" \
    -scheme Stickyy
fi

if [[ ! -x "$sparkle_tools/generate_appcast" ]]; then
  print -u2 "Sparkle's generate_appcast tool was not found."
  exit 1
fi

mkdir -p "$updates_dir"
ditto "$dmg_path" "$updates_dir/$dmg_name"

if [[ -f "$release_notes" ]]; then
  ditto "$release_notes" "$updates_dir/Stickyy-$version.md"
fi

"$sparkle_tools/generate_appcast" \
  --download-url-prefix "https://github.com/inthiiii/stickyy/releases/download/v$version/" \
  --link "https://stickyyformac.vercel.app" \
  --embed-release-notes \
  --maximum-versions 3 \
  -o "$appcast_path" \
  "$updates_dir"

ditto "$appcast_path" "$root_dir/Website/dist/appcast.xml"

print "Sparkle update prepared locally:"
print "  $appcast_path"
print "  $root_dir/Website/dist/appcast.xml"
print "Nothing has been uploaded. Publish the GitHub release before deploying"
print "the appcast, otherwise its download URL will not exist yet."
