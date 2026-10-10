class_name House
extends Location
## Daniel's flat: Rua das Gaivotas 12, rés-do-chão, Salgueira. Built in code
## from Poly Haven (CC0) textures and models, so every wall and lamp can be
## changed by the story.
##
##   z=0 is the street wall (windows), the street is at z < 0.
##   Sala x0..5.5 z0..4.5 | Quarto x5.5..10 z0..4.5
##   Corredor x0..10 z4.5..5.8 (front door at the east end, x=10)
##   Cozinha x0..5.5 z5.8..9 | WC x5.5..8 | Arrumos x8..10

const H := 2.9            # ceiling
const EXT := 0.3          # outer wall
const INT := 0.12         # inner wall
const STREET_SODIUM := Color(1.0, 0.6, 0.28)

## room id -> {lights: [Light3D], glow: [StandardMaterial3D], on: bool, energy: [float]}
var tv_on := true
var tv_light: OmniLight3D
var tv_mat: ShaderMaterial
var laptop_mat: StandardMaterial3D
var street_lamp: SpotLight3D
var street_lamp_bulb: StandardMaterial3D
var street_lights: Array[SpotLight3D] = []
var lit_windows: Array[StandardMaterial3D] = []
var moon: DirectionalLight3D
var sky_fills: Array[OmniLight3D] = []
var landing_light: OmniLight3D
var mirror: MeshInstance3D
var _t := 0.0
var _street_flicker := 0.0


func _ready() -> void:
	load_texts("casa")
	m_wall = WB.mat("acg_plaster", 2.0, Color(0.93, 0.91, 0.87))
	m_ceiling = WB.mat("acg_plaster", 2.0, Color(0.9, 0.9, 0.88))
	m_paint = WB.flat(Color(0.86, 0.85, 0.82), 0.45)
	m_skirt = WB.flat(Color(0.8, 0.79, 0.76), 0.4)
	_build_shell()
	_build_sala()
	_build_quarto()
	_build_corredor()
	_build_cozinha()
	_build_wc()
	_build_arrumos()
	_build_outside()
	_build_landing()
	set_room_light("sala", true)
	set_room_light("candeeiro", false)
	_build_story_hooks()


## Where Daniel starts, which room is where, where to hide, what can change.
func _build_story_hooks() -> void:
	peep = [Vector3(10.2, 1.55, 5.15), -90.0]
	spawns = {
		"sofa": [Vector3(3.9, 0.02, 2.6), 20.0],
		"corridor": [Vector3(8.5, 0.02, 5.15), 90.0],
		"bed": [Vector3(8.0, 0.02, 1.8), 0.0],
	}
	room_bounds = {
		"sala": AABB(Vector3(0, 0, 0), Vector3(5.5, H, 4.5)),
		"quarto": AABB(Vector3(5.5, 0, 0), Vector3(4.5, H, 4.5)),
		"corredor": AABB(Vector3(0, 0, 4.5), Vector3(10, H, 1.3)),
		"cozinha": AABB(Vector3(0, 0, 5.8), Vector3(5.5, H, 3.2)),
		"wc": AABB(Vector3(5.5, 0, 5.8), Vector3(2.5, H, 3.2)),
		"arrumos": AABB(Vector3(8, 0, 5.8), Vector3(2, H, 3.2)),
	}
	# hiding places: the wardrobe, under the bed, the storage room
	add_hide("roupeiro", Vector3(8.45, 1.1, 3.8), Vector3(1.9, 2.1, 0.3), "Esconder no roupeiro",
		[Vector3(8.45, 1.55, 4.15), 180.0, -4.0], [Vector3(8.45, 0.02, 3.2), 180.0])
	add_hide("cama", Vector3(8.95, 0.3, 2.25), Vector3(1.9, 0.5, 0.25), "Esconder debaixo da cama",
		[Vector3(8.95, 0.18, 2.7), 0.0, 4.0], [Vector3(8.95, 0.02, 1.7), 180.0])
	add_hide("arrumos", Vector3(9.75, 1.0, 8.3), Vector3(0.4, 1.8, 1.0), "Esconder atrás das prateleiras",
		[Vector3(9.55, 1.5, 8.6), 15.0, -6.0], [Vector3(9.0, 0.02, 7.6), 0.0])
	# things that change when nobody is looking
	for id in ["sala", "quarto", "cozinha", "wc", "arrumos"]:
		var d: Door = doors[id]
		add_change("porta_" + id, d.global_position + Vector3(0.4, 1.0, 0), func():
			d.set_open(not d.is_open, true), "door", -22.0)
	for c in find_children("dining_chair_02", "Node3D", false, false):
		var chair: Node3D = c
		add_change("cadeira", chair.position + Vector3(0, 0.5, 0), func():
			chair.rotation_degrees.y += 90.0 * (1 if randf() < 0.5 else -1), "click_far", -14.0)
	add_change("tv", Vector3(2.7, 1.1, 4.2), func(): set_tv(not tv_on), "click_far", -12.0)
	for id in ["cozinha", "quarto", "wc"]:
		add_change("luz_" + id, room_bounds[id].get_center(), func(): set_room_light(id, not rooms[id].on), "switch", -16.0)


