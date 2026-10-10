class_name RuiHouse
extends Location
## Rui Matos's house, Travessa do Pescador, Salgueira. A fisherman's ground
## floor: one big kitchen-living room with blue-and-white tiles, the table
## where Rui eats alone, nets and boots by the yard door; Rui's room; and
## Inês's old room, kept as it was, with the box of her things.
##
##   x0..9 z0..8 (street at z<0, yard at z>8), ceiling 2.7

const H := 2.7
const EXT := 0.3
const INT := 0.12

var rng := RandomNumberGenerator.new()
var sky_fills: Array[OmniLight3D] = []
var moon: DirectionalLight3D


func _ready() -> void:
	load_texts("rui")
	aliases = ["casa_ines"]
	rng.seed = 317
	m_wall = WB.mat("white_plaster_02", 2.5, Color(0.95, 0.94, 0.9))
	m_ceiling = WB.mat("roof_planks", 1.6, Color(0.55, 0.46, 0.38))
	m_paint = WB.flat(Color(0.2, 0.32, 0.45), 0.45)
	m_skirt = WB.flat(Color(0.2, 0.32, 0.45), 0.5)
	_build_shell()
	_build_kitchen()
	_build_rooms()
	_build_outside()
	_build_story_hooks()
	set_room_light("cozinha", true)


func _azulejo() -> Material:
	# a blue-and-white tile with a simple four-petal pattern, drawn here
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(Color(0.93, 0.93, 0.9))
	var blue := Color(0.12, 0.28, 0.58)
	for y in 128:
		for x in 128:
			var u := (x - 64.0) / 64.0
			var v := (y - 64.0) / 64.0
			var r := sqrt(u * u + v * v)
			var petal := absf(sin(atan2(v, u) * 2.0))
			if r < 0.55 * petal + 0.12 or (absf(u) > 0.9 or absf(v) > 0.9) and (absf(u) + absf(v) > 1.75):
				img.set_pixel(x, y, blue)
			elif absf(r - 0.78) < 0.04:
				img.set_pixel(x, y, blue.lightened(0.25))
	for k in 128:
		img.set_pixel(k, 0, Color(0.75, 0.75, 0.72))
		img.set_pixel(0, k, Color(0.75, 0.75, 0.72))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.12
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / 0.15
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


