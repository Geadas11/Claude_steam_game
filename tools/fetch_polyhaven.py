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
    # visual pass 2: walls, small things that make rooms lived in, the square
    "hanging_picture_frame_01": "1k", "hanging_picture_frame_02": "1k", "hanging_picture_frame_03": "1k",
    "fancy_picture_frame_02": "1k", "standing_picture_frame_02": "1k", "mantel_clock_01": "1k",
    "Television_01": "1k", "television_02": "1k",
    "ceiling_fan": "1k", "security_camera_01": "1k", "security_camera_02": "1k",
    "modern_ceiling_lamp_01": "1k", "industrial_wall_lamp": "1k", "ClassicNightstand_01": "1k",
    "Shelf_01": "1k", "ceramic_vase_01": "1k", "ceramic_vase_03": "1k", "tea_set_01": "1k",
    "pot_enamel_01": "1k", "wicker_basket_01": "1k", "plastic_monobloc_chair_01": "1k",
    "outdoor_table_chair_set_01": "1k", "metal_stool_01": "1k", "Barrel_01": "1k",
    "wooden_crate_02": "1k", "life_jacket": "1k", "bleach_bottle": "1k", "all_purpose_cleaner": "1k",
    "plastic_broom": "1k", "dustpan": "1k", "plunger": "1k", "wooden_ladder_02": "1k",
    "utility_box_02": "1k", "water_manhole_cover": "1k", "food_apple_01": "1k", "lemon": "1k",
    "croissant": "1k", "classic_laptop": "1k", "cassette_player": "1k",
    "vintage_radio_transceiver": "1k", "cigarette_pack": "1k", "round_spectacles": "1k",
    "vintage_electric_kettle": "1k", "Sofa_01": "1k", "mid_century_lounge_chair": "1k", "wooden_display_shelves_01": "1k",
    "planter_box_01": "1k",
    # dressing pass: the small things on every surface
    "brass_pot_01": "1k", "wooden_bowl_01": "1k", "carved_wooden_plate": "1k", "metal_jug": "1k", "ceramic_vase_02": "1k",
    "ceramic_vase_04": "1k", "antique_ceramic_vase_01": "1k", "wicker_basket_02": "1k", "plastic_bottle_gallon": "1k", "multi_cleaner_bottle": "1k",
    "food_kiwi_01": "1k", "food_pears_asian_01": "1k", "bananas": "1k", "long_life_food": "1k", "russian_food_cans_01": "1k",
    "modified_thermos": "1k", "plastic_thermos": "1k", "vintage_lighter": "1k", "pocket_watch": "1k", "digital_wrist_watch": "1k",
    "garden_gloves_01": "1k", "measuring_tape_01": "1k", "screwdriver": "1k", "medical_tape": "1k", "rubber_duck_toy": "1k",
    "football": "1k", "dartboard": "1k", "gamepad": "1k", "Camera_01": "1k", "boombox": "1k",
    "plastic_crate_02": "1k", "metal_toolbox": "1k", "tool_cart": "1k", "worn_metal_rack": "1k", "WoodenChair_01": "1k",
    "GreenChair_01": "1k", "Ottoman_01": "1k", "painted_wooden_chair_01": "1k", "coffee_table_round_01": "1k",
    "small_wooden_table_01": "1k", "ClassicConsole_01": "1k", "painted_wooden_shelves": "1k", "SchoolChair_01": "1k",
    "SchoolDesk_01": "1k", "wooden_stool_02": "1k", "vintage_oil_lamp": "1k", "hanging_industrial_lamp": "1k", "lantern_chandelier_01": "1k",
    "ornate_mirror_01": "1k", "portable_cassette_player": "1k", "cigarette_case": "1k", "vintage_flashlight": "1k", "plastic_container": "1k",
    "painted_wooden_cabinet_02": "1k", "CoffeeTable_01": "1k",
    # hall / outside
    "fancy_picture_frame_01": "1k", "street_lamp_01": "1k", "covered_car": "1k",
    "metal_trash_can": "1k", "trashbag": "1k",
}
TEXTURES = {
    # tiling surfaces, 2K (seen up close in first person)
    "herringbone_parquet": "2k", "plastered_wall_04": "2k", "white_plaster_02": "2k",
    "terrazzo_tiles": "2k", "square_tiled_wall": "2k", "marble_mosaic_tiles": "2k",
    "long_white_tiles": "2k", "marble_01": "2k", "painted_plaster_wall": "2k",
    "stone_pavers": "2k", "asphalt_06": "2k", "kitchen_wood": "2k",
    "dark_wooden_planks": "2k", "dark_wood": "2k", "roof_planks": "2k",
    "old_linoleum_flooring_01": "2k", "painted_concrete": "2k", "grey_tiles": "2k",
    "coast_sand_02": "2k", "damp_sand": "2k", "stone_wall": "2k", "weathered_planks": "2k",
    "cobblestone_floor_04": "2k", "rough_block_wall": "2k", "concrete_wall_003": "2k", "forest_ground_05": "2k",
    # surface detail for painted, metal and fabric things (WB.flat uses their relief)
    "rough_linen": "2k", "metal_plate": "2k", "wood_cabinet_worn_long": "2k",
    "white_plaster_rough_01": "2k", "plywood": "2k", "smooth_concrete_floor": "2k",
    "painted_metal_shutter": "2k", "velour_velvet": "2k", "worn_plaster_wall": "2k",
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
    # keep the sections the other fetch scripts own (## ambientCG, ## BlenderKit)
    path = os.path.join(ROOT, "CREDITS.md")
    rest = ""
    if os.path.exists(path):
        old = open(path).read()
        if "\n## " in old:
            rest = "\n## " + old.split("\n## ", 1)[1]
    save(path, ("\n".join(lines) + "\n" + rest).encode())


def main() -> None:
    force = "--force" in sys.argv
    only = set(a for a in sys.argv[1:] if not a.startswith("--"))
    for aid, res in MODELS.items():
        if (not only or aid in only) and not os.path.isdir(os.path.join(ROOT, "models", aid)):
            fetch_model(aid, res)
    for aid, res in TEXTURES.items():
        if (not only or aid in only) and (force or not os.path.isdir(os.path.join(ROOT, "textures", aid))):
            fetch_texture(aid, res)
    credits()


if __name__ == "__main__":
    main()
