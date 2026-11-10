#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  if [ -f /etc/debian_version ]; then
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-yaml
  else
    python3 -m pip install --user pyyaml
  fi
fi

python3 scripts/check_project_yml.py
python3 scripts/check_docs.py
python3 scripts/check_app_icon.py
python3 scripts/check_asc_secrets.py --self-test
python3 scripts/write_asc_key.py --self-test
python3 scripts/check_testflight_workflow.py

if grep -R -E -n 'import (UIKit|SwiftUI|Foundation|Darwin|AppKit|CoreGraphics|Combine)' Packages/RummyEngine/Sources; then
  echo "Engine sources import a framework they must not use." >&2
  exit 1
fi

if grep -R -E -n 'URLSession|NWPathMonitor|ATTrackingManager' App Packages/RummyEngine; then
  echo "The demo contains a network or tracking call." >&2
  exit 1
fi

grep -q 'Rummy 500' App/Rummy500/LaunchScreen.storyboard
grep -q 'Rummy 500' App/Rummy500/ContentView.swift
grep -q 'You against the computer' App/Rummy500/ContentView.swift

swift test --package-path Packages/RummyEngine
