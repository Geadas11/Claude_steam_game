#!/usr/bin/env python3
"""Export the game as an executable plus packs that each stay under 2 GB.

    python3 tools/export_split.py "Windows Desktop" builds/windows/UNKNOWN.exe

Godot 4.3 reads files past the 2 GB mark of a .pck wrongly, so a single pack
with the 4K textures and 2K models (well over 3 GB) breaks the game: even
project.binary comes back corrupted. This writes:
  UNKNOWN.exe + UNKNOWN.pck     everything but assets/3d
  UNKNOWN_3d_1.pck, _2.pck ...  the 3D assets, each under LIMIT
Packs (scripts/core/packs.gd) loads every *_3d_*.pck next to the
executable before anything needs it.

The asset packs are exported with temporary presets appended to
export_presets.cfg (restored afterwards).
"""
import glob
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
LIMIT = 1_700_000_000


def imported_size(import_file: str) -> int:
    total = 0
    for line in open(import_file, encoding="utf-8", errors="ignore"):
        m = re.match(r'^(?:path(?:\.\w+)?|dest_files)=(.*)$', line.strip())
        if not m:
            continue
        for p in re.findall(r'"res://(\.godot/imported/[^"]+)"', m.group(1)):
            f = os.path.join(ROOT, p)
            if os.path.exists(f):
                total += os.path.getsize(f)
    return total


def main() -> None:
    preset, out = sys.argv[1], sys.argv[2]
    out_dir = os.path.dirname(os.path.join(ROOT, out))
    cfg_path = os.path.join(ROOT, "export_presets.cfg")
    original = open(cfg_path, encoding="utf-8").read()
    # the preset's own excludes (unused assets) apply to the parts too
    m = re.search(r'name="%s".*?exclude_filter="([^"]*)"' % re.escape(preset), original, re.S)
    excludes = m.group(1) if m else ""
    platform = re.search(r'name="%s"\s*\nplatform="([^"]*)"' % re.escape(preset), original).group(1)
    skip = [e.strip() for e in excludes.split(",") if e.strip()]

    def skipped(rel: str) -> bool:
        return any(re.fullmatch(s.replace(".", r"\.").replace("*", ".*"), rel) for s in skip)

    # the 3D sources and how big their imported versions are
    files = []
    for imp in glob.glob(os.path.join(ROOT, "assets/3d/**/*.import"), recursive=True):
        src = imp[:-len(".import")]
        rel = os.path.relpath(src, ROOT).replace(os.sep, "/")
        if skipped(rel):
            continue
        files.append((rel, imported_size(imp)))
    # keep a model's files together: sort by folder, then fill parts in order
    files.sort()
    parts, size = [[]], 0
    for rel, n in files:
        if size + n > LIMIT and parts[-1]:
            parts.append([])
            size = 0
        parts[-1].append(rel)
        size += n
    print("3D parts:", [len(p) for p in parts])

    try:
        # main: no assets/3d
        cfg = re.sub(r'(name="%s".*?exclude_filter=")' % re.escape(preset),
                     lambda mm: mm.group(1) + "assets/3d/*, ", original, count=1, flags=re.S)
        n = len(re.findall(r'^\[preset\.\d+\]$', cfg, re.M))
        for i, part in enumerate(parts):
            k = n + i
            lst = ", ".join('"res://%s"' % f for f in part)
            cfg += f'''
[preset.{k}]

name="_3d_{i + 1}"
platform="{platform}"
runnable=false
dedicated_server=false
custom_features=""
export_filter="resources"
export_files=PackedStringArray({lst})
include_filter=""
exclude_filter=""
export_path=""
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.{k}.options]
'''
        open(cfg_path, "w", encoding="utf-8").write(cfg)
        os.makedirs(out_dir, exist_ok=True)
        subprocess.run(["godot", "--headless", "--path", ROOT, "--export-release", preset, out], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        base = os.path.splitext(os.path.basename(out))[0]
        for i in range(len(parts)):
            dest = os.path.join(out_dir, f"{base}_3d_{i + 1}.pck")
            subprocess.run(["godot", "--headless", "--path", ROOT, "--export-pack", f"_3d_{i + 1}", dest],
                           check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    finally:
        open(cfg_path, "w", encoding="utf-8").write(original)
    for f in sorted(os.listdir(out_dir)):
        print(f, os.path.getsize(os.path.join(out_dir, f)))


if __name__ == "__main__":
    main()
