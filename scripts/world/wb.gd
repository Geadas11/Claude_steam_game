class_name WB
## World-building helpers: PBR materials from the Poly Haven textures, boxes
## with collision, walls with door/window holes, and glTF props.

const TEX := "res://assets/3d/textures/%s/%s.jpg"
const MODEL := "res://assets/3d/models/%s/%s.gltf"

static var _mats := {}
static var _models := {}


## A tiling PBR material in world space (triplanar), `tile` metres per repeat.
static func mat(tex_id: String, tile := 1.0, tint := Color.WHITE, rough_mul := 1.0) -> Material:
	var key := "%s|%s|%s|%s" % [tex_id, tile, tint, rough_mul]
	if _mats.has(key):
		return _mats[key]
	var m := ORMMaterial3D.new()
	m.albedo_texture = load(TEX % [tex_id, "diff"])
	m.albedo_color = tint
	if ResourceLoader.exists(TEX % [tex_id, "nor"]):
		m.normal_enabled = true
		m.normal_texture = load(TEX % [tex_id, "nor"])
	if ResourceLoader.exists(TEX % [tex_id, "arm"]):
		m.orm_texture = load(TEX % [tex_id, "arm"])
	m.roughness = rough_mul
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 8.0
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


## A plain material (painted wood, plastic, ceramic, glass...).
## Not quite flat: the colour is the one asked for, but the surface gets the
## relief of a real material (metal plate, linen, painted wood grain) so it
## doesn't read as clean CG plastic. Glossy things (porcelain, chrome) stay smooth.
static func flat(color: Color, roughness := 0.6, metallic := 0.0) -> StandardMaterial3D:
	var key := "flat|%s|%s|%s" % [color, roughness, metallic]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		var detail := ""
		var tile := 1.0
		var depth := 0.3
		if metallic >= 0.5:
			detail = "acg_brushed_steel"
			tile = 0.6
			depth = 0.5
		elif roughness >= 0.85:
			detail = "acg_linen"
			tile = 0.3
			depth = 0.8
		elif roughness > 0.25:
			detail = "acg_paint"
			tile = 1.0
			depth = 0.6
		if detail != "" and ResourceLoader.exists(TEX % [detail, "nor"]):
			m.normal_enabled = true
			m.normal_texture = load(TEX % [detail, "nor"])
			m.normal_scale = depth
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_triplanar_sharpness = 8.0
			m.uv1_scale = Vector3.ONE / tile
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


static func emissive(color: Color, energy := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.BLACK
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func glass() -> StandardMaterial3D:
	if _mats.has("glass"):
		return _mats.glass
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.62, 0.68, 0.12)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic = 0.2
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats.glass = m
	return m


## A box from `a` to `b` (any two opposite corners). Static collision unless
## collide is false.
## Furniture-sized boxes get their edges chamfered (a centimetre or less) so
## light catches them like a real object; big slabs and walls stay sharp.
## bevel < 0: automatic, 0: none, > 0: that radius.
static func box(parent: Node3D, a: Vector3, b: Vector3, material: Material, collide := true, name := "", bevel := -1.0) -> MeshInstance3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var size := hi - lo
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
	var mn := minf(size.x, minf(size.y, size.z))
	var mx := maxf(size.x, maxf(size.y, size.z))
	var r := bevel
	if r < 0.0:
		r = clampf(mn * 0.22, 0.0, 0.012) if mx < 2.6 and mn > 0.008 else 0.0
	if r > 0.0005:
		mi.mesh = chamfered_box(size, r)
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
	mi.material_override = material
	mi.position = (lo + hi) / 2.0
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


