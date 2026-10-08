class_name PhotoPresets
extends RefCounted
## Scene presets for PhotoView. A photo spec is:
##   {"preset": "pier_night", <params>, "layers": [extra...],
##    "variants": {"name": {"set": {params}, "add": [layers], "remove": ["layer name"]}}}
## Named layers ("n": "figure1") can be removed by variants.


static func build(spec: Dictionary, variant: String) -> Array:
	var params := spec.duplicate()
	var var_def: Dictionary = spec.get("variants", {}).get(variant, {})
	for k in var_def.get("set", {}):
		params[k] = var_def.set[k]
	var layers: Array = []
	match str(params.get("preset", "")):
		"room_night": layers = room_night(params)
		"window_outside": layers = window_outside(params)
		"street_night": layers = street_night(params)
		"pier_night": layers = pier_night(params)
		"pier_day": layers = pier_day(params)
		"beach_day": layers = beach_day(params)
		"bar": layers = bar(params)
		"group": layers = group(params)
		"portrait": layers = portrait(params)
		"food": layers = food(params)
		"cat": layers = cat(params)
		"bookshop": layers = bookshop(params)
		"document": layers = document(params)
		"car_night": layers = car_night(params)
		"corridor": layers = corridor(params)
		"office": layers = office(params)
		"back": layers = back(params)
		"sunset": layers = sunset(params)
		"cctv": layers = cctv(params)
		"door": layers = door(params)
		"black": layers = black(params)
		"sea_night": layers = sea_night(params)
		"bedroom": layers = bedroom(params)
		"screen": layers = screen(params)
		"", "custom": layers = []
		_:
			push_warning("unknown photo preset " + str(params.get("preset")))
	layers.append_array(params.get("layers", []))
	layers.append_array(var_def.get("add", []))
	var removed: Array = var_def.get("remove", [])
	if not removed.is_empty():
		layers = layers.filter(func(L): return not removed.has(L.get("n", "")))
	return layers


# ------------------------------------------------------------ helpers
static func g(cols: Array, y0 := 0.0, y1 := 1.0) -> Dictionary:
	return {"t": "grad", "c": cols, "y0": y0, "y1": y1}


static func rc(x: float, y: float, w: float, h: float, c: String, extra := {}) -> Dictionary:
	var d := {"t": "rect", "r": [x, y, w, h], "c": c}
	d.merge(extra)
	return d


static func poly(pts: Array, c: String, extra := {}) -> Dictionary:
	var d := {"t": "poly", "pts": pts, "c": c}
	d.merge(extra)
	return d


static func glow(x: float, y: float, r: float, c: String, extra := {}) -> Dictionary:
	var d := {"t": "glow", "p": [x, y], "r": r, "c": c}
	d.merge(extra)
	return d


static func fig(x: float, y: float, h: float, extra := {}) -> Dictionary:
	var d := {"t": "figure", "p": [x, y], "h": h, "c": "#050506"}
	d.merge(extra)
	return d


static func _figs(p: Dictionary, layers: Array) -> void:
	# params "figs": [[x, y, h, pose, name, alpha]]
	for f in p.get("figs", []):
		var d := fig(float(f[0]), float(f[1]), float(f[2]))
		if f.size() > 3:
			d.pose = f[3]
		if f.size() > 4:
			d.n = f[4]
		if f.size() > 5:
			d.a = float(f[5])
		if f.size() > 6:
			d.c = f[6]
		layers.append(d)


