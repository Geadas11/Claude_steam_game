#!/usr/bin/env python3
"""Bring heavy Poly Haven models under a face budget with Blender.

    python3 tools/decimate_models.py

Each model in BUDGET is read from assets/3d/models/<id>/<id>.gltf, decimated
to about the given number of faces and written as <id>.glb next to it (the
glTF, its .bin and its textures folder are then removed). WB.model() prefers
the .glb, and fetch_polyhaven.py skips a model whose folder already exists.
Foliage is only decimated when it is far too heavy (its leaves are alpha
cards and lose shape): the jacaranda seen from Sofia's window.
"""
import os
import shutil
import subprocess
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "3d", "models")

BUDGET = {
    "coast_rocks_01": 40000, "fire_hydrant": 10000, "boulder_01": 8000,
    "concrete_road_barrier": 6000, "book_encyclopedia_set_01": 12000,
    "vintage_cabinet_01": 20000, "rubber_boots": 10000, "tea_set_01": 10000,
    "wheelchair_01": 20000, "old_bed_frame": 20000,
    # 3.9 million triangles is too much even for a tree seen from a window
    "jacaranda_tree": 400000,
}

SCRIPT = """
import bpy, sys
src, out, budget = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
faces = sum(len(o.data.polygons) for o in meshes)
if faces > int(budget):
    for o in meshes:
        m = o.modifiers.new("decimate", "DECIMATE")
        m.ratio = int(budget) / faces
        m.use_collapse_triangulate = True
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_apply=True, export_image_format="JPEG")
print("FACES", faces, "->", budget)
"""


def main() -> None:
    blender = shutil.which("blender")
    if not blender:
        raise SystemExit("Blender is needed (apt install blender python3-numpy)")
    with tempfile.TemporaryDirectory() as tmp:
        script = os.path.join(tmp, "dec.py")
        open(script, "w").write(SCRIPT)
        for mid, budget in BUDGET.items():
            d = os.path.join(ROOT, mid)
            src = os.path.join(d, mid + ".gltf")
            if not os.path.exists(src):
                continue
            out = os.path.join(d, mid + ".glb")
            subprocess.run([blender, "-b", "--python", script, "--", src, out, str(budget)], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if not os.path.exists(out):
                raise SystemExit(mid + ": Blender export failed")
            for f in os.listdir(d):
                p = os.path.join(d, f)
                if f.startswith(mid + ".gltf") or f.startswith(mid + ".bin"):
                    os.remove(p)
                elif f == "textures":
                    shutil.rmtree(p)
            print("decimated", mid, "to", budget)


if __name__ == "__main__":
    main()