# =================================================================== shell
func _build_shell() -> void:
	var floor := WB.grid(Color(0.62, 0.32, 0.22), Color(0.48, 0.25, 0.18), 0.3, 0.6, 3)
	WB.box(self, Vector3(0, -0.1, 0), Vector3(9, 0, 8), floor)
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(9 + EXT, H + 0.12, 8 + EXT), m_ceiling)
	for z in [1.5, 3.5, 5.5]:
		WB.box(self, Vector3(0, H - 0.18, z - 0.08), Vector3(6, H, z + 0.08), WB.mat("dark_wood", 1.0, Color(0.35, 0.26, 0.2)), false)
	var front := [[1.0, 2.4, 0.9, 2.1], [3.2, 4.2, 0.0, 2.2], [6.8, 8.0, 0.9, 2.1]]
	WB.wall(self, "x", -EXT / 2, -EXT, 9 + EXT, H, EXT, m_wall, front)
	WB.wall(self, "x", 8 + EXT / 2, -EXT, 9 + EXT, H, EXT, m_wall, [[1.2, 2.2, 0.0, 2.1], [3.6, 5.0, 1.0, 2.0]])
	WB.wall(self, "z", -EXT / 2, 0, 8, H, EXT, m_wall)
	WB.wall(self, "z", 9 + EXT / 2, 0, 8, H, EXT, m_wall)
	WB.wall(self, "z", 6.0, 0, 8, H, INT, m_wall, [[1.2, 2.0, 0.0, 2.05], [5.6, 6.4, 0.0, 2.05]])
	WB.wall(self, "x", 4.5, 6.0, 9, H, INT, m_wall)
	# azulejo dado around the big room
	var az := _azulejo()
	WB.wall(self, "x", 0.008, 0, 6, 1.3, 0.016, az, [[1.0, 2.4, 0.9, 2.1], [3.2, 4.2, 0.0, 2.2]])
	WB.wall(self, "x", 7.992, 0, 6, 1.3, 0.016, az, [[1.2, 2.2, 0.0, 2.1], [3.6, 5.0, 1.0, 2.0]])
	WB.wall(self, "z", 0.008, 0, 8, 1.3, 0.016, az)
	WB.wall(self, "z", 5.932, 0, 8, 1.3, 0.016, az, [[1.2, 2.0, 0.0, 2.05], [5.6, 6.4, 0.0, 2.05]])
	for w in front:
		if w[2] > 0.0:
			_window(w, 0.0, -1.0)
	_window([3.6, 5.0, 1.0, 2.0], 8.0, 1.0)
	doors.rua = Door.make(self, Vector3(3.2, 0, 0.0), "x", 1.0, 2.2, m_paint, 1.0)
	doors.rua.locked = true
	doors.rua.locked_text = _first_text("porta_rua")
	doors.rua.toggled.connect(func(open: bool):
		if open:
			GameState.set_var("left_rui", true)
			Director.notify_player_action())
	doors.quintal = Door.make(self, Vector3(1.2, 0, 8.0), "x", 1.0, 2.1, m_paint, 1.0)
	doors.quintal.locked = true
	doors.quintal.locked_text = _first_text("porta_quintal")
	doors.ines = Door.make(self, Vector3(6.0, 0, 1.2), "z", 0.8, 2.05, WB.flat(Color(0.85, 0.83, 0.78), 0.45), -1.0)
	doors.rui = Door.make(self, Vector3(6.0, 0, 5.6), "z", 0.8, 2.05, WB.flat(Color(0.85, 0.83, 0.78), 0.45), -1.0)
	room_bounds = {
		"cozinha": AABB(Vector3(0, 0, 0), Vector3(6, H, 8)),
		"ines": AABB(Vector3(6, 0, 0), Vector3(3, H, 4.5)),
		"rui": AABB(Vector3(6, 0, 4.5), Vector3(3, H, 3.5)),
	}


func _window(w: Array, at: float, out: float) -> void:
	var frame := WB.flat(Color(0.2, 0.32, 0.45), 0.45)
	var mid := at + out * EXT / 2
	var x0: float = w[0]
	var x1: float = w[1]
	var y0: float = w[2]
	var y1: float = w[3]
	for p in [[x0, x0 + 0.06, y0, y1], [x1 - 0.06, x1, y0, y1], [x0, x1, y0, y0 + 0.06], [x0, x1, y1 - 0.06, y1], [(x0 + x1) / 2 - 0.03, (x0 + x1) / 2 + 0.03, y0, y1]]:
		WB.box(self, Vector3(p[0], p[2], mid - 0.04), Vector3(p[1], p[3], mid + 0.04), frame, false)
	WB.box(self, Vector3(x0 + 0.06, y0 + 0.06, mid - 0.005), Vector3(x1 - 0.06, y1 - 0.06, mid + 0.005), WB.glass(), true)
	WB.box(self, Vector3(x0 - 0.04, y0 - 0.04, at - out * 0.06), Vector3(x1 + 0.04, y0, mid), WB.mat("marble_01", 1.0), false)
	# a lace curtain, half drawn
	var lace := StandardMaterial3D.new()
	lace.albedo_color = Color(0.95, 0.94, 0.9, 0.55)
	lace.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lace.cull_mode = BaseMaterial3D.CULL_DISABLED
	WB.box(self, Vector3(x0, y0 + 0.1, at - out * 0.12), Vector3((x0 + x1) / 2, y1, at - out * 0.125), lace, false)
	var fill := WB.omni(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, at - out * 0.9), Color(0.8, 0.85, 0.95), 0.0, 5.5, false)
	fill.set_meta("base", 1.6)
	fill.visible = false
	sky_fills.append(fill)


