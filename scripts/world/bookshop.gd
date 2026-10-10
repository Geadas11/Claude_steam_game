class_name Bookshop
extends Location
## Livraria Maré, Rua do Cais 31, Salgueira. A narrow old bookshop with a
## wooden gallery on three sides, a staircase in the middle, books from the
## floor to the ceiling, the counter with the old register, Carla's office
## and the storeroom at the back. The shop window looks onto the street.
##
##   hall x0..7.5 z0..11 (street at z<0), ceiling 5.0, gallery at 2.7–2.85
##   office x0..3.4 z11..13.6 · storeroom x4..7.5 z11..13.6

const H := 5.0
const EXT := 0.3
const INT := 0.12
const GAL := 2.85            # gallery floor (walkable height)
const STREET_SODIUM := Color(1.0, 0.6, 0.28)

var rng := RandomNumberGenerator.new()
var street_lights: Array[SpotLight3D] = []
var sky_fills: Array[OmniLight3D] = []
var lit_windows: Array[StandardMaterial3D] = []
var moon: DirectionalLight3D
var shelf_wood: Material
var chandelier: Node3D
var fallen_books: Array[Node3D] = []


func _ready() -> void:
	load_texts("livraria")
	rng.seed = 31
	m_wall = WB.mat("plastered_wall_04", 2.5, Color(0.42, 0.5, 0.44))
	m_ceiling = WB.mat("roof_planks", 1.8, Color(0.55, 0.45, 0.36))
	m_paint = WB.flat(Color(0.2, 0.26, 0.22), 0.5)
	m_skirt = WB.flat(Color(0.16, 0.12, 0.09), 0.5)
	shelf_wood = WB.mat("dark_wood", 1.2, Color(0.62, 0.5, 0.4))
	_build_shell()
	_build_gallery()
	_build_stairs()
	_build_shelves()
	_build_counter()
	_build_floor_furniture()
	_build_office()
	_build_storeroom()
	_build_lights()
	_build_outside()
	_build_story_hooks()
	set_room_light("loja", true)
	set_room_light("galeria", true)


# =================================================================== shell
func _build_shell() -> void:
	var floor := WB.mat("dark_wooden_planks", 1.4, Color(0.8, 0.72, 0.64))
	WB.box(self, Vector3(0, -0.1, 0), Vector3(7.5, 0, 11), floor)
	WB.box(self, Vector3(0, -0.1, 11), Vector3(7.5, 0, 13.6), floor)
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(7.5 + EXT, H + 0.15, 13.6 + EXT), m_ceiling)
	# ceiling beams across the hall
	var beam := WB.mat("dark_wood", 1.0, Color(0.4, 0.3, 0.22))
	for z in [1.5, 3.5, 5.5, 7.5, 9.5]:
		WB.box(self, Vector3(0, H - 0.22, z - 0.09), Vector3(7.5, H, z + 0.09), beam, false)
	var window := [2.8, 7.0, 0.55, 3.0]
	var door := [0.8, 2.2, 0.0, 2.7]
	var clerestory := [3.0, 6.8, 3.5, 4.5]
	WB.wall(self, "x", -EXT / 2, -EXT, 7.5 + EXT, H, EXT, m_wall, [window, door, clerestory])
	WB.wall(self, "x", 13.6 + EXT / 2, -EXT, 7.5 + EXT, H, EXT, m_wall)
	WB.wall(self, "z", -EXT / 2, 0, 13.6, H, EXT, m_wall)
	WB.wall(self, "z", 7.5 + EXT / 2, 0, 13.6, H, EXT, m_wall)
	# back wall of the hall, with the office and storeroom doors
	var d_off := [0.9, 1.8, 0.0, 2.1]
	var d_sto := [5.6, 6.5, 0.0, 2.1]
	WB.wall(self, "x", 11.0, 0, 7.5, 2.7, INT, m_wall, [d_off, d_sto])
	WB.wall(self, "z", 3.7, 11.0, 13.6, H, INT, m_wall)
	_skirting()
	# shop window and clerestory glass, with dark wooden frames
	_window(window, true)
	_window(clerestory, false)
	_frame(door)
	doors.rua = Door.make(self, Vector3(0.8, 0, 0.0), "x", 1.4, 2.7, WB.mat("dark_wood", 1.0, Color(0.32, 0.22, 0.16)), 1.0)
	WB.text(doors.rua.leaf, "FECHADO", Vector3(0.7, 1.55, 0.03), 0.0, 0.07, Color(0.85, 0.82, 0.7))
	doors.escritorio = Door.make(self, Vector3(0.9, 0, 11.0), "x", 0.9, 2.1, m_paint, -1.0)
	doors.arrecadacao = Door.make(self, Vector3(5.6, 0, 11.0), "x", 0.9, 2.1, m_paint, -1.0)
	room_bounds = {
		"loja": AABB(Vector3(0, 0, 0), Vector3(7.5, GAL, 11)),
		"galeria": AABB(Vector3(0, GAL - 0.2, 0), Vector3(7.5, H - GAL + 0.2, 11)),
		"escritorio": AABB(Vector3(0, 0, 11), Vector3(3.7, H, 2.6)),
		"arrecadacao": AABB(Vector3(3.7, 0, 11), Vector3(3.8, H, 2.6)),
	}