## A cabinet that reads as one: the carcass from `lo` to `hi`, its front
## facing `front` (±X or ±Z); `doors` door fronts with 3 mm gaps, a row of
## drawers on top when `drawer_h` > 0, a recessed plinth when it stands on
## the floor, and bar handles. Kitchens, counters, lockers, sideboards.
static func cabinet(parent: Node3D, lo: Vector3, hi: Vector3, front: Vector3, body: Material, face: Material, doors := 2, drawer_h := 0.0, handle: Material = null, vertical_handles := true, with_handles := true) -> void:
	var gap := 0.003
	var proud := 0.018
	if handle == null:
		handle = flat(Color(0.72, 0.72, 0.7), 0.3, 0.9)
	var along_x := absf(front.z) > 0.5          # the front runs along X
	var plinth := 0.09 if lo.y < 0.05 else 0.0
	var inset := 0.05
	# carcass, with the plinth recessed under it
	var c_lo := lo
	var c_hi := hi
	if front.x > 0.5:
		c_hi.x -= proud
	elif front.x < -0.5:
		c_lo.x += proud
	elif front.z > 0.5:
		c_hi.z -= proud
	else:
		c_lo.z += proud
	box(parent, Vector3(c_lo.x, c_lo.y + plinth, c_lo.z), c_hi, body)
	if plinth > 0.0:
		var p_lo := c_lo
		var p_hi := Vector3(c_hi.x, c_lo.y + plinth, c_hi.z)
		if front.x > 0.5:
			p_hi.x -= inset
		elif front.x < -0.5:
			p_lo.x += inset
		elif front.z > 0.5:
			p_hi.z -= inset
		else:
			p_lo.z += inset
		box(parent, p_lo, p_hi, flat(Color(0.08, 0.08, 0.08), 0.6), false)
	# the front plane and the span along it
	var f0: float
	var f1: float
	if front.x > 0.5:
		f0 = c_hi.x
		f1 = hi.x
	elif front.x < -0.5:
		f0 = lo.x
		f1 = c_lo.x
	elif front.z > 0.5:
		f0 = c_hi.z
		f1 = hi.z
	else:
		f0 = lo.z
		f1 = c_lo.z
	var s0 := lo.x if along_x else lo.z
	var s1 := hi.x if along_x else hi.z
	var y0 := lo.y + plinth
	var y1 := hi.y
	var rows: Array = []   # [y0, y1, count, is_drawer]
	if drawer_h > 0.0:
		rows.append([y1 - drawer_h, y1, maxi(doors, 1), true])
		rows.append([y0, y1 - drawer_h, doors, false])
	else:
		rows.append([y0, y1, doors, false])
	for r in rows:
		var n: int = r[2]
		if n <= 0:
			continue
		var w := (s1 - s0) / n
		for k in n:
			var a0 := s0 + k * w + gap
			var a1 := s0 + (k + 1) * w - gap
			var b0: float = r[0] + gap
			var b1: float = r[1] - gap
			var pa: Vector3
			var pb: Vector3
			if along_x:
				pa = Vector3(a0, b0, f0)
				pb = Vector3(a1, b1, f1)
			else:
				pa = Vector3(f0, b0, a0)
				pb = Vector3(f1, b1, a1)
			box(parent, pa, pb, face, false, "", 0.004)
			if not with_handles:
				continue
			# the handle: a short bar, near the top edge (drawers) or the opening side
			var out := front * 0.022
			var hc: Vector3
			var hs: Vector3
			if r[3] or not vertical_handles:
				var mid := (a0 + a1) / 2.0
				var hy: float = (b1 - 0.05) if not r[3] else (b0 + b1) / 2.0
				hc = Vector3(mid, hy, (f0 + f1) / 2.0) if along_x else Vector3((f0 + f1) / 2.0, hy, mid)
				hs = Vector3(minf(0.16, (a1 - a0) * 0.5), 0.012, 0.012) if along_x else Vector3(0.012, 0.012, minf(0.16, (a1 - a0) * 0.5))
			else:
				var side := a1 - 0.045 if k % 2 == 0 else a0 + 0.045
				var hy2 := clampf(b1 - 0.12, b0 + 0.08, b1) if hi.y < 1.2 else clampf(b0 + 0.12, b0, b1)
				hc = Vector3(side, hy2, (f0 + f1) / 2.0) if along_x else Vector3((f0 + f1) / 2.0, hy2, side)
				hs = Vector3(0.012, 0.13, 0.012)
			hc += out
			box(parent, hc - hs / 2.0, hc + hs / 2.0, handle, false, "", 0.0)


## A worktop slab over cabinets, with a little overhang at the front.
static func worktop(parent: Node3D, lo: Vector3, hi: Vector3, front: Vector3, material: Material, thick := 0.035) -> void:
	var a := Vector3(lo.x, hi.y, lo.z)
	var b := Vector3(hi.x, hi.y + thick, hi.z)
	if front.x > 0.5:
		b.x += 0.025
	elif front.x < -0.5:
		a.x -= 0.025
	elif front.z > 0.5:
		b.z += 0.025
	else:
		a.z -= 0.025
	box(parent, a, b, material, true, "", 0.006)


static var _chamfers := {}


