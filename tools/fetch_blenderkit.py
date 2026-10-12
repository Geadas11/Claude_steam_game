#!/usr/bin/env python3
"""Download free models from BlenderKit (https://www.blenderkit.com) into
assets/3d/models/<id>/<id>.glb, so WB.model() places them like the Poly Haven
ones.

    python3 tools/fetch_blenderkit.py            # everything in MODELS
    python3 tools/fetch_blenderkit.py --force    # download again

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
}

BLEND_EXPORT = """
import bpy, sys
out = sys.argv[sys.argv.index("--") + 1]
if out.endswith(".in.glb"):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=out)
    out = out[:-7] + ".glb"
for im in bpy.data.images:
    w, h = im.size
    if max(w, h) > MAX_TEX:
        k = MAX_TEX / max(w, h)
        im.scale(max(1, int(w * k)), max(1, int(h * k)))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True,
                          export_yup=True, use_visible=True, export_image_format="JPEG")
""".replace("MAX_TEX", "1024")
SHRINK_ABOVE = 4_000_000  # bytes; bigger GLBs get their textures cut to 1024 px


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


def blender_run(blend: str, out: str) -> None:
    """Export `blend` (or, with blend="", re-export the .in.glb `out`) as GLB."""
    with tempfile.TemporaryDirectory() as tmp:
        script = os.path.join(tmp, "export.py")
        open(script, "w").write(BLEND_EXPORT)
        cmd = [shutil.which("blender"), "-b"] + ([blend] if blend else [])
        subprocess.run(cmd + ["--python", script, "--", out], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def shrink(glb: str) -> None:
    src = glb[:-4] + ".in.glb"
    os.replace(glb, src)
    blender_run("", src)
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
    if gl:
        data = get(signed(gl))
        os.makedirs(out, exist_ok=True)
        open(glb, "wb").write(data)
        if len(data) > SHRINK_ABOVE and shutil.which("blender"):
            shrink(glb)
    else:
        blender = shutil.which("blender")
        if not blender:
            print("skip", our_id, "(.blend only; install Blender to convert)")
            return False
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, "asset.blend")
            open(src, "wb").write(get(signed(files["blend"])))
            os.makedirs(out, exist_ok=True)
            blender_run(src, glb)
            if not os.path.exists(glb):
                raise SystemExit(f"{our_id}: Blender export failed")
    print("model", our_id, "<-", a["name"], f"({a['license']})")
    return True


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
    have = {}
    for our_id, base in MODELS.items():
        a = info(base)
        done = os.path.exists(os.path.join(ROOT, "models", our_id, our_id + ".glb"))
        if force or not done:
            done = fetch(our_id, a)
        if done:
            have[our_id] = a
    credits(have)


if __name__ == "__main__":
    main()