func _skirting() -> void:
	WB.wall(self, "z", 0.0, 0, 11, 0.12, 0.03, m_skirt)
	WB.wall(self, "z", 7.5, 0, 11, 0.12, 0.03, m_skirt)


func _frame(hole: Array) -> void:
	var w := 0.09
	var dark := WB.mat("dark_wood", 1.0, Color(0.3, 0.2, 0.15))
	for p in [[hole[0] - w, hole[0], 0.0, hole[3] + w], [hole[1], hole[1] + w, 0.0, hole[3] + w], [hole[0], hole[1], hole[3], hole[3] + w]]:
		WB.box(self, Vector3(p[0], p[2], -0.33), Vector3(p[1], p[3], 0.03), dark, false)


func _window(hole: Array, low: bool) -> void:
	var x0: float = hole[0]
	var x1: float = hole[1]
	var y0: float = hole[2]
	var y1: float = hole[3]
	var dark := WB.mat("dark_wood", 1.0, Color(0.3, 0.2, 0.15))
	var fw := 0.07
	var bars := [[x0, x0 + fw, y0, y1], [x1 - fw, x1, y0, y1], [x0, x1, y0, y0 + fw], [x0, x1, y1 - fw, y1]]
	var n := 3 if low else 4
	for i in range(1, n):
		var x := x0 + (x1 - x0) * i / n
		bars.append([x - 0.035, x + 0.035, y0, y1])
	if low:
		bars.append([x0, x1, 2.35, 2.42])
	for p in bars:
		WB.box(self, Vector3(p[0], p[2], -0.2), Vector3(p[1], p[3], -0.1), dark, false)
	WB.box(self, Vector3(x0 + fw, y0 + fw, -0.155), Vector3(x1 - fw, y1 - fw, -0.145), WB.glass(), true)
	if low:
		# the sill of the display, and daylight coming in
		WB.box(self, Vector3(x0, 0, 0.0), Vector3(x1, 0.5, 0.9), WB.mat("dark_wood", 1.0, Color(0.36, 0.26, 0.18)))
		for i in 7:
			Books.pile(self, Vector3(x0 + 0.35 + i * 0.55, 0.5, 0.45 + rng.randf_range(-0.15, 0.15)), rng.randi_range(2, 6), rng, 0.02)
	var fill := WB.omni(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, 0.9), Color(0.78, 0.84, 0.95), 0.0, 7.0, false)
	fill.set_meta("base", 2.0 if low else 1.0)
	fill.visible = false
	sky_fills.append(fill)


# =================================================================== gallery
func _build_gallery() -> void:
	var floor := WB.mat("dark_wooden_planks", 1.4, Color(0.75, 0.66, 0.58))
	var under := WB.mat("dark_wood", 1.2, Color(0.45, 0.34, 0.26))
	# slabs: left, right, back
	for r in [[0, 2.5, 1.35, 11.0], [6.15, 2.5, 7.5, 11.0], [1.35, 9.65, 6.15, 11.0]]:
		WB.box(self, Vector3(r[0], 2.7, r[1]), Vector3(r[2], GAL, r[3]), floor)
		WB.box(self, Vector3(r[0], 2.66, r[1]), Vector3(r[2], 2.7, r[3]), under, false)
	# posts under the inner corners
	for p in [Vector2(1.35, 2.5), Vector2(1.35, 6.0), Vector2(1.35, 9.65), Vector2(6.15, 2.5), Vector2(6.15, 6.0), Vector2(6.15, 9.65)]:
		WB.box(self, Vector3(p.x - 0.08, 0, p.y - 0.08), Vector3(p.x + 0.08, 2.7, p.y + 0.08), under)
	# railings along the inner edges (gap for the stairs on the back)
	_railing(Vector3(1.35, GAL, 2.5), Vector3(1.35, GAL, 9.65))
	_railing(Vector3(6.15, GAL, 2.5), Vector3(6.15, GAL, 9.65))
	_railing(Vector3(0.0, GAL, 2.5), Vector3(1.35, GAL, 2.5))
	_railing(Vector3(6.15, GAL, 2.5), Vector3(7.5, GAL, 2.5))
	_railing(Vector3(1.35, GAL, 9.65), Vector3(3.05, GAL, 9.65))
	_railing(Vector3(4.45, GAL, 9.65), Vector3(6.15, GAL, 9.65))


