#!/usr/bin/env python3
"""Pack the icons the phone uses into data/icons.json.

    python3 tools/build_icons.py <tabler package dir>

The icons are Tabler Icons (MIT, https://tabler.io/icons, npm @tabler/icons).
Each SVG is stored as text, drawn white; the game rasterises it at the size
it needs and tints it (scripts/ui/icons.gd), so it stays sharp at any scale.
"""
import json
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

# game name -> (style, tabler name)
ICONS = {
    # app tiles (white on the coloured squircle)
    "app_messages": ("filled", "message-circle"),
    "app_phone": ("filled", "phone"),
    "app_contacts": ("filled", "user"),
    "app_gallery": ("filled", "photo"),
    "app_camera": ("filled", "camera"),
    "app_browser": ("filled", "compass"),
    "app_maps": ("filled", "map-pin"),
    "app_email": ("filled", "mail"),
    "app_notes": ("outline", "notes"),
    "app_files": ("filled", "folder"),
    "app_settings": ("filled", "settings"),
    "app_clock": ("filled", "clock"),
    "app_eco": ("filled", "eye"),
    # interface glyphs
    "back": ("outline", "chevron-left"),
    "forward": ("outline", "chevron-right"),
    "chevron": ("outline", "chevron-right"),
    "search": ("outline", "search"),
    "send": ("outline", "send"),
    "more": ("outline", "dots-vertical"),
    "plus": ("outline", "plus"),
    "close": ("outline", "x"),
    "info": ("outline", "info-circle"),
    "lock": ("filled", "lock"),
    "mic": ("outline", "microphone"),
    "speaker": ("outline", "volume"),
    "keypad": ("outline", "dialpad"),
    "play": ("filled", "player-play"),
    "pause": ("filled", "player-pause"),
    "star": ("filled", "star"),
    "trash": ("outline", "trash"),
    "doc": ("outline", "file-text"),
    "file": ("outline", "file-text"),
    "audio": ("outline", "wave-sine"),
    "wave": ("outline", "wave-sine"),
    "image": ("outline", "photo"),
    "history": ("outline", "history"),
    "bookmark": ("filled", "bookmark"),
    "refresh": ("outline", "refresh"),
    "missed": ("outline", "phone-x"),
    "arrow_in": ("outline", "arrow-down-left"),
    "arrow_out": ("outline", "arrow-up-right"),
    "flip": ("outline", "camera-rotate"),
    "locate": ("outline", "current-location"),
    "zoom_in": ("outline", "zoom-in"),
    "edit": ("outline", "pencil"),
    "tag": ("outline", "tag"),
    "link": ("outline", "link"),
    "wifi": ("outline", "wifi"),
    "phone": ("filled", "phone"),
    "call": ("filled", "phone"),
    "hangup": ("filled", "phone"),      # drawn turned down (scripts/ui/icons.gd)
    "person": ("outline", "user"),
    "contacts": ("outline", "user"),
    "gallery": ("outline", "photo"),
    "camera": ("outline", "camera"),
    "browser": ("outline", "world"),
    "globe": ("outline", "world"),
    "maps": ("outline", "map-pin"),
    "pin": ("filled", "map-pin"),
    "email": ("outline", "mail"),
    "messages": ("outline", "message-circle"),
    "notes": ("outline", "notes"),
    "files": ("outline", "folder"),
    "folder": ("filled", "folder"),
    "settings": ("outline", "settings"),
    "gear": ("outline", "settings"),
    "clock": ("outline", "clock"),
    "battery": ("outline", "battery-2"),
    "torch": ("outline", "bulb"),
}


def main() -> None:
    pkg = sys.argv[1]
    out = {"_license": "Tabler Icons, MIT License, (c) 2020-2024 Pawel Kuna, https://tabler.io/icons"}
    for name, (style, tab) in ICONS.items():
        path = os.path.join(pkg, "icons", style, tab + ".svg")
        svg = open(path, encoding="utf-8").read()
        svg = svg.replace("currentColor", "#ffffff")
        # one line, no class noise
        svg = " ".join(line.strip() for line in svg.splitlines() if line.strip())
        out[name] = svg
    dst = os.path.join(ROOT, "data", "icons.json")
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=0)
    lic = os.path.join(ROOT, "data", "LICENSE-tabler-icons.txt")
    with open(lic, "w", encoding="utf-8") as f:
        f.write(open(os.path.join(pkg, "LICENSE"), encoding="utf-8").read())
    print("%d icons -> %s" % (len(ICONS), dst))


if __name__ == "__main__":
    main()