## A box mesh of `size` with every edge cut at 45° by `r` (6 faces, 12 bevels,
## 8 corner triangles), flat-shaded, with planar UVs. Cached by size.
static func chamfered_box(size: Vector3, r: float) -> ArrayMesh:
	var key := "%s|%s" % [size.snapped(Vector3.ONE * 0.0005), snappedf(r, 0.0005)]
	if _chamfers.has(key):
		return _chamfers[key]
	var h := size / 2.0
	var i := h - Vector3.ONE * r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad := func(p: Array, n: Vector3) -> void:
		_tri(st, p[0], p[1], p[2], n)
		_tri(st, p[0], p[2], p[3], n)
	for ax in 3:
		var b := (ax + 1) % 3
		var c := (ax + 2) % 3
		for sa in [-1.0, 1.0]:
			# the main face
			var f: Array = []
			for q in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
				var v := Vector3.ZERO
				v[ax] = sa * h[ax]
				v[b] = q[0] * i[b]
				v[c] = q[1] * i[c]
				f.append(v)
			var n := Vector3.ZERO
			n[ax] = sa
			quad.call(f, n)
			# the bevel between this face and the next axis' faces
			for sb in [-1.0, 1.0]:
				var e: Array = []
				for sc in [-1.0, 1.0]:
					var p1 := Vector3.ZERO
					p1[ax] = sa * h[ax]
					p1[b] = sb * i[b]
					p1[c] = sc * i[c]
					var p2 := Vector3.ZERO
					p2[ax] = sa * i[ax]
					p2[b] = sb * h[b]
					p2[c] = sc * i[c]
					e.append(p1)
					e.append(p2)
				var ne := Vector3.ZERO
				ne[ax] = sa
				ne[b] = sb
				quad.call([e[0], e[1], e[3], e[2]], ne.normalized())
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_tri(st, Vector3(sx * h.x, sy * i.y, sz * i.z), Vector3(sx * i.x, sy * h.y, sz * i.z), Vector3(sx * i.x, sy * i.y, sz * h.z), Vector3(sx, sy, sz).normalized())
	st.generate_tangents()
	var m := st.commit()
	_chamfers[key] = m
	return m


## One triangle facing `n` (Godot's front faces wind clockwise), planar UVs.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	var ax := n.abs()
	for v in [a, b, c]:
		var uv := Vector2(v.z, -v.y) if ax.x >= ax.y and ax.x >= ax.z else (Vector2(v.x, v.z) if ax.y >= ax.z else Vector2(v.x, -v.y))
		st.set_normal(n)
		st.set_uv(uv)
		st.add_vertex(v)


## A wall along X (axis "x") or Z (axis "z") from `from` to `to` at the line
## `at`, `thick` metres thick, with rectangular holes:
## holes = [[start, end, bottom, top], ...] measured along the wall.
static func wall(parent: Node3D, axis: String, at: float, from: float, to: float, height: float, thick: float, material: Material, holes: Array = []) -> void:
	# cut the wall into vertical strips at every hole edge, then, in each strip,
	# keep what is not covered by any hole (holes may overlap along the wall)
	var edges := [from, to]
	for h in holes:
		edges.append(clampf(h[0], from, to))
		edges.append(clampf(h[1], from, to))
	edges.sort()
	var pieces: Array = []   # [s, e, y0, y1]
	for k in edges.size() - 1:
		var s0: float = edges[k]
		var s1: float = edges[k + 1]
		if s1 - s0 < 0.0005:
			continue
		var mid := (s0 + s1) / 2.0
		var gaps: Array = []
		for h in holes:
			if h[0] < mid and mid < h[1]:
				gaps.append([maxf(0.0, h[2]), minf(height, h[3])])
		gaps.sort_custom(func(a, b): return a[0] < b[0])
		var y := 0.0
		for g in gaps:
			if g[0] > y:
				pieces.append([s0, s1, y, g[0]])
			y = maxf(y, g[1])
		if y < height:
			pieces.append([s0, s1, y, height])
	for p in pieces:
		if axis == "x":
			box(parent, Vector3(p[0], p[2], at - thick / 2), Vector3(p[1], p[3], at + thick / 2), material, true, "", 0.0)
		else:
			box(parent, Vector3(at - thick / 2, p[2], p[0]), Vector3(at + thick / 2, p[3], p[1]), material, true, "", 0.0)


## A Poly Haven glTF model turned `rot_deg` around Y and scaled, placed so
## its footprint is centred on (x, z) and its bottom sits at `y`.
## With collide, a box collider from its bounds is added.
static func model(parent: Node3D, id: String, x: float, z: float, rot_deg := 0.0, scale := 1.0, y := 0.0, collide := true) -> Node3D:
	var ps: PackedScene = _models.get(id)
	if ps == null:
		ps = load(MODEL % [id, id])
		_models[id] = ps
	var n: Node3D = ps.instantiate()
	n.name = id
	n.rotation_degrees.y = rot_deg
	n.scale = Vector3.ONE * scale
	parent.add_child(n)
	var lb := local_bounds(n)
	var fb: AABB = Transform3D(n.transform.basis, Vector3.ZERO) * lb
	n.position = Vector3(x - (fb.position.x + fb.size.x / 2.0), y - fb.position.y, z - (fb.position.z + fb.size.z / 2.0))
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = lb.size
		cs.shape = sh
		cs.position = lb.position + lb.size / 2.0
		sb.add_child(cs)
		n.add_child(sb)
	return n


## Footprint of a placed model in its parent's space.
static func footprint(n: Node3D) -> AABB:
	return n.transform * local_bounds(n)


