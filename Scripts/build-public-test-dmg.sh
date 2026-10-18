#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h:h}"
build_dir="$root_dir/.build/PublicTest"
derived_data="$build_dir/DerivedData"
staging_dir="$build_dir/dmg-root"
mount_dir="$build_dir/dmg-mount"
app_path="$derived_data/Build/Products/Release/Stickyy.app"
background_svg="$root_dir/Resources/DMG/installer-background.svg"
background_png="$build_dir/installer-background.png"
background_renderer="$root_dir/Scripts/render-dmg-background.swift"
version="$(xcodebuild -project "$root_dir/Stickyy.xcodeproj" -scheme Stickyy -configuration Release -showBuildSettings | awk '/MARKETING_VERSION/ { print $3; exit }')"
dmg_path="$build_dir/Stickyy-$version.dmg"
rw_dmg_path="$build_dir/Stickyy-$version-rw.dmg"
checksum_path="$dmg_path.sha256"
mounted_device=""

cleanup() {
  if [[ -n "$mounted_device" ]]; then
    hdiutil detach "$mounted_device" -force >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

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
touch "$staging_dir/.metadata_never_index"
mkdir -p "$staging_dir/.background"
xcrun swift "$background_renderer" "$background_svg" "$background_png"
ditto "$background_png" "$staging_dir/.background/installer-background.png"

if [[ -f "$dmg_path" ]]; then
  rm "$dmg_path"
fi

if [[ -f "$rw_dmg_path" ]]; then
  rm "$rw_dmg_path"
fi

if [[ -d "$mount_dir" ]]; then
  find "$mount_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
  mkdir -p "$mount_dir"
fi

hdiutil create \
  -volname Stickyy \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDRW \
  "$rw_dmg_path"

attach_output="$(hdiutil attach "$rw_dmg_path" -readwrite -noverify -noautoopen -mountpoint "$mount_dir")"
mounted_device="$(print "$attach_output" | awk -v mount="$mount_dir" '$NF == mount { print $1; exit }')"

if [[ -z "$mounted_device" ]]; then
  print -u2 "Unable to determine the mounted disk-image device."
  exit 1
fi

osascript <<APPLESCRIPT
set volumeFolder to POSIX file "$mount_dir" as alias
tell application "Finder"
  open volumeFolder
  set installerWindow to container window of volumeFolder
  tell installerWindow
    set current view to icon view
    set toolbar visible to false
    set statusbar visible to false
    set pathbar visible to false
    set bounds to {120, 120, 780, 540}
  end tell
  tell icon view options of installerWindow
    set arrangement to not arranged
    set icon size to 112
    set text size to 13
    set background picture to file ".background:installer-background.png" of volumeFolder
  end tell
  set position of item "Stickyy.app" of volumeFolder to {170, 235}
  set position of item "Applications" of volumeFolder to {490, 235}
  update volumeFolder without registering applications
  delay 2
  close installerWindow
end tell
APPLESCRIPT

hdiutil detach "$mounted_device"
mounted_device=""

hdiutil convert "$rw_dmg_path" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$dmg_path"
rm "$rw_dmg_path"

hdiutil verify "$dmg_path"
checksum_value="$(shasum -a 256 "$dmg_path" | awk '{print $1}')"
print "$checksum_value  ${dmg_path:t}" > "$checksum_path"

echo "Public test release created:"
echo "  $dmg_path"
echo "  $checksum_path"
echo "This build is ad-hoc signed and not Apple-notarized. Gatekeeper will require"
echo "the user to approve it in System Settings > Privacy & Security on first launch."
