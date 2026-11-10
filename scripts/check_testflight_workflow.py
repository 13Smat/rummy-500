#!/usr/bin/env python3

import sys
from pathlib import Path

import yaml

root = Path(__file__).resolve().parents[1]
errors = []


def need(condition, message):
    if not condition:
        errors.append(message)


def triggers(doc):
    if True in doc:
        return doc[True]
    return doc.get("on", {})


def step_runs(doc):
    runs = []
    for job in doc.get("jobs", {}).values():
        for step in job.get("steps", []):
            if "run" in step:
                runs.append((step, step["run"]))
    return runs


testflight = yaml.safe_load((root / ".github/workflows/testflight.yml").read_text())
on = triggers(testflight)
need("workflow_dispatch" in on, "workflow_dispatch")
need("pull_request" not in on, "TestFlight does not run on pull requests")
push = on.get("push", {})
need("branches" not in push, "TestFlight does not run on branch pushes")
need(push.get("tags") == ["tf-*"], "tag filter is tf-*")
dry = on.get("workflow_dispatch", {}).get("inputs", {}).get("dry_run", {})
need(dry.get("type") == "boolean", "dry_run is a boolean input")
need(dry.get("default") is False, "dry_run defaults off")

need(testflight.get("permissions") == {"contents": "read"}, "contents read only")
jobs = testflight.get("jobs", {})
need(len(jobs) == 1, "one TestFlight job")
job = next(iter(jobs.values()))
need(job.get("runs-on") == "macos-26", "macos-26 runner")
need(job.get("env", {}).get("DEVELOPER_DIR") == "/Applications/Xcode_26.6.app", "Xcode 26.6")
runs = step_runs(testflight)
joined = "\n".join(command for _, command in runs)
for command in (
    "./scripts/install-xcodegen.sh",
    "python3 scripts/check_asc_secrets.py",
    "python3 scripts/write_asc_key.py",
    "./scripts/archive-unsigned-release.sh",
    "./scripts/archive-and-upload.sh",
):
    need(command in joined, command)
need(
    any(step.get("if") == "always()" and "AuthKey_ASC.p8" in step.get("run", "") for step, _ in runs),
    "always delete the key file",
)
need("${{ secrets." not in joined, "run scripts do not interpolate secrets")
secret_names = ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_P8", "APPLE_TEAM_ID")
seen = {name: 0 for name in secret_names}
for step, _command in runs:
    for key, value in step.get("env", {}).items():
        if key not in seen:
            continue
        seen[key] += 1
        need(value == f"${{{{ secrets.{key} }}}}", f"{key} comes from secrets")
for name, count in seen.items():
    need(count > 0, f"{name} is passed to a step")

ci = yaml.safe_load((root / ".github/workflows/ci.yml").read_text())
ci_on = triggers(ci)
need("pull_request" in ci_on, "CI still runs on pull requests")
ci_jobs = ci.get("jobs", {})
need("engine" in ci_jobs and "app" in ci_jobs, "CI keeps the engine and app jobs")
need(ci_jobs["engine"].get("runs-on") == "ubuntu-24.04", "engine runner")
need(ci_jobs["app"].get("runs-on") == "macos-26", "app runner")
ci_runs = "\n".join(command for _, command in step_runs(ci))
for command in (
    "./scripts/check.sh",
    "./scripts/ios-ci.sh",
    "./scripts/archive-unsigned-release.sh",
    "actions/upload-artifact@v4",
):
    need(command in ci_runs or command in (root / ".github/workflows/ci.yml").read_text(), command)

upload = (root / "scripts/archive-and-upload.sh").read_text()
unsigned = (root / "scripts/archive-unsigned-release.sh").read_text()
for needle in (
    "-allowProvisioningUpdates",
    "-authenticationKeyPath",
    "-authenticationKeyID",
    "-authenticationKeyIssuerID",
    "app-store-connect",
    "CURRENT_PROJECT_VERSION",
    "-exportArchive",
    "CODE_SIGNING_ALLOWED=NO",
):
    need(needle in upload, f"upload script has {needle}")
need("fastlane" not in upload.lower(), "upload does not call fastlane")


def logical_lines(text):
    lines = []
    buffer = ""
    for raw in text.splitlines():
        piece = raw.strip()
        if piece.startswith("#"):
            continue
        buffer = f"{buffer} {piece}".strip() if buffer else piece
        if buffer.endswith("\\"):
            buffer = buffer[:-1].rstrip()
            continue
        if buffer:
            lines.append(buffer)
        buffer = ""
    if buffer:
        lines.append(buffer)
    return lines


