#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

xcodegen generate
destination=$(python3 scripts/pick_iphone_simulator.py)
xcodebuild \
  -project Rummy500.xcodeproj \
  -scheme Rummy500 \
  -destination "$destination" \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