# =================================================================== shell
func _build_shell() -> void:
	var parquet := WB.mat("herringbone_parquet", 1.6, Color(0.85, 0.8, 0.75))
	var terrazzo := WB.mat("terrazzo_tiles", 1.2)
	var mosaic := WB.mat("marble_mosaic_tiles", 0.7)
	# floors
	WB.box(self, Vector3(0, -0.1, 0), Vector3(10, 0, 5.8), parquet)
	WB.box(self, Vector3(0, -0.1, 5.8), Vector3(5.5, 0, 9), terrazzo)
	WB.box(self, Vector3(5.5, -0.1, 5.8), Vector3(8, 0, 9), mosaic)
	WB.box(self, Vector3(8, -0.1, 5.8), Vector3(10, 0, 9), terrazzo)
	# ceiling
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(10 + EXT, H + 0.15, 9 + EXT), m_ceiling)
	# outer walls (inside face at 0 / 10 / 9)
	var win_sala_a := [1.0, 2.2, 0.95, 2.45]
	var win_sala_b := [3.2, 4.4, 0.95, 2.45]
	var win_quarto := [7.1, 8.5, 0.95, 2.45]
	var win_coz := [2.6, 3.6, 1.15, 2.25]
	var win_wc := [6.4, 7.0, 1.6, 2.2]
	var front := [4.75, 5.55, 0.0, 2.15]
	WB.wall(self, "x", -EXT / 2, -EXT, 10 + EXT, H, EXT, m_wall, [win_sala_a, win_sala_b, win_quarto])
	WB.wall(self, "x", 9 + EXT / 2, -EXT, 10 + EXT, H, EXT, m_wall, [win_coz, win_wc])
	WB.wall(self, "z", -EXT / 2, 0, 9, H, EXT, m_wall)
	WB.wall(self, "z", 10 + EXT / 2, 0, 9, H, EXT, m_wall, [front])
	# inner walls
	var d_sala := [4.3, 5.1, 0.0, 2.1]
	var d_quarto := [5.8, 6.6, 0.0, 2.1]
	var d_coz := [3.0, 3.8, 0.0, 2.1]
	var d_wc := [6.2, 6.9, 0.0, 2.1]
	var d_arr := [8.7, 9.4, 0.0, 2.1]
	WB.wall(self, "x", 4.5, 0, 10, H, INT, m_wall, [d_sala, d_quarto])
	WB.wall(self, "x", 5.8, 0, 10, H, INT, m_wall, [d_coz, d_wc, d_arr])
	WB.wall(self, "z", 5.5, 0, 4.5 - INT / 2, H, INT, m_wall)
	WB.wall(self, "z", 5.5, 5.8 + INT / 2, 9, H, INT, m_wall)
	WB.wall(self, "z", 8.0, 5.8 + INT / 2, 9, H, INT, m_wall)
	# skirting boards (rodapé) in the wooden rooms
	WB.wall(self, "x", 0.0, 0, 10, 0.09, 0.03, m_skirt, [])
	WB.wall(self, "x", 4.5, 0, 10, 0.09, INT + 0.03, m_skirt, [d_sala, d_quarto])
	WB.wall(self, "x", 5.8, 0, 10, 0.09, INT + 0.03, m_skirt, [d_coz, d_wc, d_arr])
	WB.wall(self, "z", 0.0, 0, 5.8, 0.09, 0.03, m_skirt, [])
	WB.wall(self, "z", 10.0, 0, 5.8, 0.09, 0.03, m_skirt, [front])
	WB.wall(self, "z", 5.5, 0, 4.5, 0.09, INT + 0.03, m_skirt, [])
	# tiles: kitchen to 1.5 m, bathroom to 2.0 m
	var ktile := WB.grid(Color(0.93, 0.93, 0.9), Color(0.66, 0.66, 0.63), 0.15, 0.12, 2)
	WB.wall(self, "x", 9 - 0.006, 0, 5.5, 1.5, 0.012, ktile, [win_coz])
	WB.wall(self, "x", 5.8 + INT / 2 + 0.006, 0, 5.5, 1.5, 0.012, ktile, [d_coz])
	WB.wall(self, "z", 0.006, 5.8, 9, 1.5, 0.012, ktile)
	WB.wall(self, "z", 5.5 - INT / 2 - 0.006, 5.8, 9, 1.5, 0.012, ktile)
	var wtile := WB.mat("long_white_tiles", 1.0)
	WB.wall(self, "x", 9 - 0.006, 5.5, 8, 2.0, 0.012, wtile, [win_wc])
	WB.wall(self, "x", 5.8 + INT / 2 + 0.006, 5.5, 8, 2.0, 0.012, wtile, [d_wc])
	WB.wall(self, "z", 5.5 + INT / 2 + 0.006, 5.8, 9, 2.0, 0.012, wtile)
	WB.wall(self, "z", 8 - INT / 2 - 0.006, 5.8, 9, 2.0, 0.012, wtile)
	# door frames and leaves
	_frame("x", 4.5, d_sala, INT)
	_frame("x", 4.5, d_quarto, INT)
	_frame("x", 5.8, d_coz, INT)
	_frame("x", 5.8, d_wc, INT)
	_frame("x", 5.8, d_arr, INT)
	_frame("z", 10.0, front, EXT * 2)
	doors.sala = Door.make(self, Vector3(4.3, 0, 4.5), "x", 0.8, 2.1, m_paint, 1.0)
	doors.quarto = Door.make(self, Vector3(5.8, 0, 4.5), "x", 0.8, 2.1, m_paint, 1.0)
	doors.cozinha = Door.make(self, Vector3(3.0, 0, 5.8), "x", 0.8, 2.1, m_paint, -1.0)
	doors.wc = Door.make(self, Vector3(6.2, 0, 5.8), "x", 0.7, 2.1, m_paint, -1.0)
	doors.arrumos = Door.make(self, Vector3(8.7, 0, 5.8), "x", 0.7, 2.1, m_paint, -1.0)
	var wood_dark := WB.mat("kitchen_wood", 1.0, Color(0.45, 0.32, 0.24))
	doors.entrada = Door.make(self, Vector3(10.0, 0, 4.75), "z", 0.8, 2.15, wood_dark, -1.0)
	doors.entrada.locked = true
	doors.entrada.locked_text = _first_text("front_door")
	doors.sala.set_open(true, true)
	doors.cozinha.set_open(true, true)
	doors.quarto.leaf.rotation_degrees.y = 35.0
	doors.quarto.is_open = true
	# windows
	_window("x", 0.0, win_sala_a, -1.0, "window_sala")
	_window("x", 0.0, win_sala_b, -1.0, "window_sala")
	_window("x", 0.0, win_quarto, -1.0, "window_quarto")
	_window("x", 9.0, win_coz, 1.0, "")
	_window("x", 9.0, win_wc, 1.0, "", true)
	spots.front_door = Vector3(10.4, 1.3, 5.15)
	spots.landing = Vector3(11.5, 1.5, 5.4)
	spots.corridor = Vector3(5.0, 1.6, 5.15)
	spots.kitchen = Vector3(2.5, 1.0, 7.5)
	spots.bedroom = Vector3(7.8, 1.2, 2.5)
	spots.wc = Vector3(6.7, 1.2, 7.5)
	spots.window = Vector3(2.7, 1.2, -1.2)
	spots.street = Vector3(4.0, 0.5, -5.0)


