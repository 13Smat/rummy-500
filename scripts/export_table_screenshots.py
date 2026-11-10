#!/usr/bin/env python3

import json
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: export_table_screenshots.py RESULT.xcresult OUTPUT_DIR", file=sys.stderr)
        return 2
    result = Path(sys.argv[1])
    output = Path(sys.argv[2])
    if not result.exists():
        print(f"missing result bundle: {result}", file=sys.stderr)
        return 1
    staging = output.parent / "attachment-export"
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir(parents=True)
    output.mkdir(parents=True)
    exported = subprocess.run(
        [
            "xcrun",
            "xcresulttool",
            "export",
            "attachments",
            "--path",
            str(result),
            "--output-path",
            str(staging),
        ],
        check=False,
    )
    if exported.returncode != 0:
        print("xcresulttool could not export attachments", file=sys.stderr)
        return exported.returncode
    manifest_path = staging / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    copied = 0
    for test in manifest:
        for attachment in test.get("attachments", []):
            name = attachment.get("suggestedHumanReadableName") or ""
            if not name.endswith(".png"):
                continue
            if not name.startswith(("fresh-deal", "mid-hand", "long-discard", "play-")):
                continue
            source = staging / attachment["exportedFileName"]
            target = output / name
            shutil.copyfile(source, target)
            copied += 1
    print(f"copied {copied} table screenshots to {output}")
    if copied < 6:
        print(json.dumps(manifest, indent=2), file=sys.stderr)
        print("expected 6 table screenshots", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
