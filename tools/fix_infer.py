"""Dev helper: turns `var x := expr` into `var x = expr` on lines where Godot
reports it cannot infer a static type. Run repeatedly until clean."""
import re, subprocess, sys
for it in range(15):
    out = subprocess.run("timeout 60 godot --headless res://tools/compile_all.tscn", shell=True, capture_output=True, text=True).stderr + ""
    out += subprocess.run("true", shell=True, capture_output=True, text=True).stdout
    lines = out.split("\n")
    fixes = []
    for i, l in enumerate(lines):
        if "Cannot infer the type" in l or "inferred from a Variant" in l:
            m = re.search(r"\(res://(.+?):(\d+)\)", lines[i+1] if i+1 < len(lines) else "")
            if m: fixes.append((m.group(1), int(m.group(2))))
    if not fixes:
        print("no inference fixes needed"); break
    for f, ln in fixes:
        src = open(f).read().split("\n")
        src[ln-1] = re.sub(r"\bvar (\w+) :=", r"var \1 =", src[ln-1], count=1)
        open(f, "w").write("\n".join(src))
        print("fixed", f, ln)