# ------------------------------------------------------------ presets
static func room_night(p: Dictionary) -> Array:
	var L: Array = [
		g(["#15161a", "#0d0e11", "#08090b"]),
		# window
		rc(0.58, 0.14, 0.3, 0.36, "#0c1420", {"n": "window"}),
		rc(0.58, 0.14, 0.3, 0.36, "#101a28", {"c2": "#060a10"}),
		rc(0.725, 0.14, 0.01, 0.36, "#1b1d22"),
		rc(0.58, 0.315, 0.3, 0.01, "#1b1d22"),
		# curtain
		poly([0.52, 0.1, 0.6, 0.1, 0.62, 0.55, 0.5, 0.56], "#1a1414"),
		# lamp
		glow(0.18, 0.42, 0.45, "#e2b26a55"),
		poly([0.13, 0.35, 0.23, 0.35, 0.21, 0.42, 0.15, 0.42], "#c9a36a"),
		rc(0.175, 0.42, 0.01, 0.2, "#2a2420"),
		# sofa
		rc(0.05, 0.6, 0.75, 0.17, "#2a2c33", {"c2": "#1b1c21"}),
		rc(0.05, 0.53, 0.75, 0.1, "#30333b"),
		rc(0.03, 0.55, 0.06, 0.24, "#25272d"),
		rc(0.76, 0.55, 0.06, 0.24, "#25272d"),
		# floor + table
		rc(0, 0.78, 1, 0.22, "#0b0b0d"),
		rc(0.25, 0.8, 0.45, 0.04, "#2a2119"),
		rc(0.28, 0.84, 0.02, 0.1, "#1d1712"),
		rc(0.65, 0.84, 0.02, 0.1, "#1d1712"),
		# mug on table
		rc(0.4, 0.765, 0.04, 0.035, "#ccc6bd"),
		# hallway door: the corridor beyond is faintly lit (bathroom nightlight),
		# so anything standing in it reads as a silhouette
		rc(0.86, 0.12, 0.14, 0.66, "#0a0a0c", {"n": "hall"}),
		rc(0.88, 0.14, 0.12, 0.64, "#1a1d24", {"c2": "#101217", "n": "hall_gap"}),
		glow(0.97, 0.3, 0.12, "#8aa0c018"),
	]
	_figs(p, L)
	return L


static func window_outside(p: Dictionary) -> Array:
	var L: Array = [
		g(["#05070b", "#0b0f16", "#11151c"]),
		# house wall
		rc(0.0, 0.18, 1.0, 0.6, "#1a1c20", {"c2": "#121316"}),
		rc(0.0, 0.16, 1.0, 0.03, "#242629"),
		# lit window
		glow(0.5, 0.45, 0.5, "#e0b06a30"),
		rc(0.28, 0.3, 0.44, 0.3, "#c7965a", {"c2": "#8d6537"}),
		# interior: sofa back + person on phone
		rc(0.28, 0.48, 0.44, 0.12, "#3a2f28"),
		fig(0.52, 0.66, 0.28, {"pose": "phone", "c": "#1a1411", "n": "daniel"}),
		rc(0.28, 0.3, 0.44, 0.3, "#00000000"),
		# window frame
		rc(0.495, 0.3, 0.01, 0.3, "#1c1a18"),
		rc(0.28, 0.44, 0.44, 0.008, "#1c1a18"),
		rc(0.26, 0.6, 0.48, 0.02, "#2c2c2e"),
		# hedge / foreground
		poly([0, 0.78, 0.1, 0.72, 0.2, 0.76, 0.35, 0.7, 0.5, 0.75, 0.65, 0.69, 0.8, 0.74, 1, 0.7, 1, 1, 0, 1], "#060807"),
		# street lamp spill
		glow(0.95, 0.05, 0.35, "#ffb35a22"),
	]
	_figs(p, L)
	return L


static func street_night(p: Dictionary) -> Array:
	var L: Array = [
		g(["#04060a", "#0a0e15", "#131820"], 0.0, 0.55),
		rc(0.0, 0.25, 0.32, 0.4, "#101216"),
		{"t": "windows", "r": [0.02, 0.28, 0.28, 0.3], "cols": 3, "rows": 4, "lit": 0.25, "seed": int(p.get("seed", 3))},
		rc(0.68, 0.2, 0.32, 0.45, "#0e1014"),
		{"t": "windows", "r": [0.7, 0.23, 0.28, 0.35], "cols": 3, "rows": 5, "lit": 0.15, "seed": int(p.get("seed", 3)) + 7},
		poly([0.32, 0.6, 0.68, 0.6, 1.0, 1.0, 0.0, 1.0], "#0b0c0e"),
		poly([0.48, 0.6, 0.52, 0.6, 0.6, 1.0, 0.4, 1.0], "#141518"),
		# lamp posts
		rc(0.3, 0.3, 0.008, 0.32, "#1a1a1a"),
		glow(0.31, 0.3, 0.3, "#ffbd6a40"),
		glow(0.31, 0.3, 0.05, "#ffe2b0cc"),
		glow(0.4, 0.82, 0.35, "#ffbd6a18"),
		rc(0.73, 0.38, 0.006, 0.24, "#1a1a1a"),
		glow(0.735, 0.38, 0.18, "#ffbd6a28"),
	]
	_figs(p, L)
	if p.get("rain", false):
		L.append({"t": "rain", "n": 180})
	return L


