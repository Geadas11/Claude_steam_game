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
import time
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AindaEstasAcordado-assets/1.0"}

# id -> resolution
MODELS = {
    # living room
    "sofa_03": "2k", "ArmChair_01": "2k", "modern_coffee_table_01": "2k",
    "modern_wooden_cabinet": "2k", "wooden_bookshelf_worn": "2k",
    "book_encyclopedia_set_01": "2k",
    "lightbulb_01": "2k", "potted_plant_01": "2k", "throw_pillows_01": "2k",
    "standing_picture_frame_01": "2k", "metal_office_desk": "2k",
    "dining_chair_02": "2k", "desk_lamp_arm_01": "2k", "wall_clock": "2k",
    # kitchen
    "electric_stove": "2k", "vintage_microwave": "2k", "round_wooden_table_01": "2k",
    "wine_bottles_01": "2k", "jug_01": "2k", "wooden_cutting_board": "2k",
    # bedroom
    "old_bed_frame": "2k", "painted_wooden_nightstand": "2k", "alarm_clock_01": "2k",
    "vintage_cabinet_01": "2k", "cardboard_box_01": "2k",
    # bookshop (Livraria Maré)
    "CashRegister_01": "2k", "standing_chalkboard_01": "2k", "wooden_ladder": "2k",
    "Rockingchair_01": "2k", "side_table_01": "2k", "WoodenTable_02": "2k",
    "wooden_stool_01": "2k", "potted_plant_02": "2k", "postcard_set_01": "2k",
    "vintage_suitcase": "2k", "binder_notebook": "2k", "magnifying_glass_01": "2k",
    "vintage_telephone_wall_clock": "2k", "painted_wooden_cabinet": "2k",
    "steel_frame_shelves_03": "2k", "Chandelier_01": "2k",
    # clinic (Clínica Atlântico)
    "mounted_fluorescent_lights": "2k", "wheelchair_01": "2k", "WetFloorSign_01": "2k",
    "korean_fire_extinguisher_01": "2k", "fire_alarm": "2k", "medical_box": "2k", "clipboard": "2k",
    "stationery_supplies": "2k", "modern_arm_chair_01": "2k", "drawer_cabinet": "2k",
    "steel_frame_shelves_01": "2k", "potted_plant_04": "2k", "office_notepads": "2k",
    # the road and the pier (caminho, Cais Velho) and Rui's house
    "lifebuoy": "2k", "lateral_sea_marker": "2k", "ocean_buoy": "2k", "wooden_barrels_01": "2k",
    "wooden_crate_01": "2k", "plastic_crate_01": "2k", "metal_jerrycan": "2k", "rubber_boots": "2k",
    "fishermans_hat": "2k", "Lantern_01": "2k", "coast_rocks_01": "2k",
    "boulder_01": "2k", "modular_street_seating": "2k", "fire_hydrant": "2k",
    "utility_box_01": "2k", "concrete_road_barrier": "2k", "rollershutter_door": "2k",
    "exterior_aircon_unit": "2k", "security_light": "2k", "street_lamp_02": "2k",
    "shrub_02": "2k", "old_tyre": "2k", "wooden_bucket_01": "2k",
    # visual pass 2: walls, small things that make rooms lived in, the square
    "hanging_picture_frame_01": "2k", "hanging_picture_frame_02": "2k", "hanging_picture_frame_03": "2k",
    "fancy_picture_frame_02": "2k", "standing_picture_frame_02": "2k", "mantel_clock_01": "2k",
    "Television_01": "2k", "television_02": "2k",
    "ceiling_fan": "2k", "security_camera_01": "2k", "security_camera_02": "2k",
    "modern_ceiling_lamp_01": "2k", "industrial_wall_lamp": "2k", "ClassicNightstand_01": "2k",
    "Shelf_01": "2k", "ceramic_vase_01": "2k", "ceramic_vase_03": "2k", "tea_set_01": "2k",
    "pot_enamel_01": "2k", "wicker_basket_01": "2k", "plastic_monobloc_chair_01": "2k",
    "outdoor_table_chair_set_01": "2k", "metal_stool_01": "2k", "Barrel_01": "2k",
    "wooden_crate_02": "2k", "life_jacket": "2k", "bleach_bottle": "2k", "all_purpose_cleaner": "2k",
    "plastic_broom": "2k", "dustpan": "2k", "plunger": "2k", "wooden_ladder_02": "2k",
    "utility_box_02": "2k", "water_manhole_cover": "2k", "food_apple_01": "2k", "lemon": "2k",
    "croissant": "2k", "classic_laptop": "2k", "cassette_player": "2k",
    "vintage_radio_transceiver": "2k", "cigarette_pack": "2k", "round_spectacles": "2k",
    "vintage_electric_kettle": "2k", "Sofa_01": "2k", "mid_century_lounge_chair": "2k", "wooden_display_shelves_01": "2k",
    "planter_box_01": "2k",
    # dressing pass: the small things on every surface
    "brass_pot_01": "2k", "wooden_bowl_01": "2k", "carved_wooden_plate": "2k", "metal_jug": "2k", "ceramic_vase_02": "2k",
    "ceramic_vase_04": "2k", "antique_ceramic_vase_01": "2k", "wicker_basket_02": "2k", "plastic_bottle_gallon": "2k", "multi_cleaner_bottle": "2k",
    "food_kiwi_01": "2k", "food_pears_asian_01": "2k", "bananas": "2k", "long_life_food": "2k", "russian_food_cans_01": "2k",
    "modified_thermos": "2k", "plastic_thermos": "2k", "vintage_lighter": "2k", "pocket_watch": "2k", "digital_wrist_watch": "2k",
    "garden_gloves_01": "2k", "measuring_tape_01": "2k", "screwdriver": "2k", "medical_tape": "2k", "rubber_duck_toy": "2k",
    "football": "2k", "dartboard": "2k", "gamepad": "2k", "Camera_01": "2k", "boombox": "2k",
    "plastic_crate_02": "2k", "metal_toolbox": "2k", "tool_cart": "2k", "worn_metal_rack": "2k", "WoodenChair_01": "2k",
    "GreenChair_01": "2k", "Ottoman_01": "2k", "painted_wooden_chair_01": "2k", "coffee_table_round_01": "2k",
    "small_wooden_table_01": "2k", "ClassicConsole_01": "2k", "painted_wooden_shelves": "2k", "SchoolChair_01": "2k",
    "SchoolDesk_01": "2k", "wooden_stool_02": "2k", "vintage_oil_lamp": "2k", "hanging_industrial_lamp": "2k", "lantern_chandelier_01": "2k",
    "ornate_mirror_01": "2k", "portable_cassette_player": "2k", "cigarette_case": "2k", "vintage_flashlight": "2k", "plastic_container": "2k",
    "painted_wooden_cabinet_02": "2k", "CoffeeTable_01": "2k",
    # vegetation: no longer cut for size
    "jacaranda_tree": "2k", "island_tree_01": "2k", "island_tree_02": "2k", "shrub_01": "2k",
    "shrub_03": "2k", "shrub_04": "2k", "searsia_lucida": "2k", "grass_medium_01": "2k",
    "grass_medium_02": "2k", "dandelion_01": "2k", "fern_02": "2k", "planter_pot_clay": "2k",
    # hall / outside
    "fancy_picture_frame_01": "2k", "street_lamp_01": "2k", "covered_car": "2k",
    "metal_trash_can": "2k", "trashbag": "2k",
}
TEXTURES = {
    # tiling surfaces, 4K (seen up close in first person)
    "herringbone_parquet": "4k", "plastered_wall_04": "2k", "white_plaster_02": "2k",
    "terrazzo_tiles": "4k", "square_tiled_wall": "2k", "marble_mosaic_tiles": "4k",
    "long_white_tiles": "4k", "marble_01": "4k", "painted_plaster_wall": "4k",
    "stone_pavers": "4k", "asphalt_06": "4k", "kitchen_wood": "4k",
    "dark_wooden_planks": "4k", "dark_wood": "4k", "roof_planks": "4k",
    "old_linoleum_flooring_01": "2k", "painted_concrete": "4k", "grey_tiles": "4k",
    "coast_sand_02": "2k", "damp_sand": "4k", "stone_wall": "2k", "weathered_planks": "4k",
    "cobblestone_floor_04": "4k", "rough_block_wall": "4k", "concrete_wall_003": "4k", "forest_ground_05": "4k",
    # surface detail for painted, metal and fabric things (WB.flat uses their relief)
    "rough_linen": "2k", "metal_plate": "2k", "wood_cabinet_worn_long": "2k",
    "white_plaster_rough_01": "2k", "plywood": "2k", "smooth_concrete_floor": "2k",
    "painted_metal_shutter": "2k", "velour_velvet": "2k", "worn_plaster_wall": "2k",
}


def get(url: str) -> bytes:
    # the connection drops now and then on big files: try again a few times
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except OSError:
            if attempt == 5:
                raise
            time.sleep(2 ** (attempt + 1))
    return b""


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
        d = os.path.join(ROOT, "models", aid)
        if (not only or aid in only) and (force or not os.path.isdir(d)):
            fetch_model(aid, res)
            # drop textures left over from another resolution
            tex = os.path.join(d, "textures")
            if os.path.isdir(tex):
                for f in os.listdir(tex):
                    if f"_{res}." not in f:
                        os.remove(os.path.join(tex, f))
    for aid, res in TEXTURES.items():
        if (not only or aid in only) and (force or not os.path.isdir(os.path.join(ROOT, "textures", aid))):
            fetch_texture(aid, res)
    credits()


if __name__ == "__main__":
    main()