func _railing(a: Vector3, b: Vector3) -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.38, 0.27, 0.2))
	var len := a.distance_to(b)
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var lo := Vector3(minf(a.x, b.x), a.y, minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), a.y, maxf(a.z, b.z))
	var t := 0.035
	# handrail and bottom rail
	if along_x:
		WB.box(self, Vector3(lo.x, a.y + 0.95, lo.z - 0.045), Vector3(hi.x, a.y + 1.0, lo.z + 0.045), wood, false)
		WB.box(self, Vector3(lo.x, a.y + 0.06, lo.z - t), Vector3(hi.x, a.y + 0.1, lo.z + t), wood, false)
	else:
		WB.box(self, Vector3(lo.x - 0.045, a.y + 0.95, lo.z), Vector3(lo.x + 0.045, a.y + 1.0, hi.z), wood, false)
		WB.box(self, Vector3(lo.x - t, a.y + 0.06, lo.z), Vector3(lo.x + t, a.y + 0.1, hi.z), wood, false)
	# turned balusters (one MultiMesh per run)
	var n := int(len / 0.14)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cm := CylinderMesh.new()
	cm.top_radius = 0.016
	cm.bottom_radius = 0.022
	cm.height = 0.85
	cm.radial_segments = 8
	mm.mesh = cm
	mm.instance_count = n
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.525, 0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = wood
	add_child(mmi)
	# one collider for the whole run
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(len if along_x else 0.1, 1.0, 0.1 if along_x else len)
	cs.shape = sh
	cs.position = (a + b) / 2 + Vector3(0, 0.5, 0)
	sb.add_child(cs)
	add_child(sb)


func _build_stairs() -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.5, 0.38, 0.28))
	var tread := WB.mat("dark_wooden_planks", 1.0, Color(0.7, 0.6, 0.5))
	var steps := 16
	var z0 := 5.4
	var z1 := 9.65
	var run := (z1 - z0) / steps
	var rise := GAL / steps
	for i in steps:
		var z := z0 + i * run
		WB.box(self, Vector3(3.1, 0, z), Vector3(4.4, (i + 1) * rise - 0.03, z + run), wood, false)
		WB.box(self, Vector3(3.08, (i + 1) * rise - 0.03, z - 0.02), Vector3(4.42, (i + 1) * rise, z + run), tread, false)
	# a ramp the feet actually walk on (steps are only for the eyes)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var length := Vector2(z1 - z0, GAL).length()
	sh.size = Vector3(1.3, 0.1, length)
	cs.shape = sh
	cs.position = Vector3(3.75, GAL / 2 - 0.02, (z0 + z1) / 2)
	cs.rotation.x = -atan2(GAL, z1 - z0)
	sb.add_child(cs)
	add_child(sb)
	# side rails
	for x in [3.1, 4.4]:
		var rail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.06, 0.06, length)
		rail.mesh = bm
		rail.material_override = wood
		rail.position = Vector3(x, GAL / 2 + 0.95, (z0 + z1) / 2)
		rail.rotation.x = -atan2(GAL, z1 - z0)
		add_child(rail)
		for k in 9:
			var f := (k + 0.5) / 9.0
			var post := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.016
			pm.bottom_radius = 0.02
			pm.height = 0.9
			post.mesh = pm
			post.material_override = wood
			post.position = Vector3(x, f * GAL + 0.48, z0 + f * (z1 - z0))
			add_child(post)


