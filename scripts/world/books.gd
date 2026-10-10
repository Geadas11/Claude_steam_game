class_name Books
## Bookshelves full of books, built in code. Every book is one instance of a
## MultiMesh, with its own size, colour and spine design (gold bands, a paper
## label, lines of "title"), drawn by one shader — thousands of books for the
## cost of one draw call per shelf unit.

const PALETTE := [
	Color(0.55, 0.12, 0.10), Color(0.18, 0.22, 0.35), Color(0.12, 0.26, 0.18), Color(0.72, 0.62, 0.42),
	Color(0.86, 0.83, 0.76), Color(0.30, 0.20, 0.14), Color(0.62, 0.36, 0.14), Color(0.10, 0.10, 0.12),
	Color(0.80, 0.78, 0.70), Color(0.45, 0.10, 0.18), Color(0.25, 0.32, 0.40), Color(0.68, 0.55, 0.20),
	Color(0.90, 0.88, 0.82), Color(0.36, 0.40, 0.30), Color(0.20, 0.14, 0.22), Color(0.74, 0.28, 0.20),
]

static var _mat: ShaderMaterial
static var _mesh: BoxMesh


static func material() -> ShaderMaterial:
	if _mat:
		return _mat
	var sh := Shader.new()
	sh.code = """shader_type spatial;
varying vec3 lp;
varying vec3 ln;
varying vec4 cust;
void vertex() {
	lp = VERTEX;
	ln = NORMAL;
	cust = INSTANCE_CUSTOM;
}
float h(float n) { return fract(sin(n * 91.3458) * 47453.5453); }
void fragment() {
	vec3 base = COLOR.rgb;
	vec3 c = base;
	float rough = 0.62;
	float s = cust.x * 997.0;
	if (abs(ln.y) > 0.5) {
		// the paper block seen from above, framed by the cover boards
		float cover = step(0.44, lp.z) + step(0.4, abs(lp.x));
		vec3 paper = vec3(0.72, 0.67, 0.56) * (0.93 + 0.07 * h(floor(lp.z * 9.0) + s));
		c = mix(paper, base * 0.85, clamp(cover, 0.0, 1.0));
		rough = 0.92;
	} else if (ln.z > 0.5) {
		float y = lp.y + 0.5;
		float x = lp.x + 0.5;
		// fine print fades out when it gets smaller than a pixel (no shimmer)
		float detail = 1.0 - smoothstep(0.004, 0.018, fwidth(y));
		float gold = step(0.45, h(s * 3.1));
		float band = (step(0.05, y) - step(0.085, y)) + (step(0.915, y) - step(0.95, y));
		c = mix(c, mix(base * 0.55, vec3(0.78, 0.62, 0.28), gold), band * detail);
		// title and author run along the spine (Portuguese style, top to bottom)
		float labelled = step(0.62, h(s * 5.7));
		float t0 = 0.30 + 0.12 * h(s * 1.7);
		float t1 = 0.80 - 0.06 * h(s * 2.3);
		float label = labelled * step(t0 - 0.05, y) * step(y, t1 + 0.05);
		c = mix(c, vec3(0.88, 0.84, 0.74), label * mix(0.45, 0.9, detail));
		vec3 ink = mix(mix(vec3(0.85, 0.78, 0.6), vec3(0.95, 0.93, 0.88), step(0.5, h(s * 8.3))), vec3(0.1, 0.09, 0.08), labelled);
		float tw = 0.16 + 0.14 * h(s * 4.1);
		float title = step(abs(x - 0.5), tw) * step(t0 + 0.12 * h(s * 6.6), y) * step(y, t1);
		float author = step(abs(x - 0.5), tw * 0.7) * step(0.16, y) * step(y, t0 - 0.06) * step(0.3, h(s * 7.7));
		float logo = step(abs(x - 0.5), 0.18) * step(0.07, y) * step(y, 0.11) * step(0.4, h(s * 2.9));
		float txt = clamp(title + author * 0.8 + logo, 0.0, 1.0);
		c = mix(c, ink, txt * 0.65 * detail);
		c *= 1.0 - 0.12 * detail * h(floor(y * 24.0) * 7.0 + s);
		rough = mix(0.55, 0.8, h(s * 9.1));
	} else {
		c = base * 0.88;
	}
	ALBEDO = c;
	ROUGHNESS = rough;
}"""
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	return _mat


