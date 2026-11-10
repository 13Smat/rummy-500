#!/bin/bash
set -euo pipefail
curl -fsSL -o /tmp/xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip
unzip -q /tmp/xcodegen.zip -d /tmp/xcodegen-dist
sudo /tmp/xcodegen-dist/xcodegen/install.sh /usr/local
xcodegen --version