static func pier_night(p: Dictionary) -> Array:
	var L: Array = [
		g(["#020306", "#060a12", "#0b1220"], 0.0, 0.5),
		{"t": "stars", "n": 50, "seed": 31, "region": [0, 0, 1, 0.35]},
		glow(0.78, 0.14, 0.12, "#d8e2f033"),
		{"t": "circle", "p": [0.78, 0.14], "r": 0.025, "c": "#d9dfe6"},
		{"t": "sea", "y": 0.5, "c": ["#0a1522", "#020407"], "waves": 60, "hla": 0.22},
		# pier perspective
		poly([0.42, 0.5, 0.5, 0.5, 0.78, 1.0, 0.18, 1.0], "#1b1712"),
		poly([0.42, 0.5, 0.43, 0.5, 0.2, 1.0, 0.18, 1.0], "#0d0b09"),
		{"t": "line", "pts": [0.44, 0.5, 0.3, 1.0], "c": "#00000066", "w": 0.002},
		{"t": "line", "pts": [0.465, 0.5, 0.48, 1.0], "c": "#00000066", "w": 0.002},
		{"t": "line", "pts": [0.485, 0.5, 0.64, 1.0], "c": "#00000066", "w": 0.002},
		# posts
		rc(0.4, 0.46, 0.006, 0.06, "#14110d"),
		rc(0.5, 0.46, 0.006, 0.06, "#14110d"),
		rc(0.15, 0.62, 0.02, 0.38, "#0c0a08"),
		rc(0.8, 0.62, 0.02, 0.38, "#0c0a08"),
		# single lamp at the end
		rc(0.505, 0.38, 0.004, 0.12, "#121212"),
		glow(0.507, 0.38, 0.22, "#ffcf8a30", {"n": "lamp"}),
		glow(0.507, 0.38, 0.03, "#ffe6c0cc", {"n": "lamp_core"}),
	]
	_figs(p, L)
	return L


static func pier_day(p: Dictionary) -> Array:
	var L: Array = [
		g(["#9fc2dc", "#cfe0ea", "#e8eef0"], 0.0, 0.5),
		{"t": "sea", "y": 0.5, "c": ["#5f8fa8", "#2d5a73"], "waves": 50, "hl": "#ffffff", "hla": 0.35},
		poly([0.42, 0.5, 0.5, 0.5, 0.78, 1.0, 0.18, 1.0], "#8b6e4e"),
		poly([0.42, 0.5, 0.43, 0.5, 0.2, 1.0, 0.18, 1.0], "#5d4630"),
		{"t": "line", "pts": [0.44, 0.5, 0.3, 1.0], "c": "#00000033", "w": 0.002},
		{"t": "line", "pts": [0.485, 0.5, 0.64, 1.0], "c": "#00000033", "w": 0.002},
		rc(0.505, 0.38, 0.004, 0.12, "#333333"),
		rc(0.15, 0.62, 0.02, 0.38, "#4a3826"),
		rc(0.8, 0.62, 0.02, 0.38, "#4a3826"),
	]
	_figs(p, L)
	return L


static func beach_day(p: Dictionary) -> Array:
	var L: Array = [
		g(["#78a9cf", "#b9d5e6", "#e9eef0"], 0.0, 0.45),
		{"t": "circle", "p": [0.8, 0.12], "r": 0.05, "c": "#fff6d8"},
		glow(0.8, 0.12, 0.3, "#fff1c040"),
		{"t": "sea", "y": 0.45, "c": ["#3f7fa3", "#2c6b8a"], "waves": 60, "hl": "#ffffff", "hla": 0.45},
		poly([0, 0.62, 0.3, 0.58, 0.6, 0.6, 1, 0.56, 1, 1, 0, 1], "#e3cfa6"),
		poly([0, 0.62, 0.3, 0.58, 0.6, 0.6, 1, 0.56, 1, 0.6, 0.6, 0.64, 0.3, 0.62, 0, 0.66], "#f2f2ee88"),
	]
	_figs(p, L)
	return L


