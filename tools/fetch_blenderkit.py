#!/usr/bin/env python3
"""Download free models from BlenderKit (https://www.blenderkit.com) into
assets/3d/models/<id>/<id>.glb, so WB.model() places them like the Poly Haven
ones.

    python3 tools/fetch_blenderkit.py            # everything in MODELS
    python3 tools/fetch_blenderkit.py --force    # download again
    python3 tools/fetch_blenderkit.py --decimate # bring the ones here under budget

Free BlenderKit assets need no account or key. Only "royalty_free" (commercial
use, no attribution required, no resale of the asset itself) and "cc_zero"
(public domain) licences are accepted; we still credit every author in
assets/3d/CREDITS.md.

Models published only as .blend are converted with Blender when it is
installed (`blender` on PATH): see BLEND_ONLY.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import uuid

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d")
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) UNKNOWN-assets/1.0"}
API = "https://www.blenderkit.com/api/v1/search/?"
LICENCES = {"royalty_free", "cc_zero"}

# our id -> BlenderKit asset base id
MODELS = {
    "bk_toilet": "93ee67c9-c58a-4567-a463-2de73733debb",          # Toilet (Wall Hung)
    "bk_basin": "ad08cfc1-8c22-4793-b920-016bdbd39037",           # Modern basin + mirror
    "bk_bathtub": "05b90044-e5d1-4b45-b7c6-9ee49227b875",         # Generic Bathtub
    "bk_crt_monitor": "dde030e6-dd05-43bc-9e59-130681f72845",     # IBM 8513 dirty
    "bk_monitor": "e03ac19c-7aef-4d7f-bf41-f8286b0050e7",         # 27 inch monitor
    "bk_washer": "cba568e5-396d-4f90-bd7b-cebaa84a48a3",          # Modern flat washing machine
    "bk_bedside": "09dfde68-dac8-485f-a9f8-de42f22c87ed",         # Hospital bedside cabinet
    "bk_trolley": "55ab4191-b86d-4a87-ac43-f4b16a445e63",         # Medi trolley
    "bk_mayo_table": "48507381-deec-440b-b221-c1b98770b928",      # Mayo table (over-bed)
    "bk_med_stool": "362c3801-81d0-4ed4-84c8-710e454168bd",       # medical stool
    "bk_hospital_bed": "d91eed93-39a3-480e-9e87-ac9814583385",    # Old Hospital Bed (.blend)
    "bk_waiting_bench": "0ba31352-6fac-43c8-902c-9b9dad7cd961",   # Waiting bench chair (.blend)
    # visual pass 2
    "bk_fridge_black": "bdc31d4c-3879-4c46-a42d-2273d5ad82f3",    # Refrigerator (.blend)
    "bk_fridge_smeg": "bd506c1b-3eb0-4004-a45f-8c25cda485e4",     # Smeg fridge freezer (.blend)
    "bk_kettle": "cefb5bdc-7d0f-4ba8-92fe-a4ece160870e",          # kitchen kettle
    "bk_bed_wood": "040cfb6b-ee19-4ddd-a039-b58305239617",        # double bed, striped bedding (.blend)
    "bk_bed_metal": "5a7345ac-2da8-4f86-8d19-15710f25f161",       # white iron bed, floral (.blend)
    "bk_bed_single": "02ef4a9f-5935-4b49-be06-970846f69d2b",      # IKEA Slattum single bed
    "bk_mattress": "a007a8b9-7d79-420b-953b-d804dcfc41c1",        # quilted mattress
    "bk_towels": "74fca3ee-3226-4629-afdb-3b63ca8b3049",          # folded towels (.blend)
    "bk_sneakers": "bcce2091-e4d6-415f-a8be-5ce145d18552",        # red high-tops
    "bk_laptop": "e68dc9f3-b6cb-4088-9960-6ec8182c1871",          # 14" laptop
    "bk_dish_rack": "28315e81-3547-4362-a7fb-984ec783fbbd",       # dish drying rack (.blend)
    "bk_plate": "b34527f8-854b-4f06-a3ea-8acac490581e",           # white plate (.blend)
    "bk_dracaena": "c779cc58-abbd-478d-9e30-cf1423d8ccc3",        # dracaena in a pot
    "bk_street_lamp": "5eef57a2-0b42-4e48-9a62-bfd8afd7de22",     # double lantern post
    "bk_trash_bin": "29971a13-455e-417a-881f-c6bc14906659",       # concrete bin with bag (.blend)
    "bk_dumpsters": "d2ce9c7b-fb99-48af-b8fa-edfbd0687589",       # street wheelie bins (photoscan)
    "bk_park_bench": "0e35aec5-21cf-4e03-883e-008756e7d8bf",      # cast-iron park bench
    "bk_2cv": "aded2129-2a68-4a74-b8c9-ee00e03943b5",             # Citroen 2CV
    "bk_rug": "a1891b12-9881-49e0-a4b4-bf425bd9352e",             # patterned rug (.blend)
    "bk_palm": "f9c65ca8-8ad7-4b2b-80c1-b3634862da1d",          # palm tree for the square
    # detail pass: no longer limited by size
    "bk_pendant": "37124311-1106-4306-a4e1-480e0eb5b89f",         # white pendant light
    "bk_lamp_pletz": "678c8edf-4638-41e5-898e-87c027981bbe",      # table lamp, linen shade
    "bk_towel_rail": "24198e1f-3111-441a-95ed-c6da10d0fd72",      # heated towel rail (.blend)
    "bk_radiator": "35341a82-29bb-4304-9a39-8b078917f562",        # panel radiator (.blend)
    "bk_backpack": "fca3b63f-9def-4ba4-95e8-bf7ba7f9e52f",        # canvas backpack (.blend)
    "bk_toaster_cream": "be42f0a0-3e4f-46ec-bafa-9434a6ffeea8",   # retro toaster
    "bk_coffee": "c9d4195e-31d4-46b8-81b3-12a7217e2d1e",          # bean-to-cup coffee machine (.blend)
    "bk_pan": "9692ec04-0f6a-4103-b0c8-d0fc89d9ef7a",             # non-stick frying pan
    "bk_pan_iron": "8e08328b-c70b-4d5e-b533-3e1f419f09d3",        # iron frying pan
    "bk_clothes": "4fdb482d-2642-4388-ae57-8097afa99519",         # folded clothes stack
    "bk_tv": "ad2a1b9a-c3dc-4176-8150-be4715302b74",              # 50" TV
}

BLEND_EXPORT = """
import bpy, sys
argv = sys.argv[sys.argv.index("--") + 1:]
out = argv[0]
max_faces = int(argv[1]) if len(argv) > 1 else 0
if out.endswith(".in.glb"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=out)
    out = out[:-7] + ".glb"
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.visible_get()]
faces = sum(len(o.data.polygons) for o in meshes)
if max_faces and faces > max_faces:
    for o in meshes:
        mod = o.modifiers.new("decimate", "DECIMATE")
        mod.ratio = max_faces / faces
        mod.use_collapse_triangulate = True