# =================================================================== books
func _build_shelves() -> void:
	var low := [0.42, 0.78, 1.14, 1.5, 1.86, 2.22]
	var high := [0.36, 0.72, 1.08, 1.44, 1.8]
	# ground floor: left wall, right wall (behind the counter), back wall
	for i in 7:
		Books.unit(self, Vector3(0.36, 0, 2.95 + i), 90.0, 1.0, 2.6, 0.34, low, shelf_wood, rng)
	for i in 6:
		Books.unit(self, Vector3(7.14, 0, 4.55 + i), -90.0, 1.0, 2.6, 0.34, low, shelf_wood, rng)
	for x in [2.35, 3.45, 4.55]:
		Books.unit(self, Vector3(x, 0, 10.64), 180.0, 1.1, 2.6, 0.34, low, shelf_wood, rng)
	Books.unit(self, Vector3(7.0, 0, 10.64), 180.0, 0.9, 2.6, 0.34, low, shelf_wood, rng)
	# gallery: all three walls, up to the beams
	for i in 8:
		Books.unit(self, Vector3(0.36, GAL, 2.95 + i), 90.0, 1.0, 2.0, 0.34, high, shelf_wood, rng)
		Books.unit(self, Vector3(7.14, GAL, 2.95 + i), -90.0, 1.0, 2.0, 0.34, high, shelf_wood, rng)
	for i in 6:
		Books.unit(self, Vector3(1.0 + i * 1.1, GAL, 10.64), 180.0, 1.1, 2.0, 0.34, high, shelf_wood, rng)
	# front wall beside the door, low
	# section labels hung on the shelves
	for p in [[Vector3(0.38, 2.45, 4.0), 90.0, "LITERATURA PORTUGUESA"], [Vector3(0.38, 2.45, 7.5), 90.0, "POESIA"],
			[Vector3(7.12, 2.45, 6.0), -90.0, "HISTÓRIA · ALGARVE"], [Vector3(3.45, 2.45, 10.62), 180.0, "SARAMAGO"],
			[Vector3(1.0 + 2 * 1.1, GAL + 1.85, 10.62), 180.0, "PESSOA"]]:
		WB.text(self, p[2], p[0] + _out(p[1]) * 0.012, p[1], 0.05, Color(0.85, 0.78, 0.55))
	# the library ladder leaning on the left gallery
	WB.model(self, "wooden_ladder", 1.0, 5.5, 90.0, 1.3)


func _out(yaw: float) -> Vector3:
	return Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))


# =================================================================== counter
func _build_counter() -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.42, 0.3, 0.22))
	var top := WB.mat("dark_wooden_planks", 1.0, Color(0.6, 0.48, 0.38))
	# L-shaped counter facing the door
	WB.box(self, Vector3(4.6, 0, 3.6), Vector3(6.6, 0.95, 4.2), wood)
	WB.box(self, Vector3(6.0, 0, 4.2), Vector3(6.6, 0.95, 5.4), wood)
	WB.box(self, Vector3(4.55, 0.95, 3.55), Vector3(6.65, 1.0, 4.25), top, false)
	WB.box(self, Vector3(5.95, 0.95, 4.2), Vector3(6.65, 1.0, 5.45), top, false)
	# panels on the front face
	for x in [4.75, 5.35, 5.95]:
		WB.box(self, Vector3(x, 0.12, 3.585), Vector3(x + 0.5, 0.82, 3.6), WB.mat("dark_wood", 1.0, Color(0.36, 0.25, 0.18)), false)
	var reg := WB.model(self, "CashRegister_01", 5.2, 3.95, 180.0, 0.75, 1.0, false)
	hotspots.caixa = Hotspot.add(self, WB.footprint(reg).get_center(), WB.footprint(reg).size, _prompt("caixa"), func(p): _say("caixa", p))
	Books.pile(self, Vector3(4.85, 1.0, 3.9), 4, rng)
	Books.pile(self, Vector3(6.3, 1.0, 4.9), 6, rng)
	WB.model(self, "desk_lamp_arm_01", 6.35, 4.4, -150.0, 0.9, 1.0, false)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(6.2, 1.55, 4.3)
	lamp.rotation_degrees = Vector3(-70, 200, 0)
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.light_energy = 2.0
	lamp.spot_range = 3.0
	lamp.spot_angle = 50.0
	lamp.shadow_enabled = true
	add_child(lamp)
	_room("balcao", [lamp], [])
	WB.model(self, "wooden_stool_01", 5.4, 4.7, 0.0)
	hotspots.balcao = Hotspot.add(self, Vector3(5.6, 0.5, 3.9), Vector3(2.0, 1.0, 0.6), _prompt("balcao"), func(p): _say("balcao", p))
	_switch_plate("balcao", Vector3(6.62, 1.15, 5.0), -90.0, ["balcao"], "Acender o candeeiro do balcão")


