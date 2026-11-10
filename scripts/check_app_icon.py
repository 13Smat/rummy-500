#!/usr/bin/env python3

import json
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
icon_dir = root / "App/Rummy500/Assets.xcassets/AppIcon.appiconset"
icon_path = icon_dir / "AppIcon.png"


def fail(message):
    print(f"app icon check failed: {message}")
    sys.exit(1)


def chunk_names(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        fail("AppIcon.png is not a PNG")
    index = 8
    while index + 8 <= len(data):
        length = struct.unpack(">I", data[index : index + 4])[0]
        name = data[index + 4 : index + 8]
        yield name, data[index + 8 : index + 8 + length]
        index += 12 + length
        if name == b"IEND":
            return
    fail("AppIcon.png ended before IEND")


def main():
    if not icon_path.is_file():
        fail("AppIcon.png is missing")
    data = icon_path.read_bytes()
    header = None
    has_transparency = False
    for name, payload in chunk_names(data):
        if name == b"IHDR":
            header = payload
        if name == b"tRNS":
            has_transparency = True
    if header is None or len(header) < 10:
        fail("AppIcon.png has no image header")
    width, height, _bit, color = struct.unpack(">IIBB", header[:10])
    if (width, height) != (1024, 1024):
        fail(f"AppIcon.png is {width} by {height}, not 1024 by 1024")
    if color in (4, 6) or has_transparency:
        fail("AppIcon.png has transparency")
    catalog = json.loads((icon_dir / "Contents.json").read_text())
    images = catalog.get("images", [])
    if not any(
        image.get("filename") == "AppIcon.png" and image.get("size") == "1024x1024"
        for image in images
    ):
        fail("Contents.json does not list AppIcon.png at 1024x1024")
    print("app icon check passed")


if __name__ == "__main__":
    main()