# =================================================================== the big room
func _build_kitchen() -> void:
	var wood := WB.mat("kitchen_wood", 1.0, Color(0.7, 0.6, 0.48))
	var counter := WB.mat("marble_01", 1.0, Color(0.6, 0.58, 0.55))
	# kitchen along the west wall
	WB.box(self, Vector3(0.05, 0, 3.0), Vector3(0.65, 0.88, 6.2), wood)
	WB.box(self, Vector3(0.03, 0.88, 2.98), Vector3(0.68, 0.92, 6.22), counter, false)
	WB.model(self, "electric_stove", 0.36, 6.6, 90.0)
	WB.box(self, Vector3(0.1, 0.92, 4.2), Vector3(0.6, 0.94, 4.9), WB.flat(Color(0.7, 0.7, 0.7), 0.2, 0.9), false)
	WB.model(self, "jug_01", 0.35, 3.5, 90.0, 1.0, 0.92, false)
	WB.model(self, "wooden_cutting_board", 0.35, 5.6, 80.0, 1.0, 0.92, false)
	# the table where he eats alone, one chair pulled out
	WB.model(self, "round_wooden_table_01", 2.8, 4.0, 0.0, 0.7)
	WB.model(self, "dining_chair_02", 2.1, 4.0, 90.0)
	WB.model(self, "dining_chair_02", 3.6, 4.6, -120.0)
	WB.model(self, "dining_chair_02", 2.8, 3.1, 0.0)
	hotspots.mesa = Hotspot.add(self, Vector3(2.8, 0.8, 4.0), Vector3(1.0, 0.2, 1.0), _prompt("mesa"), func(p): _say("mesa", p))
	# the dresser with plates, an armchair, the radio corner
	WB.model(self, "painted_wooden_cabinet", 5.6, 2.6, -90.0)
	WB.model(self, "ArmChair_01", 4.8, 1.2, -140.0)
	WB.model(self, "standing_picture_frame_01", 5.62, 2.3, -100.0, 1.2, WB.footprint(get_node("painted_wooden_cabinet")).end.y, false)
	hotspots.fotografia = Hotspot.add(self, Vector3(5.6, 1.35, 2.3), Vector3(0.3, 0.35, 0.3), _prompt("fotografia"), func(p): _say("fotografia", p))
	# fishing gear by the yard door
	WB.model(self, "rubber_boots", 1.0, 7.6, 10.0)
	WB.model(self, "fishermans_hat", 0.4, 7.2, 0.0, 1.0, 1.55, false)
	WB.box(self, Vector3(0.05, 1.5, 7.1), Vector3(0.1, 1.53, 7.3), WB.flat(Color(0.3, 0.3, 0.3), 0.5, 0.7), false)
	WB.model(self, "lifebuoy", 3.6, 7.98, 180.0, 1.0, 1.4, false)
	WB.model(self, "plastic_crate_01", 4.6, 7.5, 20.0)
	WB.model(self, "plastic_crate_01", 4.62, 7.48, -10.0, 1.0, 0.26, false)
	WB.model(self, "wooden_bucket_01", 5.3, 7.4, 0.0)
	WB.model(self, "Lantern_01", 5.4, 2.0, 0.0, 1.4, 1.17, false)
	_net(Vector3(2.6, 0, 7.4))
	hotspots.redes = Hotspot.add(self, Vector3(2.6, 0.3, 7.4), Vector3(1.4, 0.6, 1.0), _prompt("redes"), func(p): _say("redes", p))
	var calendar := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.3, 0.42)
	calendar.mesh = qm
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.95, 0.94, 0.9)
	calendar.material_override = cm
	calendar.position = Vector3(0.02, 1.7, 2.2)
	calendar.rotation_degrees.y = 90.0
	add_child(calendar)
	WB.text(self, "OUTUBRO 2025", Vector3(0.025, 1.85, 2.2), 90.0, 0.035, Color(0.6, 0.1, 0.1))
	hotspots.calendario = Hotspot.add(self, Vector3(0.05, 1.7, 2.2), Vector3(0.08, 0.45, 0.35), _prompt("calendario"), func(p): _say("calendario", p))
	WB.pendant(self, "cozinha", Vector3(2.8, H, 4.0), 0.9, 1.4, 6.0, Color(0.9, 0.85, 0.7))
	WB.omni(self, Vector3(0.5, 2.2, 4.6), Color(1.0, 0.85, 0.65), 0.0, 3.0, false)
	_switch("cozinha", Vector3(3.0, 1.2, 0.07), 180.0, ["cozinha"])


