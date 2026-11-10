#!/bin/sh
set -eu
root=$(unset CDPATH; cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

xcodebuild -version
xcodegen generate

archive_path=${1:-${TMPDIR:-/tmp}/Rummy500-unsigned.xcarchive}
derived_path=${TMPDIR:-/tmp}/Rummy500-unsigned-derived
rm -rf "$archive_path" "$derived_path"

xcodebuild archive \
  -project Rummy500.xcodeproj \
  -scheme Rummy500 \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$archive_path" \
  -derivedDataPath "$derived_path" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual

app="$archive_path/Products/Applications/Rummy500.app"
test -d "$app"
compliance=$(plutil -extract ITSAppUsesNonExemptEncryption raw -o - "$app/Info.plist")
version=$(plutil -extract CFBundleShortVersionString raw -o - "$app/Info.plist")
test "$compliance" = "false"
test "$version" = "0.1.0"
echo "Unsigned Release archive: $archive_path"
echo "CFBundleShortVersionString=$version"
echo "ITSAppUsesNonExemptEncryption=$compliance"
