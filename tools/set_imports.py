#!/usr/bin/env python3
"""Give every 3D texture the right import settings (run after Godot creates
the .import files, then import again):
  - VRAM compressed (S3TC/BPTC) with mipmaps, normal maps flagged;
  - tiling textures at full resolution (2K), ARM maps 1K, model textures 1K.
Safe to run again: it rewrites the settings it owns every time.
"""
import glob
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")

n = 0
for f in glob.glob(os.path.join(ROOT, "**", "*.import"), recursive=True):
    if not re.search(r"\.(jpg|png)\.import$", f):
        continue
    s0 = open(f).read()
    s = s0.replace("compress/mode=0", "compress/mode=2").replace("mipmaps/generate=false", "mipmaps/generate=true")
    name = os.path.basename(f)
    if "nor" in name:
        s = s.replace("compress/normal_map=0", "compress/normal_map=1")
    is_model = os.sep + "models" + os.sep in f
    limit = 1024 if (is_model or "arm" in name) else 0
    s = re.sub(r"process/size_limit=\d+", "process/size_limit=%d" % limit, s)
    if s != s0:
        open(f, "w").write(s)
        n += 1
print("updated", n, "import files")