# =================================================================== the floor of the shop
func _build_floor_furniture() -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.48, 0.36, 0.27))
	# two display tables with piles of new books
	for t in [Vector3(3.6, 0, 2.2), Vector3(2.6, 0, 4.4)]:
		WB.box(self, t + Vector3(-0.75, 0.74, -0.42), t + Vector3(0.75, 0.79, 0.42), wood)
		for lx in [-0.68, 0.62]:
			for lz in [-0.36, 0.3]:
				WB.box(self, t + Vector3(lx, 0, lz), t + Vector3(lx + 0.06, 0.74, lz + 0.06), wood, false)
		for i in 6:
			Books.pile(self, t + Vector3(-0.55 + (i % 3) * 0.55, 0.79, -0.18 + (i / 3) * 0.36), rng.randi_range(3, 8), rng, 0.01)
	hotspots.mesa = Hotspot.add(self, Vector3(3.6, 0.85, 2.2), Vector3(1.5, 0.3, 0.85), _prompt("mesa"), func(p): _say("mesa", p))
	# reading corner: rocking chair, side table, floor lamp, rug
	WB.box(self, Vector3(4.9, 0, 6.4), Vector3(6.1, 0.012, 8.2), WB.flat(Color(0.32, 0.12, 0.1), 0.95), false)
	var chair := WB.model(self, "Rockingchair_01", 5.5, 7.1, -120.0)
	hotspots.poltrona = Hotspot.add(self, WB.footprint(chair).get_center(), WB.footprint(chair).size, _prompt("poltrona"), func(p): _say("poltrona", p))
	WB.model(self, "side_table_01", 5.75, 8.1, 0.0)
	Books.pile(self, Vector3(5.75, 0.55, 8.1), 3, rng)
	WB.model(self, "magnifying_glass_01", 5.62, 8.18, 70.0, 1.0, 0.55 + 0.1, false).rotation_degrees.x = 90.0
	_floor_lamp(Vector3(5.1, 0, 8.0))
	WB.model(self, "potted_plant_02", 6.9, 1.0, 0.0)
	WB.model(self, "vintage_suitcase", 6.4, 0.6, 180.0, 0.6, 0.5, false)
	# the chalkboard on the pavement outside
	var board := WB.model(self, "standing_chalkboard_01", 1.9, -1.2, 160.0)
	WB.text(self, "SARAMAGO\n−20%\nesta semana", WB.footprint(board).get_center() + Vector3(0.05, 0.1, -0.24), 160.0 + 180.0, 0.06, Color(0.92, 0.92, 0.88))
	hotspots.quadro = Hotspot.add(self, WB.footprint(board).get_center(), WB.footprint(board).size, _prompt("quadro"), func(p): _say("quadro", p))


func _floor_lamp(at: Vector3) -> void:
	var metal := WB.flat(Color(0.15, 0.13, 0.1), 0.4, 0.8)
	WB.box(self, at + Vector3(-0.14, 0, -0.14), at + Vector3(0.14, 0.03, 0.14), metal, false)
	WB.box(self, at + Vector3(-0.012, 0.03, -0.012), at + Vector3(0.012, 1.45, 0.012), metal, false)
	var shade := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.13
	sm.bottom_radius = 0.2
	sm.height = 0.25
	sm.cap_top = false
	sm.cap_bottom = false
	shade.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.78, 0.62)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.backlight_enabled = true
	m.backlight = Color(0.6, 0.45, 0.25)
	shade.material_override = m
	shade.position = at + Vector3(0, 1.5, 0)
	add_child(shade)
	var l := WB.omni(self, at + Vector3(0, 1.45, 0), Color(1.0, 0.76, 0.5), 1.1, 4.0, true)
	_room("leitura", [l], [])
	hotspots.candeeiro = Hotspot.add(self, at + Vector3(0, 1.5, 0), Vector3(0.45, 0.35, 0.45), "Acender o candeeiro", func(_p):
		Audio.play("switch", -8.0)
		set_room_light("leitura", not rooms.leitura.on))
	hotspots.candeeiro.dynamic_prompt = func(): return "Apagar o candeeiro" if rooms.leitura.on else "Acender o candeeiro"