func _net(at: Vector3) -> void:
	# a heap of green net: a squashed sphere with a mesh-like shader
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.7
	sm.height = 0.7
	sm.is_hemisphere = true
	mi.mesh = sm
	mi.scale = Vector3(1.0, 0.6, 0.7)
	mi.position = at
	var sh := Shader.new()
	sh.code = """shader_type spatial;
void fragment() {
	vec2 g = fract(UV * vec2(60.0, 30.0));
	float knot = step(0.86, max(g.x, g.y));
	ALBEDO = mix(vec3(0.08, 0.22, 0.14), vec3(0.18, 0.32, 0.2), knot);
	ROUGHNESS = 0.9;
}"""
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	add_child(mi)
	WB.model(self, "ocean_buoy", at.x + 0.6, at.z - 0.1, 30.0, 0.25, 0.1, false)


# =================================================================== bedrooms
func _build_rooms() -> void:
	# Inês's room, as she left it
	var bed := WB.model(self, "old_bed_frame", 8.2, 2.2, 0.0)
	var bb := WB.footprint(bed)
	WB.box(self, Vector3(bb.position.x + 0.06, 0.36, bb.position.z + 0.06), Vector3(bb.end.x - 0.06, 0.52, bb.end.z - 0.06), WB.flat(Color(0.85, 0.85, 0.82), 0.9), false)
	WB.box(self, Vector3(bb.position.x + 0.04, 0.52, bb.position.z + 0.4), Vector3(bb.end.x - 0.04, 0.6, bb.end.z - 0.03), WB.flat(Color(0.6, 0.15, 0.14), 0.95), false)
	WB.model(self, "painted_wooden_nightstand", 8.6, 0.55, 180.0, 0.9)
	var box := WB.model(self, "cardboard_box_01", 6.8, 3.8, 15.0, 1.2)
	WB.text(self, "INÊS", WB.footprint(box).get_center() + Vector3(0, 0.15, -0.32), 195.0, 0.06, Color(0.1, 0.1, 0.1))
	hotspots.caixa_ines = Hotspot.add(self, WB.footprint(box).get_center(), WB.footprint(box).size + Vector3(0.1, 0.1, 0.1), _prompt("caixa_ines"), func(p): _say("caixa_ines", p))
	Books.unit(self, Vector3(6.35, 0, 2.6), 90.0, 0.9, 1.6, 0.3, [0.4, 0.8, 1.2], WB.mat("dark_wood", 1.0, Color(0.6, 0.5, 0.4)), rng)
	WB.model(self, "vintage_cabinet_01", 7.5, 0.4, 0.0, 0.7)
	var red_coat := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.2
	cap.height = 1.0
	red_coat.mesh = cap
	red_coat.material_override = WB.flat(Color(0.55, 0.06, 0.06), 0.85)
	red_coat.position = Vector3(8.82, 1.35, 3.6)
	red_coat.scale = Vector3(1.0, 1.0, 0.45)
	add_child(red_coat)
	WB.box(self, Vector3(8.85, 1.86, 3.55), Vector3(8.95, 1.9, 3.65), WB.flat(Color(0.3, 0.3, 0.3), 0.4, 0.8), false)
	hotspots.casaco = Hotspot.add(self, Vector3(8.82, 1.35, 3.6), Vector3(0.45, 1.1, 0.4), _prompt("casaco"), func(p): _say("casaco", p))
	var l := WB.omni(self, Vector3(7.5, 2.4, 2.2), Color(1.0, 0.85, 0.65), 0.8, 4.0, true)
	_room("ines", [l], [])
	_switch("ines", Vector3(6.07, 1.2, 2.3), 90.0, ["ines"])
	# Rui's room: a mattress, clothes on a chair, an ashtray
	var bed2 := WB.model(self, "old_bed_frame", 8.2, 6.4, 0.0)
	var b2 := WB.footprint(bed2)
	WB.box(self, Vector3(b2.position.x + 0.06, 0.36, b2.position.z + 0.06), Vector3(b2.end.x - 0.06, 0.52, b2.end.z - 0.06), WB.flat(Color(0.5, 0.52, 0.5), 0.9), false)
	WB.model(self, "dining_chair_02", 6.6, 7.4, 140.0)
	var l2 := WB.omni(self, Vector3(7.5, 2.4, 6.2), Color(1.0, 0.85, 0.65), 0.7, 4.0, true)
	_room("rui", [l2], [])
	_switch("rui", Vector3(6.07, 1.2, 6.6), 90.0, ["rui"])


