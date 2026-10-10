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
static func box(parent: Node3D, a: Vector3, b: Vector3, material: Material, collide := true, name := "") -> MeshInstance3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var size := hi - lo
	var mi := MeshInstance3D.new()
	if name != "":
		mi.name = name
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
			box(parent, Vector3(p[0], p[2], at - thick / 2), Vector3(p[1], p[3], at + thick / 2), material)
		else:
			box(parent, Vector3(at - thick / 2, p[2], p[0]), Vector3(at + thick / 2, p[3], p[1]), material)


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