for im in bpy.data.images:
    w, h = im.size
    if max(w, h) > MAX_TEX:
        k = MAX_TEX / max(w, h)
        im.scale(max(1, int(w * k)), max(1, int(h * k)))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True,
                          export_yup=True, use_visible=True, export_image_format="JPEG")
""".replace("MAX_TEX", "2048")
SHRINK_ABOVE = 4_000_000  # bytes; bigger GLBs get their textures cut to 2048 px
# Most props are seen at arm's length in a dark room: 12k faces is plenty.
# Bigger things that fill the view get more.
MAX_FACES = 12000
FACES = {"bk_bed_single": 90000, "bk_bed_wood": 24000, "bk_bed_metal": 20000, "bk_2cv": 60000,
         "bk_sneakers": 50000,
         "bk_dumpsters": 16000, "bk_mattress": 6000, "bk_bedside": 6000, "bk_palm": 16000}


def get(url: str) -> bytes:
    for attempt in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=180) as r:
                return r.read()
        except OSError:
            if attempt == 4:
                raise
            time.sleep(2 ** (attempt + 1))
    return b""


def info(base_id: str) -> dict:
    d = json.loads(get(API + urllib.parse.urlencode({"query": f"asset_base_id:{base_id}"})))
    if not d.get("results"):
        raise SystemExit(f"BlenderKit asset {base_id} not found")
    return d["results"][0]


def signed(file: dict) -> str:
    d = json.loads(get(file["downloadUrl"] + "?scene_uuid=" + str(uuid.uuid4())))
    return d["filePath"]


def blender_run(blend: str, out: str, max_faces: int = 0) -> None:
    """Export `blend` (or, with blend="", re-export the .in.glb `out`) as GLB,
    decimated down to about `max_faces` when it has more."""
    with tempfile.TemporaryDirectory() as tmp:
        script = os.path.join(tmp, "export.py")
        open(script, "w").write(BLEND_EXPORT)
        cmd = [shutil.which("blender"), "-b"] + ([blend] if blend else [])
        subprocess.run(cmd + ["--python", script, "--", out, str(max_faces)], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def shrink(glb: str, max_faces: int = 0) -> None:
    src = glb[:-4] + ".in.glb"
    os.replace(glb, src)
    blender_run("", src, max_faces)
    os.remove(src)
    if not os.path.exists(glb):
        raise SystemExit(f"{glb}: Blender re-export failed")


def fetch(our_id: str, a: dict) -> bool:
    if a.get("license") not in LICENCES or not a.get("isFree"):
        raise SystemExit(f"{our_id}: licence {a.get('license')} not allowed")
    files = {f["fileType"]: f for f in a["files"]}
    out = os.path.join(ROOT, "models", our_id)
    glb = os.path.join(out, our_id + ".glb")
    gl = files.get("gltf_godot") or files.get("gltf")
    limit = face_limit(our_id, a)
    if gl:
        data = get(signed(gl))
        os.makedirs(out, exist_ok=True)
        open(glb, "wb").write(data)
        if (len(data) > SHRINK_ABOVE or limit) and shutil.which("blender"):
            shrink(glb, limit)
    else:
        blender = shutil.which("blender")
        if not blender:
            print("skip", our_id, "(.blend only; install Blender to convert)")
            return False
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, "asset.blend")
            open(src, "wb").write(get(signed(files["blend"])))
            os.makedirs(out, exist_ok=True)
            blender_run(src, glb, limit)
            if not os.path.exists(glb):
                raise SystemExit(f"{our_id}: Blender export failed")
    print("model", our_id, "<-", a["name"], f"({a['license']})")
    return True


def face_limit(our_id: str, a: dict) -> int:
    """The face budget for this model, or 0 when it is already under it."""
    limit = FACES.get(our_id, MAX_FACES)
    faces = (a.get("dictParameters") or {}).get("faceCount") or 0
    return limit if faces > limit else 0


def credits(assets: dict) -> None:
    path = os.path.join(ROOT, "CREDITS.md")
    text = open(path).read() if os.path.exists(path) else "# Recursos 3D\n"
    marker = "\n## BlenderKit\n"
    head, _, tail = text.partition(marker)
    rest = ""
    if tail and "\n## " in tail:
        rest = "\n## " + tail.split("\n## ", 1)[1]
    lic = {"royalty_free": "Royalty Free", "cc_zero": "CC0"}
    body = marker + ("\nModelos gratuitos de https://www.blenderkit.com — licença Royalty Free "
                     "(uso comercial permitido, sem revenda do modelo) ou CC0.\n\n")
    for our_id, a in sorted(assets.items()):
        author = ((a.get("author") or {}).get("fullName") or "?").strip()
        body += f"- Modelo `{our_id}` — «{a['name']}» de {author}, {lic[a['license']]}, https://www.blenderkit.com/get-blenderkit/{a['id']}/\n"
    open(path, "w").write(head.rstrip("\n") + "\n" + body + rest)


def main() -> None:
    force = "--force" in sys.argv
    decimate = "--decimate" in sys.argv   # bring models already here under budget
    have = {}
    for our_id, base in MODELS.items():
        a = info(base)
        glb = os.path.join(ROOT, "models", our_id, our_id + ".glb")
        done = os.path.exists(glb)
        if force or not done:
            done = fetch(our_id, a)
        elif decimate and face_limit(our_id, a):
            shrink(glb, face_limit(our_id, a))
            print("decimated", our_id, "to", face_limit(our_id, a), "faces")
        if done:
            have[our_id] = a
    credits(have)


if __name__ == "__main__":
    main()
