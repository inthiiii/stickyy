#!/bin/zsh

set -euo pipefail

root_dir="${0:A:h:h}"

cd "$root_dir"

xcodebuild test \
  -project Stickyy.xcodeproj \
  -scheme Stickyy \
  -destination 'platform=macOS' \
  -derivedDataPath .build/IsolatedTests \
  PRODUCT_BUNDLE_IDENTIFIER=com.inthiiii.Stickyy.DevelopmentTests \
  "$@"
