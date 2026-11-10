#!/usr/bin/env python3
"""Check the rules sheet still names the open questions."""

from pathlib import Path
import sys

text = (Path(__file__).resolve().parents[1] / "docs" / "RULES.md").read_text()
errors = []
if "## Open questions" not in text:
    errors.append("missing Open questions heading")
for phrase in (
    "Empty stock",
    "cannot be used",
    "low ace",
    "Going out on a discard",
    "Who leads",
    "tie at 500",
    "Cards above",
    "Points left in the hand",
):
    if phrase not in text:
        errors.append(f"missing {phrase}")
if errors:
    print("rules check failed:", ", ".join(errors))
    sys.exit(1)
print("rules check passed")
