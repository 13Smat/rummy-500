#!/usr/bin/env python3
"""Check project.yml has the demo's project decisions."""

from pathlib import Path
import sys

import yaml

root = Path(__file__).resolve().parents[1]
spec = yaml.safe_load((root / "project.yml").read_text())
errors = []


def need(condition, message):
    if not condition:
        errors.append(message)


app = spec["targets"]["Rummy500"]
tests = spec["targets"]["Rummy500Tests"]
base = spec["settings"]["base"]
app_base = app["settings"]["base"]

need(spec["name"] == "Rummy500", "project name")
need(spec["options"]["deploymentTarget"]["iOS"] == "18.0", "iOS deployment target")
need(spec["packages"]["RummyEngine"]["path"] == "Packages/RummyEngine", "engine package path")
need(app_base["PRODUCT_BUNDLE_IDENTIFIER"] == "com.13smat.rummy500", "bundle id")
need(str(app_base["TARGETED_DEVICE_FAMILY"]) == "1", "iPhone device family")
need(app_base["INFOPLIST_KEY_UILaunchStoryboardName"] == "LaunchScreen", "launch storyboard")
need(base["CODE_SIGNING_ALLOWED"] == "NO", "signing stays off")
need(app_base["CODE_SIGNING_ALLOWED"] == "NO", "app target signing stays off")
need(app_base["CODE_SIGN_IDENTITY"] == "-", "app target has no signing identity")
need(str(tests["settings"]["base"]["TARGETED_DEVICE_FAMILY"]) == "1", "test device family")
need("DEVELOPMENT_TEAM" not in base, "no development team")
need("DEVELOPMENT_TEAM" not in app_base, "no development team on the app")
need(app["dependencies"] == [{"package": "RummyEngine"}], "app depends on the engine")
need(tests["settings"]["base"]["TEST_HOST"].endswith("Rummy500.app/Rummy500"), "test host")
need("Rummy500Tests" in app["scheme"]["testTargets"], "scheme runs the app tests")

text = (root / "project.yml").read_text()
for banned in ("PROVISIONING_PROFILE", "BEGIN CERTIFICATE", "PRIVATE KEY"):
    need(banned not in text, f"project.yml contains {banned}")

if errors:
    print("project.yml check failed:", ", ".join(errors))
    sys.exit(1)
print("project.yml check passed")