## A wooden shelf unit `w` wide, `h` tall, `d` deep, its front-bottom-centre
## at `origin`, facing `yaw` (0 = books face +Z). `rows` shelf heights from
## the bottom (metres); the books are generated to fit. Returns the unit.
static func unit(parent: Node3D, origin: Vector3, yaw: float, w: float, h: float, d: float, rows: Array, wood: Material, rng: RandomNumberGenerator, fill := 0.92, collide := true) -> Node3D:
	var u := Node3D.new()
	u.position = origin
	u.rotation_degrees.y = yaw
	parent.add_child(u)
	var t := 0.03
	# carcass: sides, top, back, plinth and each shelf board
	WB.box(u, Vector3(-w / 2, 0, -d), Vector3(-w / 2 + t, h, 0), wood, false)
	WB.box(u, Vector3(w / 2 - t, 0, -d), Vector3(w / 2, h, 0), wood, false)
	WB.box(u, Vector3(-w / 2, h - t, -d), Vector3(w / 2, h, 0.01), wood, false)
	WB.box(u, Vector3(-w / 2, 0, -d), Vector3(w / 2, h, -d + 0.012), wood, false)
	WB.box(u, Vector3(-w / 2 + t, 0, -d + 0.01), Vector3(w / 2 - t, 0.08, 0.0), wood, false)
	var boards: Array = [0.08] + rows
	for y in rows:
		WB.box(u, Vector3(-w / 2 + t, y - 0.022, -d + 0.012), Vector3(w / 2 - t, y, 0.0), wood, false)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(w, h, d)
		cs.shape = sh
		cs.position = Vector3(0, h / 2, -d / 2)
		sb.add_child(cs)
		u.add_child(sb)
	# books
	var xf: Array = []
	var cols: Array = []
	var cust: Array = []
	var tops: Array = rows + [h - t]
	for i in boards.size():
		var y0: float = boards[i]
		var clear: float = float(tops[i]) - y0 - 0.025
		if clear < 0.16:
			continue
		_fill_row(xf, cols, cust, -w / 2 + t + 0.01, w / 2 - t - 0.01, y0, clear, d - 0.03, rng, fill)
	if xf.is_empty():
		return u
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = Vector3.ONE
	mm.mesh = _mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
		mm.set_instance_custom_data(i, cust[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material()
	u.add_child(mmi)
	u.set_meta("books", xf.size())
	return u


static func _fill_row(xf: Array, cols: Array, cust: Array, x0: float, x1: float, y0: float, clear: float, depth: float, rng: RandomNumberGenerator, fill: float) -> void:
	var x := x0
	var lean := 0.0
	while x < x1 - 0.02:
		var r := rng.randf()
		if r > fill:
			x += rng.randf_range(0.03, 0.16)        # a gap
			lean = rng.randf_range(4.0, 12.0) if rng.randf() < 0.5 else 0.0
			continue
		if r < 0.06 and x1 - x > 0.3:
			# a little stack lying flat
			var n := rng.randi_range(2, 5)
			var sw := rng.randf_range(0.18, 0.26)
			var yy := y0
			for k in n:
				var th := rng.randf_range(0.02, 0.045)
				var sd := minf(rng.randf_range(0.13, 0.2), depth)
				_add(xf, cols, cust, Vector3(x + sw / 2, yy + th / 2, -sd / 2 - 0.01), Vector3(th, sd, sw), Vector3(0, rng.randf_range(-6, 6), 90), rng)
				yy += th
				if yy > y0 + clear - 0.05:
					break
			x += sw + 0.01
			continue
		var t := rng.randf_range(0.016, 0.055)
		var bh := minf(rng.randf_range(0.17, 0.31), clear)
		var bd := minf(rng.randf_range(0.12, 0.23), depth)
		var rot := Vector3.ZERO
		if lean > 0.0:
			rot.z = lean
			lean = 0.0
		var front := -0.01 - rng.randf_range(0.0, 0.015)
		_add(xf, cols, cust, Vector3(x + t / 2, y0 + bh / 2, front - bd / 2), Vector3(t, bh, bd), rot, rng)
		x += t + rng.randf_range(0.0, 0.004)


static func _add(xf: Array, cols: Array, cust: Array, pos: Vector3, size: Vector3, rot_deg: Vector3, rng: RandomNumberGenerator) -> void:
	var b := Basis.from_euler(rot_deg * PI / 180.0)
	xf.append(Transform3D(b * Basis.from_scale(size), pos))
	var c: Color = PALETTE[rng.randi() % PALETTE.size()]
	c = c.darkened(rng.randf_range(0.0, 0.25)).lerp(Color(0.5, 0.45, 0.4), rng.randf_range(0.0, 0.2))
	cols.append(c)
	cust.append(Color(rng.randf(), rng.randf(), 0, 0))


## A loose pile of books on a table or the floor (for displays).
static func pile(parent: Node3D, at: Vector3, n: int, rng: RandomNumberGenerator, spread := 0.0) -> MultiMeshInstance3D:
	var xf: Array = []
	var cols: Array = []
	var cust: Array = []
	var y := at.y
	for i in n:
		var th := rng.randf_range(0.02, 0.05)
		var w := rng.randf_range(0.14, 0.2)
		var l := rng.randf_range(0.2, 0.26)
		var off := Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread, spread))
		_add(xf, cols, cust, Vector3(at.x, y + th / 2, at.z) + off, Vector3(th, l, w), Vector3(0, rng.randf_range(-15, 15), 90), rng)
		y += th
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	if _mesh == null:
		_mesh = BoxMesh.new()
		_mesh.size = Vector3.ONE
	mm.mesh = _mesh
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
		mm.set_instance_custom_data(i, cust[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material()
	parent.add_child(mmi)
	return mmi
