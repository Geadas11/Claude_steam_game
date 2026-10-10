#!/usr/bin/env python3
"""Download CC0 materials from ambientCG (https://ambientcg.com) into
assets/3d/textures/<id>/{diff,nor,arm}.jpg — the same layout as the Poly
Haven ones, so WB.mat() and WB.flat() use them the same way.

    python3 tools/fetch_ambientcg.py            # everything in MATERIALS
    python3 tools/fetch_ambientcg.py --force    # download again

arm.jpg packs ambient occlusion (R), roughness (G) and metalness (B).
Everything on ambientCG is CC0; the list is appended to assets/3d/CREDITS.md.
"""
import io
import os
import sys
import time
import urllib.request
import zipfile

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) UNKNOWN-assets/1.0"}

# our id -> ambientCG asset id
MATERIALS = {
    "acg_plaster": "Plaster001",      # clean white interior plaster (walls)
    "acg_paint": "Paint004",          # painted surfaces: relief only
    "acg_brushed_steel": "Metal009",  # brushed steel: lockers, rails, frames
    "acg_linen": "Fabric045",         # woven fabric: sheets, curtains, sofas
}


def get(url: str) -> bytes:
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except OSError:
            if attempt == 4:
                raise
            time.sleep(2 ** (attempt + 1))
    return b""


def fetch(our_id: str, acg_id: str) -> None:
    z = zipfile.ZipFile(io.BytesIO(get(f"https://ambientcg.com/get?file={acg_id}_2K-JPG.zip")))
    files = {n.rsplit("_", 1)[-1].split(".")[0]: n for n in z.namelist() if n.endswith(".jpg")}
    out = os.path.join(ROOT, "textures", our_id)
    os.makedirs(out, exist_ok=True)

    def img(key: str, mode: str, fill: int):
        if key in files:
            return Image.open(io.BytesIO(z.read(files[key]))).convert(mode)
        return None

    color = img("Color", "RGB", 0)
    color.save(os.path.join(out, "diff.jpg"), quality=92)
    img("NormalGL", "RGB", 0).save(os.path.join(out, "nor.jpg"), quality=95)
    size = color.size
    rough = img("Roughness", "L", 0) or Image.new("L", size, 160)
    ao = img("AmbientOcclusion", "L", 0) or Image.new("L", size, 255)
    metal = img("Metalness", "L", 0) or Image.new("L", size, 0)
    Image.merge("RGB", (ao.resize(size), rough.resize(size), metal.resize(size))).save(os.path.join(out, "arm.jpg"), quality=92)
    print("material", our_id, "<-", acg_id)


def credits() -> None:
    path = os.path.join(ROOT, "CREDITS.md")
    text = open(path).read() if os.path.exists(path) else "# Recursos 3D\n"
    marker = "\n## ambientCG\n"
    text = text.split(marker)[0].rstrip("\n") + "\n" + marker + "\nLicença CC0 (domínio público), https://ambientcg.com\n\n"
    for our_id, acg_id in sorted(MATERIALS.items()):
        text += f"- Material `{our_id}` — {acg_id}, https://ambientcg.com/view?id={acg_id}\n"
    open(path, "w").write(text)


def main() -> None:
    force = "--force" in sys.argv
    for our_id, acg_id in MATERIALS.items():
        if force or not os.path.isdir(os.path.join(ROOT, "textures", our_id)):
            fetch(our_id, acg_id)
    credits()


if __name__ == "__main__":
    main()