## Painted jambs and lintel around a door hole.
func _frame(axis: String, at: float, hole: Array, thick: float) -> void:
	var w := 0.07
	var d := thick / 2.0 + 0.015
	var parts := [[hole[0] - w, hole[0], 0.0, hole[3] + w], [hole[1], hole[1] + w, 0.0, hole[3] + w], [hole[0], hole[1], hole[3], hole[3] + w]]
	for p in parts:
		if axis == "x":
			WB.box(self, Vector3(p[0], p[2], at - d), Vector3(p[1], p[3], at + d), m_paint, false)
		else:
			WB.box(self, Vector3(at - d, p[2], p[0]), Vector3(at + d, p[3], p[1]), m_paint, false)


## A two-leaf window in an outer wall along X; out = -1 if outside is -z.
func _window(axis: String, at: float, hole: Array, out: float, text_id: String, frosted := false) -> void:
	var x0: float = hole[0]
	var x1: float = hole[1]
	var y0: float = hole[2]
	var y1: float = hole[3]
	var mid := at + out * EXT / 2.0
	var frame := WB.flat(Color(0.88, 0.87, 0.84), 0.35)
	var fw := 0.06
	for p in [[x0, x0 + fw, y0, y1], [x1 - fw, x1, y0, y1], [x0, x1, y0, y0 + fw], [x0, x1, y1 - fw, y1], [(x0 + x1) / 2 - 0.035, (x0 + x1) / 2 + 0.035, y0, y1]]:
		WB.box(self, Vector3(p[0], p[2], mid - 0.04), Vector3(p[1], p[3], mid + 0.04), frame, false)
	var g := WB.glass()
	if frosted:
		g = WB.flat(Color(0.75, 0.78, 0.8, 0.75), 0.6)
	WB.box(self, Vector3(x0 + fw, y0 + fw, mid - 0.005), Vector3(x1 - fw, y1 - fw, mid + 0.005), g, true)
	# marble sills, inside and out (the photo from the street shows the outer one)
	var marble := WB.mat("marble_01", 1.0)
	var inner := at - out * 0.0
	WB.box(self, Vector3(x0 - 0.04, y0 - 0.03, inner - out * 0.06), Vector3(x1 + 0.04, y0, mid), marble, false)
	WB.box(self, Vector3(x0 - 0.05, y0 - 0.04, mid), Vector3(x1 + 0.05, y0, at + out * (EXT + 0.07)), marble, false)
	# daylight coming in: a soft fill just inside the glass (off at night)
	var fill := WB.omni(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, at - out * 0.7), Color(0.78, 0.84, 0.95), 0.0, 5.5 if not frosted else 3.5, false)
	fill.set_meta("base", 1.3 * (x1 - x0) * (y1 - y0) / 1.8)
	fill.light_volumetric_fog_energy = 0.0
	fill.visible = false
	sky_fills.append(fill)
	if text_id != "":
		hotspots[text_id + str(x0)] = Hotspot.add(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, at - out * 0.02), Vector3(x1 - x0, y1 - y0, 0.1), _prompt(text_id), func(p): _say(text_id, p))


# =================================================================== rooms
func _build_sala() -> void:
	WB.model(self, "sofa_03", 2.7, 0.55, 0.0)
	WB.model(self, "throw_pillows_01", 3.5, 0.5, 8.0, 0.8, 0.42, false)
	# rug under the coffee table
	WB.box(self, Vector3(1.6, 0, 1.15), Vector3(3.8, 0.012, 2.45), WB.flat(Color(0.28, 0.12, 0.1), 0.95), false)
	WB.model(self, "modern_coffee_table_01", 2.7, 1.8, 90.0)
	WB.model(self, "modern_wooden_cabinet", 2.7, 4.17, 180.0)
	_tv(Vector3(2.7, 0.68, 4.2))
	WB.model(self, "ArmChair_01", 0.75, 1.95, 50.0)
	var shelf := WB.model(self, "wooden_bookshelf_worn", 0.36, 3.68, 90.0)
	var sb := WB.footprint(shelf)
	for i in 3:
		WB.model(self, "book_encyclopedia_set_01", 0.36, 3.45 + i * 0.12, 90.0, 1.0, 0.06 + i * 0.47, false)
	hotspots.bookshelf = Hotspot.add(self, sb.position + sb.size / 2, sb.size, _prompt("bookshelf"), func(p): _say("bookshelf", p))
	WB.model(self, "potted_plant_01", 0.4, 0.45, 0.0, 0.9)
	# desk by the east wall, facing the room
	var desk := WB.model(self, "metal_office_desk", 5.1, 1.75, -90.0, 0.72)
	var top := WB.footprint(desk).end.y
	WB.model(self, "dining_chair_02", 4.45, 1.75, 90.0)
	_laptop(Vector3(5.12, top, 1.75))
	WB.model(self, "desk_lamp_arm_01", 5.3, 2.3, -120.0, 1.0, top, false)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(5.05, top + 0.55, 2.15)
	lamp.rotation_degrees = Vector3(-70, 90, 0)
	lamp.light_color = Color(1.0, 0.82, 0.6)
	lamp.light_energy = 2.5
	lamp.spot_range = 3.0
	lamp.spot_angle = 48.0
	lamp.shadow_enabled = true
	add_child(lamp)
	_room("candeeiro", [lamp], [])
	var frame := WB.model(self, "standing_picture_frame_01", 5.25, 1.2, -110.0, 1.0, top, false)
	var fb := WB.footprint(frame)
	hotspots.photo_frame = Hotspot.add(self, fb.position + fb.size / 2, fb.size + Vector3(0.06, 0.06, 0.06), _prompt("photo_frame"), func(p): _say("photo_frame", p))
	WB.model(self, "wall_clock", 2.7, 4.42, 180.0, 1.0, 1.95, false)
	# curtains, half drawn
	var cloth := WB.flat(Color(0.22, 0.24, 0.27), 0.95)
	for x in [0.75, 2.45, 2.95, 4.65]:
		WB.box(self, Vector3(x - 0.18, 0.4, 0.04), Vector3(x + 0.18, 2.62, 0.1), cloth, false)
	WB.box(self, Vector3(0.4, 2.62, 0.05), Vector3(5.0, 2.65, 0.09), WB.flat(Color(0.2, 0.2, 0.2), 0.4, 0.6), false)
	# the bare bulb from the photo
	_bulb("sala", Vector3(2.7, H, 2.2), 0.55, 1.5, 7.5)
	_switch("sala", Vector3(4.0, 1.2, 4.5 - INT / 2 - 0.01), 180.0, ["sala"])
	_switch("candeeiro", Vector3(5.42, 0.95, 2.45), -90.0, ["candeeiro"], "Ligar o candeeiro")


