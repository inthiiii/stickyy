#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h:h}"
build_dir="$root_dir/.build/PublicTest"
derived_data="$build_dir/DerivedData"
staging_dir="$build_dir/dmg-root"
app_path="$derived_data/Build/Products/Release/Stickyy.app"
dmg_path="$build_dir/Stickyy-1.0.0.dmg"
checksum_path="$dmg_path.sha256"

mkdir -p "$build_dir"

xcodebuild \
  -project "$root_dir/Stickyy.xcodeproj" \
  -scheme Stickyy \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  clean build

codesign \
  --force \
  --deep \
  --sign - \
  --options runtime \
  --entitlements "$root_dir/Stickyy/Stickyy.entitlements" \
  "$app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"

if [[ -d "$staging_dir" ]]; then
  find "$staging_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
  mkdir -p "$staging_dir"
fi

ditto "$app_path" "$staging_dir/Stickyy.app"
ln -s /Applications "$staging_dir/Applications"

if [[ -f "$dmg_path" ]]; then
  rm "$dmg_path"
fi

hdiutil create \
  -volname Stickyy \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg_path"

hdiutil verify "$dmg_path"
checksum_value="$(shasum -a 256 "$dmg_path" | awk '{print $1}')"
print "$checksum_value  ${dmg_path:t}" > "$checksum_path"

echo "Public test release created:"
echo "  $dmg_path"
echo "  $checksum_path"
echo "This build is ad-hoc signed and not Apple-notarized."
