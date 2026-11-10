#!/usr/bin/env python3

import os
import re
import subprocess
import sys

NAMES = ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_P8", "APPLE_TEAM_ID")
KEY_OR_TEAM = re.compile(r"[A-Z0-9]{10}\Z")
ISSUER = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\Z"
)
SENTINEL = "ZZ-SECRET-VALUE-ZZ"


def classify(env):
    missing = [name for name in NAMES if not env.get(name, "").strip()]
    if missing:
        return "missing", missing
    bad = []
    if KEY_OR_TEAM.fullmatch(env["ASC_KEY_ID"].strip()) is None:
        bad.append("ASC_KEY_ID")
    if ISSUER.fullmatch(env["ASC_ISSUER_ID"].strip()) is None:
        bad.append("ASC_ISSUER_ID")
    if KEY_OR_TEAM.fullmatch(env["APPLE_TEAM_ID"].strip()) is None:
        bad.append("APPLE_TEAM_ID")
    key = env["ASC_KEY_P8"]
    if "-----BEGIN" not in key or "PRIVATE KEY-----" not in key or "-----END" not in key:
        bad.append("ASC_KEY_P8")
    if bad:
        return "shape", bad
    return "ok", []


def render(kind, names):
    if kind == "ok":
        return "App Store Connect secrets are present.\n"
    if kind == "missing":
        listed = ", ".join(names)
        return (
            f"Missing GitHub Actions secrets: {listed}\n"
            "Add them in the repository settings, then run this workflow again.\n"
        )
    listed = ", ".join(names)
    return (
        f"These secrets are set, but the shape is wrong: {listed}\n"
        "ASC_KEY_ID and APPLE_TEAM_ID are 10 letters or digits. "
        "ASC_ISSUER_ID is a UUID. "
        "ASC_KEY_P8 is the full key file, including the BEGIN and END lines.\n"
    )


def main():
    kind, names = classify(os.environ)
    sys.stdout.write(render(kind, names))
    return 0 if kind == "ok" else 1


def self_test():
    good_key = "-----BEGIN PRIVATE KEY-----\nnot-a-real-key\n-----END PRIVATE KEY-----\n"
    good = {
        "ASC_KEY_ID": "ABCDE12345",
        "ASC_ISSUER_ID": "00000000-0000-0000-0000-000000000000",
        "ASC_KEY_P8": good_key,
        "APPLE_TEAM_ID": "TEAMID1234",
    }
    cases = [
        ({}, 1, NAMES, ()),
        ({**good, "APPLE_TEAM_ID": ""}, 1, ("APPLE_TEAM_ID",), ()),
        (
            {**good, "APPLE_TEAM_ID": SENTINEL, "ASC_KEY_P8": f"{SENTINEL}\n"},
            1,
            ("ASC_KEY_P8", "APPLE_TEAM_ID"),
            (SENTINEL,),
        ),
        (good, 0, (), (good_key, "ABCDE12345", "TEAMID1234")),
    ]
    failures = []
    for env, expect, needles, forbidden in cases:
        proc = subprocess.run(
            [sys.executable, __file__],
            env={"PATH": os.environ.get("PATH", ""), **env},
            text=True,
            capture_output=True,
            check=False,
        )
        output = proc.stdout + proc.stderr
        if proc.returncode != expect:
            failures.append(f"exit {proc.returncode}, expected {expect}")
        for needle in needles:
            if needle not in output:
                failures.append(f"output did not name {needle}")
        for secret in forbidden:
            if secret and secret in output:
                failures.append("output included a secret value")
    if failures:
        print("asc secret check self-test failed: " + "; ".join(failures))
        return 1
    print("asc secret check self-test passed")
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv[1:]:
        sys.exit(self_test())
    sys.exit(main())