def manual_signing_overrides(command):
    found = []
    for name in ("CODE_SIGN_IDENTITY", "PROVISIONING_PROFILE"):
        if any(name in token for token in command.split()):
            found.append(name)
    return found


bad_identity = (
    'xcodebuild archive CODE_SIGN_STYLE=Automatic '
    'CODE_SIGN_IDENTITY="Apple Distribution" DEVELOPMENT_TEAM=ABCDEFGHIJ'
)
bad_profile = "xcodebuild archive PROVISIONING_PROFILE_SPECIFIER=AppStore"
good_archive = (
    "xcodebuild archive CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=ABCDEFGHIJ "
    "-allowProvisioningUpdates"
)
need(
    manual_signing_overrides(bad_identity) == ["CODE_SIGN_IDENTITY"],
    "detector sees a manual signing identity",
)
need(
    manual_signing_overrides(bad_profile) == ["PROVISIONING_PROFILE"],
    "detector sees a provisioning profile",
)
need(manual_signing_overrides(good_archive) == [], "detector allows automatic signing")

development_profile_settings = (
    "DEVELOPMENT_TEAM",
    "-allowProvisioningUpdates",
    "CODE_SIGN_STYLE=Automatic",
    "CODE_SIGNING_ALLOWED=YES",
    "CODE_SIGNING_REQUIRED=YES",
    "-authenticationKeyPath",
    "-authenticationKeyID",
    "-authenticationKeyIssuerID",
)


def development_profile_request(command):
    found = [name for name in development_profile_settings if name in command]
    if "CODE_SIGNING_ALLOWED=NO" not in command.split():
        found.append("missing CODE_SIGNING_ALLOWED=NO")
    return found


needs_device = (
    "xcodebuild archive CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=ABCDEFGHIJ "
    "CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES -allowProvisioningUpdates "
    "-authenticationKeyPath /tmp/AuthKey.p8"
)
unsigned_archive = (
    "xcodebuild archive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO "
    "CURRENT_PROJECT_VERSION=2"
)
need(
    development_profile_request(needs_device) != [],
    "detector sees a development profile request",
)
need(
    development_profile_request(unsigned_archive) == [],
    "detector allows an unsigned archive",
)

xcode_commands = [
    line for line in logical_lines(upload) if line.startswith("xcodebuild ")
]
archive_commands = [
    line for line in xcode_commands if line.startswith("xcodebuild archive ")
]
need(len(archive_commands) == 1, "one archive command")
archive_command = archive_commands[0] if archive_commands else ""
for name in manual_signing_overrides(archive_command):
    need(False, f"archive command does not pass {name}")
profile_request = development_profile_request(archive_command)
need(
    not profile_request,
    "archive command does not need a development profile: " + ", ".join(profile_request),
)
for name in (
    "CODE_SIGNING_ALLOWED=NO",
    "CODE_SIGNING_REQUIRED=NO",
    "CURRENT_PROJECT_VERSION=",
):
    need(name in archive_command, f"archive command has {name}")

export_commands = [
    line for line in xcode_commands if line.startswith("xcodebuild -exportArchive ")
]
need(len(export_commands) == 1, "one export command")
export_command = export_commands[0] if export_commands else ""
for name in manual_signing_overrides(export_command):
    need(False, f"export command does not pass {name}")
for name in (
    "-allowProvisioningUpdates",
    "-authenticationKeyPath",
    "-authenticationKeyID",
    "-authenticationKeyIssuerID",
):
    need(name in export_command, f"export command has {name}")
need("signingCertificate" not in upload, "export plist does not pin a certificate")
need("provisioningProfiles" not in upload, "export plist does not pin a profile")
need("<key>signingStyle</key>" in upload, "export signing style key")
need("<string>automatic</string>" in upload, "export signing style automatic")
need("<key>destination</key>" in upload, "export destination key")
need("<string>upload</string>" in upload, "export destination upload")
need("<key>teamID</key>" in upload, "export team id")
need("<string>app-store-connect</string>" in upload, "export method app-store-connect")

for needle in (
    "CODE_SIGNING_ALLOWED=NO",
    "-configuration Release",
    "ITSAppUsesNonExemptEncryption",
    'test "$version" = "0.1.0"',
):
    need(needle in unsigned, f"unsigned script has {needle}")

if errors:
    print("testflight workflow check failed: " + ", ".join(errors))
    sys.exit(1)
print("testflight workflow check passed")