# =================================================================== back rooms
func _build_office() -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.5, 0.38, 0.28))
	# Carla's desk
	WB.box(self, Vector3(1.2, 0.74, 12.5), Vector3(2.8, 0.79, 13.3), wood)
	WB.box(self, Vector3(2.3, 0, 12.55), Vector3(2.78, 0.74, 13.28), wood, false)
	WB.box(self, Vector3(1.22, 0, 12.55), Vector3(1.3, 0.74, 13.28), wood, false)
	WB.model(self, "dining_chair_02", 1.8, 12.1, 180.0)
	WB.model(self, "binder_notebook", 2.1, 12.9, 20.0, 1.0, 0.79, false)
	Books.pile(self, Vector3(1.45, 0.79, 13.0), 7, rng)
	WB.model(self, "desk_lamp_arm_01", 2.55, 13.1, 200.0, 0.9, 0.79, false)
	var lamp := WB.omni(self, Vector3(2.4, 1.3, 12.9), Color(1.0, 0.78, 0.52), 1.0, 3.5, true)
	_room("escritorio", [lamp], [])
	WB.model(self, "painted_wooden_cabinet", 0.5, 12.3, 90.0, 0.9)
	WB.model(self, "vintage_telephone_wall_clock", 3.55, 12.4, -90.0, 1.0, 1.6, false)
	WB.model(self, "cardboard_box_01", 3.2, 11.5, 15.0)
	hotspots.secretaria = Hotspot.add(self, Vector3(2.0, 0.9, 12.9), Vector3(1.6, 0.3, 0.8), _prompt("secretaria"), func(p): _say("secretaria", p))
	_switch_plate("escritorio", Vector3(2.0, 1.2, 11.07), 0.0, ["escritorio"])


func _build_storeroom() -> void:
	WB.model(self, "steel_frame_shelves_03", 6.3, 13.2, 180.0, 0.9)
	WB.model(self, "steel_frame_shelves_03", 4.15, 12.4, 90.0, 0.9)
	for p in [Vector3(5.0, 0, 12.0), Vector3(5.35, 0, 12.15), Vector3(7.1, 0, 11.6)]:
		WB.model(self, "cardboard_box_01", p.x, p.z, rng.randf_range(-20, 20))
	WB.model(self, "cardboard_box_01", 5.15, 12.05, 30.0, 0.9, 0.34, false)
	WB.model(self, "trashbag", 7.0, 12.6, 40.0)
	var bulb := WB.omni(self, Vector3(5.8, 2.4, 12.3), Color(1.0, 0.82, 0.6), 0.8, 4.0, true)
	_room("arrecadacao", [bulb], [])
	_switch_plate("arrecadacao", Vector3(6.7, 1.2, 11.07), 0.0, ["arrecadacao"])


# =================================================================== lights
func _build_lights() -> void:
	# the brass chandelier in the middle of the hall
	chandelier = WB.model(self, "Chandelier_01", 3.75, 4.0, 0.0, 1.0, H - 0.8, false)
	var cl := WB.omni(self, Vector3(3.75, H - 0.75, 4.0), Color(1.0, 0.8, 0.56), 2.2, 9.0, true)
	var glow := WB.emissive(Color(1.0, 0.85, 0.6), 0.0)
	_room("loja", [cl], [glow])
	# pendants over the tables, lamps under the gallery
	WB.pendant(self, "loja", Vector3(3.6, H, 2.2), 2.0, 1.1, 4.5)
	WB.pendant(self, "loja", Vector3(2.6, H, 4.4), 2.0, 1.1, 4.5)
	for p in [Vector3(0.7, 2.66, 4.0), Vector3(0.7, 2.66, 7.5), Vector3(6.8, 2.66, 5.5), Vector3(6.8, 2.66, 8.5), Vector3(2.5, 2.66, 10.3), Vector3(5.2, 2.66, 10.3)]:
		var l := WB.omni(self, p - Vector3(0, 0.15, 0), Color(1.0, 0.82, 0.6), 0.55, 3.2, false)
		_room("loja", [l], [])
	# gallery: a few wall lamps between the shelves
	for p in [Vector3(1.0, GAL + 2.05, 3.0), Vector3(1.0, GAL + 2.05, 8.0), Vector3(6.5, GAL + 2.05, 4.5), Vector3(6.5, GAL + 2.05, 9.0), Vector3(3.75, GAL + 2.05, 10.4)]:
		var l2 := WB.omni(self, p, Color(1.0, 0.8, 0.55), 0.7, 4.0, true)
		_room("galeria", [l2], [])
	_switch_plate("loja", Vector3(2.45, 1.2, 0.07), 180.0, ["loja", "galeria"])
	_switch_plate("galeria", Vector3(1.6, GAL + 1.2, 10.6), 180.0, ["galeria"])


func _switch_plate(id: String, at: Vector3, rot: float, targets: Array, prompt := "") -> void:
	_switch(id, at, rot, targets, prompt)