func _tv(base: Vector3) -> void:
	var black := WB.flat(Color(0.02, 0.02, 0.02), 0.35)
	WB.box(self, base + Vector3(-0.15, 0, -0.1), base + Vector3(0.15, 0.03, 0.08), black, false)
	WB.box(self, base + Vector3(-0.025, 0.03, -0.02), base + Vector3(0.025, 0.12, 0.02), black, false)
	WB.box(self, base + Vector3(-0.62, 0.1, -0.03), base + Vector3(0.62, 0.81, 0.02), black, true)
	var scr := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.2, 0.68)
	scr.mesh = qm
	scr.position = base + Vector3(0, 0.455, -0.032)
	scr.rotation_degrees.y = 180
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded;
uniform float on = 1.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float t = floor(TIME * 0.35);
	float scene = h(vec2(t, 3.0));
	vec3 a = mix(vec3(0.05,0.12,0.3), vec3(0.25,0.32,0.45), scene);
	float shape = smoothstep(0.35, 0.0, distance(uv, vec2(0.3 + 0.4*h(vec2(t,1.0)), 0.5 + 0.2*sin(TIME*0.2))));
	vec3 c = a + shape * vec3(0.5,0.6,0.7) * (0.6 + 0.4*h(vec2(t,7.0)));
	c *= 0.85 + 0.15 * h(uv * 200.0 + TIME);
	c *= 1.0 - 0.15 * step(0.5, fract(uv.y * 240.0));
	ALBEDO = c * 0.9 * on;
}"""
	tv_mat = ShaderMaterial.new()
	tv_mat.shader = sh
	scr.material_override = tv_mat
	add_child(scr)
	tv_light = WB.omni(self, base + Vector3(0, 0.5, -0.6), Color(0.55, 0.68, 1.0), 0.45, 4.5, false)
	hotspots.tv = Hotspot.add(self, base + Vector3(0, 0.455, 0), Vector3(1.24, 0.71, 0.1), "Desligar a televisão", func(_p): set_tv(not tv_on))
	hotspots.tv.dynamic_prompt = func(): return "Desligar a televisão" if tv_on else "Ligar a televisão"


func set_tv(on: bool) -> void:
	tv_on = on and power
	tv_mat.set_shader_parameter("on", 1.0 if tv_on else 0.0)
	tv_light.visible = tv_on
	Audio.play("click_far", -12.0)


func _laptop(at: Vector3) -> void:
	var alu := WB.flat(Color(0.5, 0.51, 0.53), 0.35, 0.8)
	var base := Node3D.new()
	base.position = at
	base.rotation_degrees.y = -90
	add_child(base)
	WB.box(base, Vector3(-0.16, 0, -0.11), Vector3(0.16, 0.015, 0.11), alu, false)
	var lid := Node3D.new()
	lid.position = Vector3(0, 0.015, -0.11)
	lid.rotation_degrees.x = 15
	base.add_child(lid)
	WB.box(lid, Vector3(-0.16, 0, -0.008), Vector3(0.16, 0.21, 0), alu, false)
	laptop_mat = WB.emissive(Color(0.18, 0.22, 0.32), 0.5)
	var scr := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.29, 0.18)
	scr.mesh = qm
	scr.material_override = laptop_mat
	scr.position = Vector3(0, 0.105, 0.001)
	lid.add_child(scr)
	hotspots.laptop = Hotspot.add(self, at + Vector3(0, 0.1, 0), Vector3(0.24, 0.24, 0.34), _prompt("laptop"), func(p): _say("laptop", p))


func _build_quarto() -> void:
	var bed := WB.model(self, "old_bed_frame", 8.95, 2.75, 90.0)
	var bb := WB.footprint(bed)
	var linen := WB.flat(Color(0.78, 0.78, 0.76), 0.9)
	var duvet := WB.flat(Color(0.2, 0.25, 0.32), 0.95)
	WB.box(self, Vector3(bb.position.x + 0.06, 0.36, bb.position.z + 0.06), Vector3(bb.end.x - 0.06, 0.52, bb.end.z - 0.06), linen, false)
	WB.box(self, Vector3(bb.position.x + 0.05, 0.52, bb.position.z + 0.02), Vector3(bb.end.x - 0.55, 0.6, bb.end.z - 0.02), duvet, false)
	WB.box(self, Vector3(bb.end.x - 0.5, 0.52, bb.position.z + 0.15), Vector3(bb.end.x - 0.12, 0.64, bb.end.z - 0.15), linen, false)
	hotspots.bed = Hotspot.add(self, bb.position + bb.size / 2, bb.size, _prompt("bed"), func(p): _say("bed", p))
	var ns := WB.model(self, "painted_wooden_nightstand", 9.7, 1.75, -90.0)
	var ntop := WB.footprint(ns).end.y
	var clock := WB.model(self, "alarm_clock_01", 9.65, 1.75, -90.0, 1.0, ntop, false)
	var cb := WB.footprint(clock)
	hotspots.alarm_clock = Hotspot.add(self, cb.position + cb.size / 2, cb.size + Vector3(0.08, 0.08, 0.08), _prompt("alarm_clock"), func(p): _say("alarm_clock", p))
	var wr := WB.model(self, "vintage_cabinet_01", 8.45, 4.1, 180.0, 0.95)
	var wb := WB.footprint(wr)
	hotspots.wardrobe = Hotspot.add(self, wb.position + wb.size / 2, wb.size, _prompt("wardrobe"), func(p): _say("wardrobe", p))
	var b1 := WB.model(self, "cardboard_box_01", 6.0, 0.55, 10.0)
	WB.model(self, "cardboard_box_01", 6.55, 0.5, -12.0)
	WB.model(self, "cardboard_box_01", 6.05, 0.58, 25.0, 0.9, WB.footprint(b1).end.y, false)
	hotspots.boxes = Hotspot.add(self, Vector3(6.25, 0.4, 0.55), Vector3(1.0, 0.8, 0.7), _prompt("boxes"), func(p): _say("boxes", p))
	_plafond("quarto", Vector3(7.75, H, 2.25))
	_switch("quarto", Vector3(6.95, 1.2, 4.5 - INT / 2 - 0.01), 180.0, ["quarto"])


func _build_corredor() -> void:
	_plafond("corredor", Vector3(2.5, H, 5.15))
	_plafond("corredor", Vector3(7.5, H, 5.15))
	_switch("corredor", Vector3(9.6, 1.2, 4.5 + INT / 2 + 0.01), 0.0, ["corredor"])
	_switch("corredor", Vector3(0.4, 1.2, 4.5 + INT / 2 + 0.01), 0.0, ["corredor"])
	var pic := WB.model(self, "fancy_picture_frame_01", 0.02, 5.15, 90.0, 1.2, 1.25, false)
	var pb := WB.footprint(pic)
	hotspots.corridor_picture = Hotspot.add(self, pb.position + pb.size / 2, pb.size + Vector3(0.06, 0, 0), _prompt("corridor_picture"), func(p): _say("corridor_picture", p))
	# coat hooks and a mat by the front door
	WB.box(self, Vector3(9.2, 0, 4.9), Vector3(9.85, 0.012, 5.4), WB.flat(Color(0.18, 0.15, 0.12), 1.0), false)
	var ph := Hotspot.add(self, Vector3(9.97, 1.55, 5.15), Vector3(0.08, 0.14, 0.14), _prompt("peephole"), func(p): peephole_requested.emit())
	hotspots.peephole = ph
	var eye := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.012
	cm.bottom_radius = 0.012
	cm.height = 0.02
	eye.mesh = cm
	eye.material_override = WB.flat(Color(0.7, 0.62, 0.4), 0.3, 1.0)
	eye.rotation_degrees.z = 90
	eye.position = Vector3(9.97, 1.55, 5.15)
	add_child(eye)




func _build_cozinha() -> void:
	var front := WB.mat("kitchen_wood", 0.8, Color(0.92, 0.9, 0.86))
	var counter := WB.mat("marble_01", 1.2, Color(0.35, 0.34, 0.33))
	var body := WB.flat(Color(0.75, 0.73, 0.7), 0.6)
	var metal := WB.flat(Color(0.7, 0.7, 0.7), 0.25, 0.9)
	# base units along the back wall, stove at 1.2..1.7
	for seg in [[0.06, 1.2], [1.7, 4.45]]:
		var n := int(roundf((seg[1] - seg[0]) / 0.6))
		WB.cabinet(self, Vector3(seg[0], 0.0, 8.38), Vector3(seg[1], 0.86, 8.94), Vector3(0, 0, -1), body, front, n, 0.16, metal)
		WB.worktop(self, Vector3(seg[0], 0.0, 8.38), Vector3(seg[1], 0.86, 8.94), Vector3(0, 0, -1), counter)
	WB.model(self, "electric_stove", 1.45, 8.66, 180.0)
	hotspots.stove = Hotspot.add(self, Vector3(1.45, 0.45, 8.66), Vector3(0.52, 0.9, 0.66), _prompt("stove"), func(p): _say("stove", p))
	# sink under the window
	WB.box(self, Vector3(2.7, 0.9, 8.5), Vector3(3.5, 0.905, 8.85), metal, false)
	WB.box(self, Vector3(2.75, 0.905, 8.53), Vector3(3.45, 0.91, 8.82), WB.flat(Color(0.12, 0.12, 0.13), 0.3, 0.9), false)
	WB.box(self, Vector3(3.08, 0.9, 8.86), Vector3(3.12, 1.2, 8.9), metal, false)
	WB.box(self, Vector3(3.08, 1.17, 8.68), Vector3(3.12, 1.2, 8.9), metal, false)
	WB.model(self, "vintage_microwave", 4.05, 8.68, 180.0, 0.45, 0.9, false)
	WB.model(self, "wooden_cutting_board", 2.2, 8.72, 15.0, 1.0, 0.9, false)
	WB.model(self, "jug_01", 0.5, 8.7, 160.0, 1.0, 0.9, false)
	WB.model(self, "wine_bottles_01", 4.2, 8.85, 180.0, 1.0, 0.9, false)
	# wall units on the left
	WB.cabinet(self, Vector3(0.06, 1.5, 8.58), Vector3(2.38, 2.2, 8.94), Vector3(0, 0, -1), body, front, 4, 0.0, metal)
	# fridge
	var white := WB.flat(Color(0.88, 0.88, 0.86), 0.3, 0.1)
	WB.box(self, Vector3(4.6, 0, 8.28), Vector3(5.3, 1.85, 8.94), white)
	WB.box(self, Vector3(5.18, 1.3, 8.24), Vector3(5.21, 1.75, 8.27), metal, false, "", 0.0)
	WB.box(self, Vector3(5.18, 0.75, 8.24), Vector3(5.21, 1.12, 8.27), metal, false, "", 0.0)
	WB.box(self, Vector3(4.61, 1.22, 8.27), Vector3(5.29, 1.235, 8.28), WB.flat(Color(0.3, 0.3, 0.3), 0.5), false)
	WB.box(self, Vector3(4.66, 1.3, 8.24), Vector3(4.68, 1.7, 8.27), metal, false)
	WB.box(self, Vector3(4.66, 0.75, 8.24), Vector3(4.68, 1.15, 8.27), metal, false)
	hotspots.fridge = Hotspot.add(self, Vector3(4.95, 0.95, 8.6), Vector3(0.72, 1.9, 0.7), _prompt("fridge"), func(p): _say("fridge", p))
	# calendar on the wall by the fridge
	var cal := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.32, 0.45)
	cal.mesh = qm
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = _calendar_texture()
	cm.roughness = 0.85
	cal.material_override = cm
	cal.position = Vector3(5.5 - INT / 2 - 0.015, 1.55, 7.6)
	cal.rotation_degrees.y = -90
	add_child(cal)
	hotspots.calendar = Hotspot.add(self, cal.position, Vector3(0.05, 0.47, 0.34), _prompt("calendar"), func(p): _say("calendar", p))
	# table and chairs
	WB.model(self, "round_wooden_table_01", 1.5, 6.95, 0.0, 0.68)
	WB.model(self, "dining_chair_02", 0.78, 6.95, 90.0)
	WB.model(self, "dining_chair_02", 2.2, 6.75, -100.0)
	_plafond("cozinha", Vector3(2.75, H, 7.3))
	_switch("cozinha", Vector3(2.6, 1.2, 5.8 + INT / 2 + 0.01), 0.0, ["cozinha"])


func _calendar_texture() -> Texture2D:
	var img := Image.create(256, 360, false, Image.FORMAT_RGB8)
	img.fill(Color(0.95, 0.94, 0.9))
	img.fill_rect(Rect2i(0, 0, 256, 120), Color(0.32, 0.42, 0.5))
	img.fill_rect(Rect2i(14, 14, 228, 92), Color(0.5, 0.58, 0.6))
	var ink := Color(0.25, 0.25, 0.27)
	# a 7 x 5 grid of days; October 2026 starts on a Thursday
	for r in 6:
		img.fill_rect(Rect2i(10, 150 + r * 34, 236, 1), Color(0.75, 0.75, 0.73))
	for c in 8:
		img.fill_rect(Rect2i(10 + c * 33, 150, 1, 170), Color(0.75, 0.75, 0.73))
	for d in 31:
		var cell := d + 3
		var cx := 10 + (cell % 7) * 33
		var cy := 150 + (cell / 7) * 34
		img.fill_rect(Rect2i(cx + 4, cy + 4, 8 + (d % 3) * 2, 3), ink)
		if d + 1 == 14:
			for a in 40:
				var ang := TAU * a / 40.0
				for th in 2:
					img.set_pixel(clampi(cx + 16 + int(cos(ang) * (14 + th)), 0, 255), clampi(cy + 17 + int(sin(ang) * (13 + th)), 0, 359), Color(0.75, 0.1, 0.1))
	img.fill_rect(Rect2i(120, 330, 60, 3), Color(0.75, 0.1, 0.1))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _build_wc() -> void:
	var ceramic := WB.flat(Color(0.93, 0.93, 0.92), 0.12)
	# bathtub along the back wall
	WB.box(self, Vector3(5.57, 0, 8.22), Vector3(7.3, 0.55, 8.94), ceramic, true)
	WB.box(self, Vector3(5.65, 0.2, 8.3), Vector3(7.22, 0.555, 8.86), WB.flat(Color(0.86, 0.87, 0.87), 0.08), false)
	# toilet against the east wall
	var t := Node3D.new()
	t.position = Vector3(7.62, 0, 7.0)
	add_child(t)
	var c1 := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.2
	cy.bottom_radius = 0.14
	cy.height = 0.4
	c1.mesh = cy
	c1.material_override = ceramic
	c1.position = Vector3(-0.08, 0.2, 0)
	c1.scale = Vector3(1.25, 1, 0.95)
	t.add_child(c1)
	WB.box(t, Vector3(-0.38, 0.4, -0.18), Vector3(0.12, 0.43, 0.18), ceramic, false)
	WB.box(t, Vector3(0.12, 0.4, -0.2), Vector3(0.32, 0.82, 0.2), ceramic, false)
	WB.box(t, Vector3(-0.3, 0, -0.18), Vector3(0.3, 0.42, 0.18), ceramic, true).visible = false
	# washbasin and mirror on the west wall
	var sink := Node3D.new()
	sink.position = Vector3(5.56, 0, 6.65)
	add_child(sink)
	WB.box(sink, Vector3(0, 0.78, -0.27), Vector3(0.45, 0.9, 0.27), ceramic, true)
	WB.box(sink, Vector3(0.06, 0.86, -0.2), Vector3(0.38, 0.905, 0.2), WB.flat(Color(0.82, 0.83, 0.84), 0.06), false)
	var ped := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.09
	pc.bottom_radius = 0.12
	pc.height = 0.78
	ped.mesh = pc
	ped.material_override = ceramic
	ped.position = Vector3(0.2, 0.39, 0)
	sink.add_child(ped)
	var metal := WB.flat(Color(0.75, 0.75, 0.75), 0.15, 1.0)
	WB.box(sink, Vector3(0.03, 0.9, -0.02), Vector3(0.12, 1.05, 0.02), metal, false)
	WB.box(sink, Vector3(0.03, 1.02, -0.02), Vector3(0.2, 1.05, 0.02), metal, false)
	mirror = WB.box(sink, Vector3(0.0, 1.2, -0.3), Vector3(0.03, 1.9, 0.3), WB.flat(Color(0.9, 0.92, 0.94), 0.02, 1.0), false)
	hotspots.mirror = Hotspot.add(self, Vector3(5.6, 1.55, 6.65), Vector3(0.06, 0.7, 0.6), _prompt("mirror"), func(p): _say("mirror", p))
	# a small shelf with the pills
	WB.box(sink, Vector3(0.0, 1.12, -0.25), Vector3(0.12, 1.14, 0.25), WB.flat(Color(0.85, 0.85, 0.85), 0.3), false)
	WB.box(sink, Vector3(0.03, 1.14, 0.08), Vector3(0.08, 1.2, 0.17), WB.flat(Color(0.9, 0.9, 0.95), 0.5), false)
	WB.box(sink, Vector3(0.03, 1.14, -0.15), Vector3(0.09, 1.17, -0.05), WB.flat(Color(0.25, 0.4, 0.7), 0.5), false)
	hotspots.pills = Hotspot.add(self, Vector3(5.62, 1.16, 6.65), Vector3(0.12, 0.08, 0.5), _prompt("pills"), func(p): _say("pills", p))
	var probe := ReflectionProbe.new()
	probe.position = Vector3(6.75, 1.45, 7.4)
	probe.size = Vector3(2.5, 2.9, 3.2)
	probe.box_projection = true
	probe.interior = true
	probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	add_child(probe)
	_probes.append(probe)
	_plafond("wc", Vector3(6.75, H, 7.4), 0.9)
	_switch("wc", Vector3(7.05, 1.2, 5.8 - INT / 2 - 0.01), 180.0, ["wc"])


func _build_arrumos() -> void:
	var wood := WB.mat("kitchen_wood", 1.0, Color(0.6, 0.5, 0.4))
	for y in [0.4, 0.9, 1.4, 1.9]:
		WB.box(self, Vector3(9.55, y, 6.0), Vector3(9.94, y + 0.025, 8.9), wood, false)
	WB.model(self, "cardboard_box_01", 9.72, 6.6, 90.0, 0.9, 0.425, false)
	WB.model(self, "cardboard_box_01", 9.72, 7.6, 80.0, 0.8, 0.925, false)
	WB.model(self, "trashbag", 8.6, 8.5, 30.0)
	# fusebox
	var grey := WB.flat(Color(0.7, 0.7, 0.68), 0.5)
	WB.box(self, Vector3(8.06, 1.4, 6.05), Vector3(8.14, 1.8, 6.35), grey, false)
	hotspots.fusebox = Hotspot.add(self, Vector3(8.1, 1.6, 6.2), Vector3(0.1, 0.42, 0.32), "Desligar a luz da casa", func(_p): set_power(not power))
	hotspots.fusebox.dynamic_prompt = func(): return "Desligar a luz da casa" if power else "Ligar a luz da casa"
	_bulb("arrumos", Vector3(9.0, H, 7.4), 0.35, 0.8, 4.0)
	_switch("arrumos", Vector3(9.55, 1.2, 5.8 + INT / 2 + 0.01), 0.0, ["arrumos"])


# =================================================================== outside
func _build_outside() -> void:
	var facade := WB.mat("painted_plaster_wall", 3.0, Color(0.85, 0.8, 0.7))
	var pav := WB.mat("stone_pavers", 1.4, Color(0.7, 0.7, 0.7))
	var asphalt := WB.mat("asphalt_06", 4.0, Color(0.6, 0.6, 0.6))
	# our building: facade cladding on the street and the floors above
	WB.wall(self, "x", -EXT - 0.01, -20, 30, 14, 0.02, facade, [[1.0, 2.2, 0.95, 2.45], [3.2, 4.4, 0.95, 2.45], [7.1, 8.5, 0.95, 2.45]])
	WB.box(self, Vector3(-20, -0.6, -EXT), Vector3(-EXT, 14, 9), facade)
	WB.box(self, Vector3(10 + EXT, -0.6, -EXT), Vector3(30, 14, 3.3), facade)
	WB.box(self, Vector3(-EXT, -0.6, -EXT), Vector3(10 + EXT, -0.1, 9 + EXT), facade)
	_dark_windows(-EXT - 0.03, -20, 30, [1.0, 3.6, 6.6, 9.6], 1.0, 0.0)
	# street
	WB.box(self, Vector3(-40, -1.0, -2.6), Vector3(50, -0.45, -EXT), pav)
	WB.box(self, Vector3(-40, -1.0, -2.75), Vector3(50, -0.45, -2.6), WB.flat(Color(0.55, 0.55, 0.53), 0.8))
	WB.box(self, Vector3(-40, -1.2, -9.4), Vector3(50, -0.6, -2.75), asphalt)
	WB.box(self, Vector3(-40, -1.0, -11.6), Vector3(50, -0.45, -9.4), pav)
	# the building across the street
	WB.box(self, Vector3(-40, -0.6, -16), Vector3(50, 15, -11.6), facade)
	_dark_windows(-11.58, -40, 50, [0.4, 3.4, 6.4, 9.4, 12.4], -1.0, 0.18)
	# lamps
	var lamp := WB.model(self, "street_lamp_01", 3.0, -2.35, 0.0, 1.0, -0.45)
	street_lamp = _street_light(Vector3(3.0, 3.25, -2.6))
	street_lamp_bulb = _lamp_bulb(lamp)
	WB.model(self, "street_lamp_01", -12.0, -9.75, 180.0, 1.0, -0.45)
	_street_light(Vector3(-12.0, 3.25, -9.5))
	WB.model(self, "street_lamp_01", 18.0, -9.75, 180.0, 1.0, -0.45)
	_street_light(Vector3(18.0, 3.25, -9.5))
	# the one right across, seen from the sofa
	WB.model(self, "street_lamp_01", 4.5, -9.75, 180.0, 1.0, -0.45)
	_street_light(Vector3(4.5, 3.25, -9.5))
	WB.model(self, "covered_car", 7.2, -3.7, 90.0, 1.0, -0.6)
	WB.model(self, "metal_trash_can", -2.2, -1.9, 0.0, 1.0, -0.45)
	# moonlight
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-38, 155, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.06
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
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
	l.spot_attenuation = 1.1
	l.shadow_enabled = true
	l.light_volumetric_fog_energy = 1.2
	add_child(l)
	street_lights.append(l)
	# light that spills sideways (walls, windows)
	var o := WB.omni(self, at + Vector3(0, -0.4, 0), STREET_SODIUM, 0.7, 9.0, false)
	o.light_volumetric_fog_energy = 0.3
	l.set_meta("fill", o)
	return l


func _lamp_bulb(lamp: Node3D) -> StandardMaterial3D:
	var m := WB.emissive(STREET_SODIUM, 4.0)
	var fb := WB.footprint(lamp)
	var b := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.12
	b.mesh = sm
	b.material_override = m
	b.position = Vector3(fb.position.x + fb.size.x / 2, fb.end.y - 0.32, fb.position.z + fb.size.z / 2)
	add_child(b)
	return m


## Windows of the other flats: dark glass, a few lit behind curtains.
func _dark_windows(z: float, x0: float, x1: float, floors: Array, facing: float, lit_chance: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1012 + int(z * 10)
	var dark := WB.flat(Color(0.03, 0.035, 0.045), 0.08, 0.3)
	var lits := [WB.emissive(Color(0.85, 0.5, 0.26), 0.16), WB.emissive(Color(0.55, 0.62, 0.9), 0.1), WB.emissive(Color(0.9, 0.62, 0.35), 0.22)]
	for m in lits:
		m.set_meta("energy", m.emission_energy_multiplier)
		lit_windows.append(m)
	var frame := WB.flat(Color(0.75, 0.73, 0.7), 0.5)
	for fy in floors:
		var x := x0 + 1.0
		while x < x1 - 1.5:
			if not (absf(z + EXT) < 0.1 and fy < 3.0 and x > -0.5 and x < 10.5):
				var m: Material = lits[rng.randi() % lits.size()] if rng.randf() < lit_chance else dark
				WB.box(self, Vector3(x - 0.06, fy - 0.06, z - 0.02), Vector3(x + 1.26, fy + 1.66, z + 0.0), frame, false)
				WB.box(self, Vector3(x, fy, z - 0.03 * facing), Vector3(x + 1.2, fy + 1.6, z - 0.031 * facing), m, false)
			x += 3.4


# =================================================================== landing
func _build_landing() -> void:
	var stone := WB.mat("marble_01", 1.5, Color(0.7, 0.68, 0.64))
	var wall := WB.mat("painted_plaster_wall", 2.5, Color(0.75, 0.72, 0.62))
	WB.box(self, Vector3(10 + EXT, -0.1, 3.3), Vector3(13, 0, 7.5), stone)
	WB.box(self, Vector3(10 + EXT, H, 3.3), Vector3(13, H + 0.1, 7.5), m_ceiling)
	WB.box(self, Vector3(13, 0, 3.3), Vector3(13.2, H, 7.5), wall)
	WB.box(self, Vector3(10 + EXT, 0, 3.1), Vector3(13, H, 3.3), wall)
	WB.box(self, Vector3(10 + EXT, 0, 7.5), Vector3(13, H, 7.7), wall)
	# stairs going up to the first floor
	for i in 9:
		WB.box(self, Vector3(11.6, 0, 5.0 + i * 0.28), Vector3(12.95, (i + 1) * 0.17, 7.5), stone)
	# mailboxes
	WB.box(self, Vector3(10.35, 1.0, 3.35), Vector3(11.5, 1.6, 3.5), WB.flat(Color(0.35, 0.32, 0.26), 0.4, 0.6), false)
	landing_light = WB.omni(self, Vector3(11.5, H - 0.2, 5.4), Color(1.0, 0.85, 0.62), 0.9, 5.0, true)
	landing_light.visible = false
	# what little comes in through the glass of the street door downstairs
	WB.omni(self, Vector3(10.8, 0.6, 3.6), Color(0.6, 0.62, 0.75), 0.12, 4.0, false)


## The timed light on the landing (someone came in).
func landing_on(secs := 30.0) -> void:
	landing_light.visible = true
	Audio.play("click_far", -14.0)
	await get_tree().create_timer(secs).timeout
	if is_instance_valid(landing_light):
		landing_light.visible = false
	# what little comes in through the glass of the street door downstairs
	WB.omni(self, Vector3(10.8, 0.6, 3.6), Color(0.6, 0.62, 0.75), 0.12, 4.0, false)


func _process(delta: float) -> void:
	_t += delta
	if tv_on and tv_light:
		tv_light.light_energy = 0.4 + 0.12 * sin(_t * 2.3) + 0.08 * sin(_t * 7.1 + 1.0) + (0.1 if fmod(_t, 2.857) < 0.08 else 0.0)
	# the street lamp in front has been blinking for weeks
	_street_flicker -= delta
	if _street_flicker <= 0.0:
		_street_flicker = randf_range(6.0, 22.0)
		_blink_street()


func _on_power(on: bool) -> void:
	if not on:
		set_tv(false)
	laptop_mat.emission_energy_multiplier = 0.5 if on else 0.0


## 0 = full night, 1 = full day: street lamps, the moon, the windows across.
func set_daylight(d: float) -> void:
	var night := d < 0.35
	for l in street_lights:
		l.visible = night
		var fill: OmniLight3D = l.get_meta("fill")
		fill.visible = night
	if street_lamp_bulb:
		street_lamp_bulb.emission_energy_multiplier = 4.0 if night else 0.0
	for m in lit_windows:
		m.emission_energy_multiplier = float(m.get_meta("energy")) * (1.0 - d)
	moon.visible = d < 0.5
	for f in sky_fills:
		f.visible = d > 0.02
		f.light_energy = float(f.get_meta("base")) * d

func _blink_street() -> void:
	if not street_lamp or not street_lamp.is_visible_in_tree() or not street_lights[0].visible:
		return
	var fill: OmniLight3D = street_lamp.get_meta("fill")
	for i in randi_range(2, 5):
		if street_lamp_bulb.emission_energy_multiplier == 0.0 and not street_lamp.visible:
			return
		street_lamp.visible = false
		fill.visible = false
		street_lamp_bulb.emission_energy_multiplier = 0.2
		await get_tree().create_timer(randf_range(0.05, 0.25)).timeout
		var still_night := moon.visible and street_lights.size() > 1 and street_lights[1].visible
		street_lamp.visible = still_night
		fill.visible = still_night
		street_lamp_bulb.emission_energy_multiplier = 4.0 if still_night else 0.0
		if not still_night:
			return
		await get_tree().create_timer(randf_range(0.05, 0.3)).timeout


## What the floor is made of under a point (for footsteps).
func floor_kind(p: Vector3) -> String:
	if p.z > 5.8 and p.x < 10.0:
		return "tile"
	return "wood"


