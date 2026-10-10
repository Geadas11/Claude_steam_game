#!/usr/bin/env python3
"""Give every 3D texture the right import settings (run after Godot creates
the .import files, then import again):
  - VRAM compressed (S3TC/BPTC) with mipmaps, normal maps flagged;
  - model textures limited to 512 px, tiling textures to 1k (ARM maps 512).
Only touches files still on the default (compress/mode=0).
"""
import glob
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")
FULL_RES_MODELS = {"sofa_03"}  # props seen very close keep 1k

n = 0
for f in glob.glob(os.path.join(ROOT, "**", "*.import"), recursive=True):
    if not re.search(r"\.(jpg|png)\.import$", f):
        continue
    s = open(f).read()
    if "compress/mode=0" not in s:
        continue
    s = s.replace("compress/mode=0", "compress/mode=2").replace("mipmaps/generate=false", "mipmaps/generate=true")
    name = os.path.basename(f)
    if "nor" in name:
        s = s.replace("compress/normal_map=0", "compress/normal_map=1")
    is_model = os.sep + "models" + os.sep in f
    model = f.split(os.sep + "models" + os.sep)[-1].split(os.sep)[0] if is_model else ""
    if (is_model and model not in FULL_RES_MODELS) or "arm" in name:
        s = re.sub(r"process/size_limit=\d+", "process/size_limit=512", s)
    open(f, "w").write(s)
    n += 1
print("updated", n, "import files")