## Bounds of all meshes under `n`, in n's own (unscaled) space.
static func local_bounds(n: Node3D) -> AABB:
	var acc: Array = [null]
	for c in n.get_children():
		_acc_bounds(c, Transform3D(), acc)
	return acc[0] if acc[0] != null else AABB()


static func _acc_bounds(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and n.mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_acc_bounds(c, t, acc)


static func omni(parent: Node3D, pos: Vector3, color: Color, energy: float, rng: float, shadow := true) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.light_volumetric_fog_energy = 0.6
	parent.add_child(l)
	return l


## Painted or printed text in the world (shop signs, notices, chalkboards).
static func text(parent: Node3D, t: String, pos: Vector3, yaw: float, size := 0.1, color := Color(0.9, 0.88, 0.8), outline := 0) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.position = pos
	l.rotation_degrees.y = yaw
	l.pixel_size = size / 64.0
	l.font_size = 64
	l.modulate = color
	l.outline_size = outline
	l.shaded = true
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	parent.add_child(l)
	return l


## A ceiling pendant with a cloth/glass shade and a warm bulb, as a room light.
static func pendant(loc: Location, room: String, ceiling: Vector3, drop: float, energy: float, rng: float, shade_color := Color(0.85, 0.8, 0.65)) -> OmniLight3D:
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.005
	cm.bottom_radius = 0.005
	cm.height = drop
	cord.mesh = cm
	cord.material_override = flat(Color(0.05, 0.05, 0.05), 0.6)
	cord.position = ceiling - Vector3(0, drop / 2, 0)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	loc.add_child(cord)
	var shade := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.07
	sm.bottom_radius = 0.2
	sm.height = 0.18
	sm.cap_bottom = false
	shade.mesh = sm
	var sh_mat := StandardMaterial3D.new()
	sh_mat.albedo_color = shade_color
	sh_mat.roughness = 0.7
	sh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shade.material_override = sh_mat
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shade.position = ceiling - Vector3(0, drop + 0.09, 0)
	loc.add_child(shade)
	var glow := emissive(Color(1.0, 0.78, 0.5), 0.0)
	var g := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.04
	gm.height = 0.08
	g.mesh = gm
	g.material_override = glow
	g.position = ceiling - Vector3(0, drop + 0.14, 0)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	loc.add_child(g)
	var l := omni(loc, ceiling - Vector3(0, drop + 0.22, 0), Color(1.0, 0.8, 0.58), energy, rng, true)
	loc._room(room, [l], [glow])
	return l


## A tiled material drawn in code: square tiles of `tile` metres with joint
## lines (suspended ceilings, hospital floors).
static func grid(color: Color, line: Color, tile := 0.6, rough := 0.8, line_px := 3) -> StandardMaterial3D:
	# 4x4 tiles per texture so each one can differ a little; the grout is
	# recessed in a normal map so light catches the tile edges
	var key := "grid|%s|%s|%s" % [color, line, tile]
	if _mats.has(key):
		return _mats[key]
	var n := 4
	var px := 64
	var size := n * px
	var g := maxi(2, line_px * 2)
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var hgt := PackedFloat32Array()
	hgt.resize(size * size)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	for ty in n:
		for tx in n:
			var c := color.lerp(color.darkened(0.08) if rng.randf() < 0.5 else color.lightened(0.05), rng.randf_range(0.0, 0.6))
			for y in px:
				for x in px:
					var gx := mini(x, px - 1 - x)
					var gy := mini(y, px - 1 - y)
					var d := mini(gx, gy)
					var h := clampf(float(d - g / 2) / 3.0, 0.0, 1.0)
					var X := tx * px + x
					var Y := ty * px + y
					img.set_pixel(X, Y, line if d < g / 2 else c)
					hgt[Y * size + X] = h
	var nimg := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var dx := hgt[y * size + (x + 1) % size] - hgt[y * size + (x - 1 + size) % size]
			var dy := hgt[((y + 1) % size) * size + x] - hgt[((y - 1 + size) % size) * size + x]
			var nv := Vector3(-dx * 1.5, -dy * 1.5, 1.0).normalized()
			nimg.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	img.generate_mipmaps()
	nimg.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(nimg)
	m.normal_scale = 0.8 if tile < 0.3 else 0.35   # big tiles (ceilings, vinyl): shallow joints
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / (tile * n)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


## A glowing sign (exit signs, room numbers lit from behind).
static func sign(parent: Node3D, t: String, pos: Vector3, yaw: float, bg: Color, fg: Color, w := 0.36, h := 0.14) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = yaw
	parent.add_child(holder)
	box(holder, Vector3(-w / 2, -h / 2, -0.02), Vector3(w / 2, h / 2, 0.0), emissive(bg, 1.6), false)
	text(holder, t, Vector3(0, 0, 0.003), 0.0, h * 0.55, fg)