# =================================================================== street
func _build_outside() -> void:
	var facade := WB.mat("painted_plaster_wall", 3.0, Color(0.86, 0.82, 0.74))
	var pav := WB.mat("stone_pavers", 1.4, Color(0.7, 0.7, 0.7))
	var asphalt := WB.mat("asphalt_06", 4.0, Color(0.6, 0.6, 0.6))
	WB.wall(self, "x", -EXT - 0.01, -25, 30, 14, 0.02, facade, [[2.8, 7.0, 0.55, 3.0], [0.8, 2.2, 0.0, 2.7], [3.0, 6.8, 3.5, 4.5]])
	WB.box(self, Vector3(-25, -0.6, -EXT), Vector3(-EXT, 14, 14), facade)
	WB.box(self, Vector3(7.5 + EXT, -0.6, -EXT), Vector3(30, 14, 14), facade)
	WB.box(self, Vector3(-EXT, H + 0.15, -EXT), Vector3(7.5 + EXT, 14, 14), facade)
	WB.box(self, Vector3(-EXT, -0.6, -EXT), Vector3(7.5 + EXT, -0.1, 14), facade)
	# the shop sign, painted above the window, and the number
	WB.box(self, Vector3(2.7, 3.1, -0.36), Vector3(7.1, 3.42, -0.32), WB.flat(Color(0.12, 0.2, 0.16), 0.5), false)
	WB.text(self, "LIVRARIA  MARÉ", Vector3(4.9, 3.26, -0.37), 180.0, 0.2, Color(0.88, 0.76, 0.48))
	WB.text(self, "31", Vector3(1.5, 2.9, -0.37), 180.0, 0.14, Color(0.2, 0.2, 0.2))
	WB.box(self, Vector3(-25, -1.0, -2.6), Vector3(30, -0.45, -EXT), pav)
	WB.box(self, Vector3(-25, -1.0, -2.75), Vector3(30, -0.45, -2.6), WB.flat(Color(0.55, 0.55, 0.53), 0.8))
	WB.box(self, Vector3(-25, -1.2, -9.4), Vector3(30, -0.6, -2.75), asphalt)
	WB.box(self, Vector3(-25, -1.0, -11.6), Vector3(30, -0.45, -9.4), pav)
	WB.box(self, Vector3(-25, -0.6, -16), Vector3(30, 15, -11.6), facade)
	_windows_across(-11.58)
	# the step up from the pavement into the shop
	WB.box(self, Vector3(0.7, -0.45, -0.6), Vector3(2.3, -0.1, -0.3), WB.mat("marble_01", 1.0, Color(0.7, 0.7, 0.68)))
	WB.model(self, "street_lamp_01", 4.5, -2.35, 0.0, 1.0, -0.45)
	street_lights.append(_street_light(Vector3(4.5, 3.25, -2.6)))
	WB.model(self, "street_lamp_01", -9.0, -9.75, 180.0, 1.0, -0.45)
	street_lights.append(_street_light(Vector3(-9.0, 3.25, -9.5)))
	WB.model(self, "street_lamp_01", 15.0, -9.75, 180.0, 1.0, -0.45)
	street_lights.append(_street_light(Vector3(15.0, 3.25, -9.5)))
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40, 160, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.05
	moon.shadow_enabled = true
	moon.light_volumetric_fog_energy = 0.0
	add_child(moon)


func _street_light(at: Vector3) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.position = at
	l.rotation_degrees.x = -90
	l.light_color = STREET_SODIUM
	l.light_energy = 9.0
	l.spot_range = 11.0
	l.spot_angle = 62.0
	l.spot_angle_attenuation = 3.0
	l.shadow_enabled = true
	l.light_volumetric_fog_energy = 1.4
	add_child(l)
	var o := WB.omni(self, at + Vector3(0, -0.4, 0), STREET_SODIUM, 0.7, 9.0, false)
	l.set_meta("fill", o)
	return l


func _windows_across(z: float) -> void:
	var dark := WB.flat(Color(0.03, 0.035, 0.045), 0.08, 0.3)
	var frame := WB.flat(Color(0.75, 0.73, 0.7), 0.5)
	var lit := WB.emissive(Color(0.85, 0.52, 0.28), 0.18)
	lit.set_meta("energy", 0.18)
	lit_windows.append(lit)
	for fy in [0.4, 3.4, 6.4, 9.4]:
		var x := -24.0
		while x < 28.0:
			WB.box(self, Vector3(x - 0.06, fy - 0.06, z), Vector3(x + 1.26, fy + 1.66, z + 0.02), frame, false)
			WB.box(self, Vector3(x, fy, z + 0.03), Vector3(x + 1.2, fy + 1.6, z + 0.031), lit if rng.randf() < 0.15 else dark, false)
			x += 3.4


