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
    # bookshop (Livraria Maré)
    "CashRegister_01": "1k", "standing_chalkboard_01": "1k", "wooden_ladder": "1k",
    "Rockingchair_01": "1k", "side_table_01": "1k", "WoodenTable_02": "1k",
    "wooden_stool_01": "1k", "potted_plant_02": "1k", "postcard_set_01": "1k",
    "vintage_suitcase": "1k", "binder_notebook": "1k", "magnifying_glass_01": "1k",
    "vintage_telephone_wall_clock": "1k", "painted_wooden_cabinet": "1k",
    "steel_frame_shelves_03": "1k", "Chandelier_01": "1k",
    # clinic (Clínica Atlântico)
    "mounted_fluorescent_lights": "1k", "wheelchair_01": "1k", "WetFloorSign_01": "1k",
    "korean_fire_extinguisher_01": "1k", "fire_alarm": "1k", "medical_box": "1k", "clipboard": "1k",
    "stationery_supplies": "1k", "modern_arm_chair_01": "1k", "drawer_cabinet": "1k",
    "steel_frame_shelves_01": "1k", "potted_plant_04": "1k", "office_notepads": "1k",
    # the road and the pier (caminho, Cais Velho) and Rui's house
    "lifebuoy": "1k", "lateral_sea_marker": "1k", "ocean_buoy": "1k", "wooden_barrels_01": "1k",
    "wooden_crate_01": "1k", "plastic_crate_01": "1k", "metal_jerrycan": "1k", "rubber_boots": "1k",
    "fishermans_hat": "1k", "Lantern_01": "1k", "coast_rocks_01": "1k",
    "boulder_01": "1k", "modular_street_seating": "1k", "fire_hydrant": "1k",
    "utility_box_01": "1k", "concrete_road_barrier": "1k", "rollershutter_door": "1k",
    "exterior_aircon_unit": "1k", "security_light": "1k", "street_lamp_02": "1k",
    "shrub_02": "1k", "old_tyre": "1k", "wooden_bucket_01": "1k",
    # hall / outside
    "fancy_picture_frame_01": "1k", "street_lamp_01": "1k", "covered_car": "1k",
    "metal_trash_can": "1k", "trashbag": "1k",
}
TEXTURES = {
    "herringbone_parquet": "1k", "plastered_wall_04": "1k", "white_plaster_02": "1k",
    "terrazzo_tiles": "1k", "square_tiled_wall": "1k", "marble_mosaic_tiles": "1k",
    "long_white_tiles": "1k", "marble_01": "1k", "painted_plaster_wall": "1k",
    "stone_pavers": "1k", "asphalt_06": "1k", "kitchen_wood": "1k",
    "dark_wooden_planks": "1k", "dark_wood": "1k", "roof_planks": "1k",
    "old_linoleum_flooring_01": "1k", "painted_concrete": "1k", "grey_tiles": "1k",
    "coast_sand_02": "1k", "damp_sand": "1k", "stone_wall": "1k", "weathered_planks": "1k",
    "cobblestone_floor_04": "1k", "rough_block_wall": "1k", "concrete_wall_003": "1k", "forest_ground_05": "1k",
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
    out = os.path.join(ROOT, "models", aid)
    if "gltf" not in files:
        # some sets only ship as FBX (Godot 4.3 imports it natively)
        g = files["fbx"][res]["fbx"]
        save(os.path.join(out, f"{aid}.fbx"), get(g["url"]))
        for rel, inc in g.get("include", {}).items():
            save(os.path.join(out, rel), get(inc["url"]))
        print("model (fbx)", aid)
        return
    g = files["gltf"][res]["gltf"]
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
