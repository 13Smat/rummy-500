#!/usr/bin/env python3
"""Print an xcodebuild destination for an available iPhone simulator."""

import json
import subprocess
import sys

raw = subprocess.check_output(
    ["xcrun", "simctl", "list", "devices", "available", "-j"],
    text=True,
)
devices_by_runtime = json.loads(raw).get("devices", {})
found = []
for runtime, devices in devices_by_runtime.items():
    if "iOS" not in runtime:
        continue
    for device in devices:
        name = device.get("name", "")
        if device.get("isAvailable") and name.startswith("iPhone"):
            found.append((runtime, device["udid"], name))

if not found:
    sys.exit("No available iPhone simulator")

found.sort(key=lambda item: (item[0], item[2]))
runtime, udid, name = found[-1]
print(f"platform=iOS Simulator,id={udid}", end="")
print(f"Using {name} on {runtime}", file=sys.stderr)
