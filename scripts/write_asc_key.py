#!/usr/bin/env python3

import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

KEY_NAME = "AuthKey_ASC.p8"
SENTINEL = "ZZ-KEY-BODY-ZZ"


def write_key(pem, dest):
    text = pem if pem.endswith("\n") else pem + "\n"
    dest.write_text(text)
    dest.chmod(0o600)
    mode = dest.stat().st_mode & 0o777
    if mode != 0o600:
        raise SystemExit("The App Store Connect key file must be mode 600.")
    return dest


def main():
    pem = os.environ.get("ASC_KEY_P8", "")
    if "PRIVATE KEY" not in pem:
        print("ASC_KEY_P8 is missing or is not a key file.", file=sys.stderr)
        return 1
    root = Path(os.environ["RUNNER_TEMP"])
    dest = write_key(pem, root / KEY_NAME)
    github_env = os.environ.get("GITHUB_ENV")
    if github_env:
        with open(github_env, "a", encoding="utf-8") as handle:
            handle.write(f"ASC_KEY_PATH={dest}\n")
    print("Wrote the App Store Connect key.")
    return 0


def self_test():
    pem = f"-----BEGIN PRIVATE KEY-----\n{SENTINEL}\n-----END PRIVATE KEY-----\n"
    with tempfile.TemporaryDirectory() as tmp:
        env_file = Path(tmp) / "github.env"
        proc = subprocess.run(
            [sys.executable, __file__],
            env={
                "PATH": os.environ.get("PATH", ""),
                "ASC_KEY_P8": pem,
                "RUNNER_TEMP": tmp,
                "GITHUB_ENV": str(env_file),
            },
            text=True,
            capture_output=True,
            check=False,
        )
        output = proc.stdout + proc.stderr
        dest = Path(tmp) / KEY_NAME
        problems = []
        if proc.returncode != 0:
            problems.append(f"exit {proc.returncode}")
        if SENTINEL in output or "BEGIN PRIVATE KEY" in output:
            problems.append("output included the key")
        if not dest.is_file():
            problems.append("key file was not written")
        else:
            mode = dest.stat().st_mode & 0o777
            if mode != 0o600:
                problems.append(f"mode is {oct(mode)}")
            if dest.read_text() != pem:
                problems.append("key text changed")
            if stat.S_IMODE(dest.stat().st_mode) != 0o600:
                problems.append("mode bits are not 600")
        recorded = env_file.read_text() if env_file.is_file() else ""
        if f"ASC_KEY_PATH={dest}\n" not in recorded:
            problems.append("GITHUB_ENV is missing ASC_KEY_PATH")
        if problems:
            print("write asc key self-test failed: " + "; ".join(problems))
            return 1
    print("write asc key self-test passed")
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv[1:]:
        sys.exit(self_test())
    sys.exit(main())