static func bar(p: Dictionary) -> Array:
	var L: Array = [
		g(["#1d120b", "#24170e", "#120b07"]),
		glow(0.2, 0.15, 0.35, "#ffb05a40"),
		glow(0.65, 0.12, 0.3, "#ffb05a38"),
		glow(0.9, 0.2, 0.25, "#d04a3a30"),
		# shelves with bottles
		rc(0.05, 0.2, 0.9, 0.012, "#3c2716"),
		rc(0.05, 0.36, 0.9, 0.012, "#3c2716"),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for s in 2:
		var x := 0.07
		while x < 0.93:
			var bh := rng.randf_range(0.07, 0.12)
			var col: String = ["#3b5e3a", "#6b3a1f", "#c9b27a", "#2f4f6b", "#7b2a2a", "#d8d8c8"][rng.randi() % 6]
			L.append(rc(x, 0.2 + s * 0.16 - bh, 0.022, bh, col + "cc"))
			x += rng.randf_range(0.03, 0.05)
	L.append_array([
		rc(0.0, 0.62, 1.0, 0.06, "#4a2c17"),
		rc(0.0, 0.68, 1.0, 0.32, "#1a0f08"),
		{"t": "text", "p": [0.36, 0.52], "s": 0.05, "c": "#ff9b5a", "v": "O FAROL", "a": 0.75},
	])
	_figs(p, L)
	return L


static func group(p: Dictionary) -> Array:
	var bg: String = p.get("bg", "bar")
	var L: Array = bar({}) if bg == "bar" else (beach_day({}) if bg == "beach" else office({}))
	for f in p.get("faces", []):
		L.append(f)
	if p.get("flash", true):
		L.append(glow(0.5, 0.55, 0.7, "#ffffff10"))
	return L


static func portrait(p: Dictionary) -> Array:
	var bg: String = p.get("bg", "#2a2f36")
	var L: Array = []
	if bg == "bar":
		L = bar({})
	elif bg == "beach":
		L = beach_day({})
	elif bg == "street":
		L = street_night({})
	else:
		L = [g([bg, Color(bg).darkened(0.4).to_html()])]
	for f in p.get("faces", []):
		L.append(f)
	return L


static func food(p: Dictionary) -> Array:
	return [
		g(["#5a3d2a", "#3f2a1c"]),
		{"t": "ellipse", "p": [0.5, 0.52], "rx": 0.42, "ry": 0.32, "c": "#e8e4dc"},
		{"t": "ellipse", "p": [0.5, 0.52], "rx": 0.33, "ry": 0.25, "c": "#f3efe8"},
		{"t": "ellipse", "p": [0.47, 0.5], "rx": 0.2, "ry": 0.14, "c": str(p.get("food", "#d9a44a"))},
		{"t": "ellipse", "p": [0.56, 0.56], "rx": 0.09, "ry": 0.06, "c": "#7a3b1e"},
		{"t": "ellipse", "p": [0.4, 0.45], "rx": 0.05, "ry": 0.03, "c": "#4f7a32"},
		rc(0.88, 0.2, 0.03, 0.6, "#c9c9c9"),
	]


static func cat(p: Dictionary) -> Array:
	return [
		g(["#4a4038", "#2c2621"]),
		rc(0.0, 0.65, 1.0, 0.35, "#5b4a3c"),
		{"t": "ellipse", "p": [0.5, 0.62], "rx": 0.28, "ry": 0.16, "c": "#d08a42"},
		{"t": "circle", "p": [0.32, 0.48], "r": 0.11, "c": "#d08a42"},
		poly([0.24, 0.42, 0.26, 0.32, 0.31, 0.39], "#d08a42"),
		poly([0.34, 0.38, 0.39, 0.31, 0.4, 0.42], "#d08a42"),
		{"t": "ellipse", "p": [0.29, 0.47], "rx": 0.012, "ry": 0.008, "c": "#1a1a10"},
		{"t": "ellipse", "p": [0.36, 0.47], "rx": 0.012, "ry": 0.008, "c": "#1a1a10"},
		poly([0.72, 0.62, 0.86, 0.5, 0.88, 0.53, 0.76, 0.66], "#c07a36"),
	]


static func bookshop(p: Dictionary) -> Array:
	var L: Array = [
		g(["#2a2018", "#1d1610"]),
		{"t": "books", "r": [0.04, 0.05, 0.92, 0.8], "shelves": 5, "seed": int(p.get("seed", 21))},
		glow(0.5, 0.0, 0.6, "#ffd59a22"),
		rc(0.0, 0.86, 1.0, 0.14, "#120d09"),
	]
	_figs(p, L)
	return L


static func document(p: Dictionary) -> Array:
	var L: Array = [
		g(["#3a3530", "#2a2622"]),
		poly([0.12, 0.08, 0.88, 0.06, 0.9, 0.94, 0.1, 0.95], "#e9e5dc"),
		{"t": "text", "p": [0.18, 0.16], "s": 0.028, "c": "#1f1f1f", "v": str(p.get("title", ""))},
		{"t": "lines", "r": [0.18, 0.22, 0.62, 0.62], "seed": int(p.get("seed", 5)), "step": 0.032, "c": "#55524d"},
	]
	for i in p.get("text", []).size():
		L.append({"t": "text", "p": [0.18, 0.24 + i * 0.035], "s": 0.022, "c": "#2b2b2b", "v": p.text[i]})
	if p.get("stamp", "") != "":
		L.append({"t": "text", "p": [0.5, 0.86], "s": 0.035, "c": "#a32a2a", "v": p.stamp, "a": 0.8})
	return L


static func car_night(p: Dictionary) -> Array:
	var L: Array = [
		g(["#020305", "#05070a"]),
		poly([0.3, 0.55, 0.7, 0.55, 1.0, 0.85, 0.0, 0.85], "#0e0f11"),
		glow(0.5, 0.75, 0.4, "#f2e3b020"),
		poly([0.47, 0.55, 0.53, 0.55, 0.6, 0.85, 0.4, 0.85], "#16171a"),
		# dashboard + frame
		rc(0.0, 0.8, 1.0, 0.2, "#030303"),
		poly([0, 0, 0.12, 0, 0.0, 0.8], "#030303"),
		poly([1, 0, 0.88, 0, 1, 0.8], "#030303"),
		rc(0.0, 0.0, 1.0, 0.1, "#030303"),
		glow(0.25, 0.86, 0.06, "#7ec8ff30"),
		rc(0.45, 0.1, 0.1, 0.04, "#0a0a0a"),
	]
	_figs(p, L)
	return L


static func corridor(p: Dictionary) -> Array:
	var L: Array = [
		g(["#c9d1d1", "#a9b3b3"]),
		poly([0, 0, 0.35, 0.3, 0.35, 0.7, 0, 1], "#b9c2c1"),
		poly([1, 0, 0.65, 0.3, 0.65, 0.7, 1, 1], "#aab3b2"),
		poly([0, 1, 0.35, 0.7, 0.65, 0.7, 1, 1], "#8e9897"),
		poly([0, 0, 0.35, 0.3, 0.65, 0.3, 1, 0], "#dfe5e4"),
		rc(0.4, 0.38, 0.2, 0.32, "#6b7676"),
		rc(0.08, 0.25, 0.12, 0.5, "#7d8a8a"),
		rc(0.8, 0.25, 0.12, 0.5, "#7d8a8a"),
	]
	_figs(p, L)
	return L


static func office(p: Dictionary) -> Array:
	var L: Array = [
		g(["#dfe3e6", "#c3c8cc"]),
		rc(0.0, 0.1, 1.0, 0.45, "#a9c3d6", {"c2": "#cfdbe3"}),
		rc(0.0, 0.1, 1.0, 0.45, "#ffffff22"),
		rc(0.33, 0.1, 0.01, 0.45, "#8a9198"),
		rc(0.66, 0.1, 0.01, 0.45, "#8a9198"),
		rc(0.0, 0.62, 1.0, 0.05, "#e9ecee"),
		rc(0.1, 0.48, 0.2, 0.14, "#1c1f24"),
		rc(0.55, 0.48, 0.2, 0.14, "#1c1f24"),
		rc(0.0, 0.67, 1.0, 0.33, "#9ca3a9"),
		{"t": "text", "p": [0.06, 0.08], "s": 0.035, "c": "#2a4e6a", "v": "LUMEN"},
	]
	_figs(p, L)
	return L


static func back(p: Dictionary) -> Array:
	## The impossible photo: Daniel seen from behind, on the sofa, holding the phone.
	var L: Array = [
		g(["#0b0b0d", "#08080a"]),
		glow(0.5, 0.3, 0.5, "#9fb8d815"),
		# sofa back seen from behind
		rc(0.0, 0.62, 1.0, 0.38, "#1e1f24", {"c2": "#121216"}),
		# the back of a head and shoulders, lit by the phone screen
		{"t": "ellipse", "p": [0.5, 0.82], "rx": 0.3, "ry": 0.16, "c": "#121214"},
		{"t": "ellipse", "p": [0.5, 0.56], "rx": 0.12, "ry": 0.15, "c": "#151313"},
		{"t": "ellipse", "p": [0.5, 0.52], "rx": 0.12, "ry": 0.12, "c": "#1c1715"},
		glow(0.5, 0.42, 0.2, "#a8c4ff30"),
		# phone glow above the shoulder
		rc(0.56, 0.6, 0.07, 0.11, "#b9d0ff", {"a": 0.55}),
		# window in front (where the camera should have been)
		rc(0.3, 0.06, 0.4, 0.3, "#0a111b"),
		rc(0.495, 0.06, 0.01, 0.3, "#16181c"),
	]
	_figs(p, L)
	return L


static func sunset(p: Dictionary) -> Array:
	var L: Array = [
		g(["#2d2c55", "#a85a6a", "#f2a65a", "#f7d48a"], 0.0, 0.55),
		{"t": "circle", "p": [0.5, 0.52], "r": 0.07, "c": "#ffe0a0"},
		{"t": "sea", "y": 0.55, "c": ["#9e5e5a", "#2a2440"], "waves": 60, "hl": "#ffd090", "hla": 0.5},
	]
	_figs(p, L)
	return L


static func cctv(p: Dictionary) -> Array:
	var L: Array = [
		g(["#1c1f1d", "#2b2f2c", "#343835"], 0.0, 1.0),
		poly([0.0, 0.55, 1.0, 0.42, 1.0, 0.75, 0.0, 0.95], "#3c403d"),
		{"t": "line", "pts": [0.0, 0.75, 1.0, 0.585], "c": "#7a7f7a88", "w": 0.004},
		rc(0.0, 0.0, 1.0, 0.4, "#2a2d2b"),
		glow(0.12, 0.2, 0.3, "#d9d9c040"),
	]
	if p.get("car", true):
		L.append_array([
			poly([0.42, 0.62, 0.66, 0.58, 0.7, 0.65, 0.44, 0.7], "#5c5f60"),
			poly([0.47, 0.6, 0.61, 0.575, 0.63, 0.6, 0.48, 0.625], "#24272a"),
			glow(0.69, 0.635, 0.06, "#ffffffaa"),
			{"t": "text", "p": [0.5, 0.69], "s": 0.022, "c": "#cfcfcf", "v": str(p.get("plate", "")), "a": 0.6},
		])
	_figs(p, L)
	L.append({"t": "scanlines", "a": 0.25})
	L.append({"t": "text", "p": [0.03, 0.06], "s": 0.035, "c": "#ffffff", "v": str(p.get("stamp", "CAM 02"))})
	return L


static func door(p: Dictionary) -> Array:
	var L: Array = [
		g(["#0c0c0e", "#08080a"]),
		rc(0.3, 0.1, 0.4, 0.8, "#1a1714"),
		rc(0.3, 0.1, float(p.get("gap", 0.08)), 0.8, "#020202", {"n": "gap"}),
		{"t": "circle", "p": [0.64, 0.52], "r": 0.012, "c": "#8a7a5a"},
		rc(0.0, 0.9, 1.0, 0.1, "#0b0a09"),
		glow(0.5, 0.95, 0.4, "#ffffff08"),
	]
	_figs(p, L)
	return L


static func black(p: Dictionary) -> Array:
	var L: Array = [g(["#030303", "#050505"])]
	_figs(p, L)
	return L


static func sea_night(p: Dictionary) -> Array:
	var L: Array = [
		g(["#020306", "#05080e"], 0.0, 0.45),
		{"t": "sea", "y": 0.45, "c": ["#060c14", "#010203"], "waves": 70, "hla": 0.15},
	]
	_figs(p, L)
	return L


static func bedroom(p: Dictionary) -> Array:
	var L: Array = [
		g(["#0e0f12", "#0a0a0c"]),
		rc(0.05, 0.55, 0.9, 0.3, "#24262c", {"c2": "#17181c"}),
		rc(0.05, 0.45, 0.25, 0.12, "#2e3036"),
		rc(0.0, 0.85, 1.0, 0.15, "#09090a"),
		rc(0.7, 0.1, 0.22, 0.32, "#0a0f17"),
		glow(0.15, 0.5, 0.2, "#7ea2ff18"),
	]
	_figs(p, L)
	return L


static func screen(p: Dictionary) -> Array:
	## A screenshot of a phone screen with a few lines of text.
	var L: Array = [g(["#0b0d10", "#0b0d10"])]
	var y := 0.08
	for line in p.get("lines", []):
		var me: bool = str(line).begins_with(">")
		var t: String = str(line).trim_prefix(">")
		var w := clampf(t.length() * 0.018 + 0.1, 0.2, 0.75)
		var x := 0.95 - w if me else 0.05
		L.append(rc(x, y, w, 0.05, "#2c4255" if me else "#20242b"))
		L.append({"t": "text", "p": [x + 0.02, y + 0.034], "s": 0.022, "c": "#e9e6e1", "v": t})
		y += 0.07
	return L