# =================================================================== story
func _build_story_hooks() -> void:
	spawns = {
		"entrada": [Vector3(1.5, 0.02, 1.0), 180.0],
		"balcao": [Vector3(5.6, 0.02, 4.9), 200.0],
		"galeria": [Vector3(0.8, GAL + 0.02, 6.0), 180.0],
		"noite": [Vector3(1.5, 0.02, 0.7), 180.0, -4.0],
	}
	spots = {
		"front_door": Vector3(1.5, 1.3, -0.6), "street": Vector3(4.0, 0.5, -5.0),
		"corridor": Vector3(3.75, GAL + 1.0, 8.0), "landing": Vector3(3.75, GAL + 1.0, 10.2),
		"kitchen": Vector3(5.8, 1.0, 12.3), "wc": Vector3(2.0, 1.0, 12.5), "window": Vector3(4.9, 1.2, -1.0),
	}
	# Ricardo Reis on the top shelf of the back gallery ("a de cima")
	hotspots.ricardo_reis = Hotspot.add(self, Vector3(3.2, GAL + 1.6, 10.55), Vector3(0.5, 0.3, 0.2), _prompt("ricardo_reis"), func(p): _say("ricardo_reis", p))
	hotspots.montra = Hotspot.add(self, Vector3(4.9, 1.8, 0.0), Vector3(4.0, 2.2, 0.2), _prompt("montra"), func(p): _say("montra", p))
	hotspots.saramago = Hotspot.add(self, Vector3(3.45, 1.4, 10.45), Vector3(1.0, 2.2, 0.3), _prompt("saramago"), func(p): _say("saramago", p))
	hotspots.poesia = Hotspot.add(self, Vector3(0.45, 1.4, 7.5), Vector3(0.3, 2.2, 1.0), _prompt("poesia"), func(p): _say("poesia", p))
	add_hide("balcao", Vector3(5.6, 0.5, 4.35), Vector3(1.2, 0.9, 0.3), "Esconder atrás do balcão",
		[Vector3(5.3, 0.55, 4.6), 160.0, 2.0], [Vector3(5.4, 0.02, 4.9), 180.0])
	add_hide("arrecadacao", Vector3(4.6, 1.0, 12.9), Vector3(0.4, 1.8, 0.8), "Esconder atrás das prateleiras",
		[Vector3(4.55, 1.5, 13.25), 160.0, -4.0], [Vector3(5.2, 0.02, 12.6), 0.0])
	add_hide("escritorio", Vector3(2.0, 0.4, 13.0), Vector3(1.4, 0.7, 0.6), "Esconder debaixo da secretária",
		[Vector3(1.9, 0.4, 13.1), 0.0, 4.0], [Vector3(1.8, 0.02, 12.0), 180.0])
	# things that change by themselves
	for i in 4:
		var b := Books.pile(self, Vector3(rng.randf_range(1.6, 6.0), 0.0, rng.randf_range(5.0, 9.4)), rng.randi_range(1, 3), rng, 0.15)
		b.visible = false
		fallen_books.append(b)
		add_change("livros_%d" % i, b.position + Vector3(0, 0.3, 0), func(): b.visible = true, "drop", -14.0)
	for id in ["escritorio", "arrecadacao"]:
		var d: Door = doors[id]
		add_change("porta_" + id, d.global_position + Vector3(0.45, 1.0, 0), func(): d.set_open(not d.is_open, true), "door", -22.0)
	add_change("candeeiro", Vector3(5.1, 1.4, 8.0), func(): set_room_light("leitura", not rooms.leitura.on), "switch", -16.0)
	add_change("lustre", Vector3(3.75, 4.2, 4.0), func():
		var tw := create_tween()
		for k in 6:
			tw.tween_property(chandelier, "rotation_degrees:z", 4.0 * (1 - k / 6.0) * (1 if k % 2 == 0 else -1), 0.6)
		tw.tween_property(chandelier, "rotation_degrees:z", 0.0, 0.6), "click_far", -18.0)


func floor_kind(_p: Vector3) -> String:
	return "wood"


func set_daylight(d: float) -> void:
	var night := d < 0.35
	for l in street_lights:
		l.visible = night
		(l.get_meta("fill") as OmniLight3D).visible = night
	for m in lit_windows:
		m.emission_energy_multiplier = float(m.get_meta("energy")) * (1.0 - d)
	moon.visible = d < 0.5
	for f in sky_fills:
		f.visible = d > 0.02
		f.light_energy = float(f.get_meta("base")) * d
