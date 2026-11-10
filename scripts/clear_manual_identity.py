#!/usr/bin/env python3

import re
import sys
import tempfile
from pathlib import Path

IDENTITY = re.compile(
    r'^[ \t]*"?CODE_SIGN_IDENTITY(?:\[[^\]]+\])?"?[ \t]*=[ \t]*[^;]*;[ \t]*\r?\n?',
    re.MULTILINE,
)


def clear_manual_identity(text):
    return IDENTITY.sub("", text)


def main(argv):
    if argv[:1] == ["--self-test"]:
        return self_test()
    if len(argv) != 1:
        print("Usage: clear_manual_identity.py project.pbxproj", file=sys.stderr)
        return 1
    path = Path(argv[0])
    if not path.is_file():
        print("The generated Xcode project is missing.", file=sys.stderr)
        return 1
    cleared = clear_manual_identity(path.read_text())
    if "CODE_SIGN_IDENTITY" in cleared:
        print("A manual signing identity is still in the generated project.", file=sys.stderr)
        return 1
    path.write_text(cleared)
    print("Removed manual signing identities from the generated project.")
    return 0


def self_test():
    fixture = "\n".join(
        (
            "\t\tbuildSettings = {",
            '\t\t\tCODE_SIGN_IDENTITY = "-";',
            '\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "-";',
            '\t\t\tCODE_SIGN_IDENTITY = "Apple Distribution";',
            "\t\t\tCODE_SIGN_STYLE = Manual;",
            "\t\t\tCODE_SIGNING_ALLOWED = NO;",
            "\t\t\tCODE_SIGNING_REQUIRED = NO;",
            "\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.13smat.rummy500;",
            "\t\t\tINFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;",
            "\t\t};",
            "",
        )
    )
    cleared = clear_manual_identity(fixture)
    problems = []
    if "CODE_SIGN_IDENTITY" in cleared:
        problems.append("identity remains")
    for kept in (
        "CODE_SIGN_STYLE = Manual;",
        "CODE_SIGNING_ALLOWED = NO;",
        "CODE_SIGNING_REQUIRED = NO;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.13smat.rummy500;",
        "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;",
        "buildSettings = {",
    ):
        if kept not in cleared:
            problems.append(f"missing {kept}")
    if clear_manual_identity(cleared) != cleared:
        problems.append("second clear changed the project")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "project.pbxproj"
        path.write_text(fixture)
        proc_code = main([str(path)])
        if proc_code != 0:
            problems.append(f"exit {proc_code}")
        written = path.read_text()
        if written != cleared:
            problems.append("file text differs from clear_manual_identity")
        if "CODE_SIGN_IDENTITY" in written:
            problems.append("written project still has an identity")
    if problems:
        print("clear manual identity self-test failed: " + "; ".join(problems))
        return 1
    print("clear manual identity self-test passed")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
