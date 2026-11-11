#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

xcodegen generate
destination=$(python3 scripts/pick_iphone_simulator.py)
rm -rf "$root/build/TestResults.xcresult"
set +e
xcodebuild \
  -project Rummy500.xcodeproj \
  -scheme Rummy500 \
  -destination "$destination" \
  -sdk iphonesimulator \
  -resultBundlePath "$root/build/TestResults.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
status=$?
set -e
if [ "$status" -eq 0 ]; then
  python3 scripts/export_table_screenshots.py \
    "$root/build/TestResults.xcresult" \
    "$root/build/table-screenshots"
else
  python3 scripts/export_table_screenshots.py \
    "$root/build/TestResults.xcresult" \
    "$root/build/table-screenshots" || true
  exit "$status"
fi
