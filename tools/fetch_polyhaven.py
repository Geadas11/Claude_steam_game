#!/usr/bin/env python3
"""Download CC0 models and textures from Poly Haven into assets/3d/.

    python3 tools/fetch_polyhaven.py              # everything in ASSETS below
    python3 tools/fetch_polyhaven.py sofa_03      # just these ids

Models land in assets/3d/models/<id>/ (glTF + bin + jpg textures) and
textures in assets/3d/textures/<id>/{diff,nor,arm}.jpg. Everything on Poly
Haven is CC0; the list is also written to assets/3d/CREDITS.md.
"""
import json
import os
import sys
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AindaEstasAcordado-assets/1.0"}

# id -> resolution
MODELS = {
    # living room
    "sofa_03": "1k", "ArmChair_01": "1k", "modern_coffee_table_01": "1k",
    "modern_wooden_cabinet": "1k", "wooden_bookshelf_worn": "1k",
    "book_encyclopedia_set_01": "1k",
    "lightbulb_01": "1k", "potted_plant_01": "1k", "throw_pillows_01": "1k",
    "standing_picture_frame_01": "1k", "metal_office_desk": "1k",
    "dining_chair_02": "1k", "desk_lamp_arm_01": "1k", "wall_clock": "1k",
    # kitchen
    "electric_stove": "1k", "vintage_microwave": "1k", "round_wooden_table_01": "1k",
    "wine_bottles_01": "1k", "jug_01": "1k", "wooden_cutting_board": "1k",
    # bedroom
    "old_bed_frame": "1k", "painted_wooden_nightstand": "1k", "alarm_clock_01": "1k",
    "vintage_cabinet_01": "1k", "cardboard_box_01": "1k",
    # hall / outside
    "fancy_picture_frame_01": "1k", "street_lamp_01": "1k", "covered_car": "1k",
    "metal_trash_can": "1k", "trashbag": "1k",
}
TEXTURES = {
    "herringbone_parquet": "1k", "plastered_wall_04": "1k", "white_plaster_02": "1k",
    "terrazzo_tiles": "1k", "square_tiled_wall": "1k", "marble_mosaic_tiles": "1k",
    "long_white_tiles": "1k", "marble_01": "1k", "painted_plaster_wall": "1k",
    "stone_pavers": "1k", "asphalt_06": "1k", "kitchen_wood": "1k",
}


def get(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def save(path: str, data: bytes) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


def fetch_model(aid: str, res: str) -> None:
    files = json.loads(get(f"https://api.polyhaven.com/files/{aid}"))
    if "gltf" not in files:
        print("skip (no glTF)", aid)
        return
    g = files["gltf"][res]["gltf"]
    out = os.path.join(ROOT, "models", aid)
    save(os.path.join(out, f"{aid}.gltf"), get(g["url"]))
    for rel, inc in g["include"].items():
        save(os.path.join(out, rel), get(inc["url"]))
    print("model", aid)


def fetch_texture(aid: str, res: str) -> None:
    files = json.loads(get(f"https://api.polyhaven.com/files/{aid}"))
    out = os.path.join(ROOT, "textures", aid)
    for key, name in (("Diffuse", "diff"), ("nor_gl", "nor"), ("arm", "arm")):
        if key in files:
            save(os.path.join(out, f"{name}.jpg"), get(files[key][res]["jpg"]["url"]))
    print("texture", aid)


def credits() -> None:
    lines = ["# Recursos 3D", "", "Todos do [Poly Haven](https://polyhaven.com), licença CC0 (domínio público).", ""]
    for aid in sorted(MODELS):
        lines.append(f"- Modelo `{aid}` — https://polyhaven.com/a/{aid}")
    for aid in sorted(TEXTURES):
        lines.append(f"- Textura `{aid}` — https://polyhaven.com/a/{aid}")
    save(os.path.join(ROOT, "CREDITS.md"), ("\n".join(lines) + "\n").encode())


def main() -> None:
    only = set(sys.argv[1:])
    for aid, res in MODELS.items():
        if (not only or aid in only) and not os.path.isdir(os.path.join(ROOT, "models", aid)):
            fetch_model(aid, res)
    for aid, res in TEXTURES.items():
        if (not only or aid in only) and not os.path.isdir(os.path.join(ROOT, "textures", aid)):
            fetch_texture(aid, res)
    credits()


if __name__ == "__main__":
    main()
