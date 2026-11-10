#!/bin/sh
set -eu
root=$(unset CDPATH; cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

: "${ASC_KEY_PATH:?The App Store Connect key file path is missing.}"
: "${ASC_KEY_ID:?ASC_KEY_ID is missing.}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is missing.}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is missing.}"
: "${GITHUB_RUN_NUMBER:?GITHUB_RUN_NUMBER is missing.}"
: "${RUNNER_TEMP:?RUNNER_TEMP is missing.}"

if [ ! -f "$ASC_KEY_PATH" ]; then
  echo "The App Store Connect key file is missing." >&2
  exit 1
fi
python3 - "$ASC_KEY_PATH" <<'PY'
import sys
import os

mode = os.stat(sys.argv[1]).st_mode & 0o777
if mode != 0o600:
    raise SystemExit("The App Store Connect key file must be mode 600.")
PY
case "$GITHUB_RUN_NUMBER" in
  ''|*[!0-9]*)
    echo "GITHUB_RUN_NUMBER is not a whole number." >&2
    exit 1
    ;;
esac

python3 - <<'PY'
import os
import re
from pathlib import Path

team = os.environ["APPLE_TEAM_ID"].strip()
if re.fullmatch(r"[A-Z0-9]{10}", team) is None:
    raise SystemExit("APPLE_TEAM_ID is not a 10 character Apple team id.")
plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>upload</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>method</key>
	<string>app-store-connect</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>TEAM</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
"""
Path(os.environ["RUNNER_TEMP"], "ExportOptions.plist").write_text(
    plist.replace(">TEAM<", f">{team}<")
)
PY

xcodebuild -version
xcodegen generate
python3 scripts/clear_manual_identity.py Rummy500.xcodeproj/project.pbxproj

archive_path="$RUNNER_TEMP/Rummy500.xcarchive"
rm -rf "$archive_path"

xcodebuild archive \
  -project Rummy500.xcodeproj \
  -scheme Rummy500 \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$archive_path" \
  -derivedDataPath "$RUNNER_TEMP/Rummy500-signed-derived" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  CURRENT_PROJECT_VERSION="$GITHUB_RUN_NUMBER"

app="$archive_path/Products/Applications/Rummy500.app"
test -d "$app"
compliance=$(plutil -extract ITSAppUsesNonExemptEncryption raw -o - "$app/Info.plist")
version=$(plutil -extract CFBundleShortVersionString raw -o - "$app/Info.plist")
build=$(plutil -extract CFBundleVersion raw -o - "$app/Info.plist")
test "$compliance" = "false"
test "$version" = "0.1.0"
test "$build" = "$GITHUB_RUN_NUMBER"
echo "Signed Release archive marketing version $version build $build"
echo "ITSAppUsesNonExemptEncryption=$compliance"

xcodebuild -exportArchive \
  -archivePath "$archive_path" \
  -exportPath "$RUNNER_TEMP/export" \
  -exportOptionsPlist "$RUNNER_TEMP/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo "Uploaded build $build to App Store Connect."