# =================================================================== outside
func _build_outside() -> void:
	var facade := WB.mat("painted_plaster_wall", 3.0, Color(0.94, 0.94, 0.9))
	WB.wall(self, "x", -EXT - 0.01, -15, 25, 6, 0.02, facade, [[1.0, 2.4, 0.9, 2.1], [3.2, 4.2, 0.0, 2.2], [6.8, 8.0, 0.9, 2.1]])
	WB.box(self, Vector3(-15, -0.5, -5), Vector3(25, 0, -EXT), WB.mat("cobblestone_floor_04", 1.6, Color(0.8, 0.78, 0.74)))
	WB.box(self, Vector3(-15, 0, -6), Vector3(25, 3.5, -5), facade)
	WB.box(self, Vector3(-EXT, -0.4, -EXT), Vector3(9 + EXT, -0.1, 8 + EXT), facade)
	WB.box(self, Vector3(-3, -0.5, 8.3), Vector3(12, 0, 12), WB.mat("concrete_wall_003", 2.0, Color(0.6, 0.6, 0.58)))
	WB.box(self, Vector3(-3, 0, 12), Vector3(12, 2.2, 12.3), facade)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40, 160, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.05
	moon.shadow_enabled = true
	add_child(moon)


# =================================================================== story
func _build_story_hooks() -> void:
	spawns = {
		"entrada": [Vector3(3.7, 0.02, 0.9), 180.0],
		"mesa": [Vector3(3.2, 0.02, 2.6), 160.0],
	}
	spots = {
		"front_door": Vector3(3.7, 1.3, -0.5), "street": Vector3(3.7, 0.5, -3.0),
		"corridor": Vector3(5.8, 1.5, 4.0), "landing": Vector3(1.7, 1.2, 8.6),
		"kitchen": Vector3(0.5, 1.0, 4.6), "wc": Vector3(7.5, 1.0, 6.0), "window": Vector3(1.7, 1.5, -0.6),
	}
	add_hide("roupeiro_ines", Vector3(7.5, 1.0, 0.65), Vector3(1.4, 1.6, 0.3), "Esconder no roupeiro",
		[Vector3(7.5, 1.4, 0.45), 180.0, -4.0], [Vector3(7.5, 0.02, 1.4), 0.0])
	add_change("porta_ines", doors.ines.global_position + Vector3(0, 1.0, 0.4), func(): doors.ines.set_open(not doors.ines.is_open, true), "door", -22.0)
	add_change("cadeira", Vector3(3.6, 0.5, 4.6), func():
		var c: Node3D = find_children("dining_chair_02", "Node3D", false, false)[1]
		c.rotation_degrees.y += 90.0, "click_far", -14.0)


func set_daylight(d: float) -> void:
	moon.visible = d < 0.5
	for f in sky_fills:
		f.visible = d > 0.02
		f.light_energy = float(f.get_meta("base")) * d
