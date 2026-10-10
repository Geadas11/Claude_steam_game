class_name SofiaHome
extends Location
## Sofia's flat, Lisbon: second floor of an old building in Arroios. Tall
## ceilings with a plaster cornice, herringbone parquet that creaks, a sala
## over the street with two tall windows, a small kitchen with the night-shift
## rota on the fridge, the bedroom with the nightstand drawer where Daniel's
## old phone has been since last October — wet, in a freezer bag, never on.
##
##   x0..9 z0..9 (street at z<0) · sala x0..5 z0..4.5 · cozinha x5..9 z0..4.5
##   corredor z4.5..5.7 · quarto x0..5 · wc x5..7.2 · arrumos x7.2..9 (z5.7..9)

const H := 3.0
const EXT := 0.3
const INT := 0.12
const STREET_SODIUM := Color(1.0, 0.62, 0.3)

var rng := RandomNumberGenerator.new()
var sky_fills: Array[OmniLight3D] = []
var street_lights: Array[SpotLight3D] = []
var lit_windows: Array[StandardMaterial3D] = []
var moon: DirectionalLight3D
var drawer: Node3D


func _ready() -> void:
	load_texts("sofia_casa")
	rng.seed = 202
	m_wall = WB.mat("white_plaster_02", 2.5, Color(0.96, 0.95, 0.92))
	m_ceiling = WB.flat(Color(0.93, 0.92, 0.89), 0.9)
	m_paint = WB.flat(Color(0.93, 0.92, 0.88), 0.4)
	m_skirt = WB.flat(Color(0.9, 0.89, 0.85), 0.5)
	_build_shell()
	_build_sala()
	_build_kitchen()
	_build_bedroom()
	_build_small_rooms()
	_build_outside()
	_build_story_hooks()


# =================================================================== shell
func _build_shell() -> void:
	var parquet := WB.mat("herringbone_parquet", 1.2, Color(0.82, 0.68, 0.52))
	WB.box(self, Vector3(0, -0.1, 0), Vector3(9, 0, 9), parquet)
	WB.box(self, Vector3(5.0, -0.09, 5.7), Vector3(7.2, 0.005, 9), WB.mat("grey_tiles", 1.0, Color(0.9, 0.9, 0.9)), false)
	WB.box(self, Vector3(5.0, -0.09, 0), Vector3(9, 0.005, 4.5), WB.mat("terrazzo_tiles", 1.0, Color(0.9, 0.88, 0.85)), false)
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(9 + EXT, H + 0.15, 9 + EXT), m_ceiling)
	# the cornice: a stepped plaster band under the ceiling, all round
	for r in [[0.0, 5.0, 0.0, 4.5], [5.0, 9.0, 0.0, 4.5], [0.0, 5.0, 5.7, 9.0]]:
		WB.box(self, Vector3(r[0], H - 0.12, r[2]), Vector3(r[1], H, r[2] + 0.1), m_paint, false)
		WB.box(self, Vector3(r[0], H - 0.12, r[3] - 0.1), Vector3(r[1], H, r[3]), m_paint, false)
		WB.box(self, Vector3(r[0], H - 0.12, r[2]), Vector3(r[0] + 0.1, H, r[3]), m_paint, false)
		WB.box(self, Vector3(r[1] - 0.1, H - 0.12, r[2]), Vector3(r[1], H, r[3]), m_paint, false)
	# a ceiling rose in the sala
	var rose := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.26
	cyl.height = 0.05
	rose.mesh = cyl
	rose.material_override = m_paint
	rose.position = Vector3(2.5, H - 0.025, 2.2)
	add_child(rose)
	# outer walls: tall windows on the street, one at the back of the bedroom
	var front := [[1.0, 2.1, 0.5, 2.6], [3.0, 4.1, 0.5, 2.6], [6.4, 7.6, 0.9, 2.4]]
	WB.wall(self, "x", -EXT / 2, -EXT, 9 + EXT, H, EXT, m_wall, front)
	WB.wall(self, "x", 9 + EXT / 2, -EXT, 9 + EXT, H, EXT, m_wall, [[1.8, 3.2, 0.9, 2.4], [5.6, 6.6, 1.2, 2.2]])
	WB.wall(self, "z", -EXT / 2, 0, 9, H, EXT, m_wall)
	WB.wall(self, "z", 9 + EXT / 2, 0, 9, H, EXT, m_wall, [[4.6, 5.6, 0.0, 2.25]])
	# inner walls
	WB.wall(self, "z", 5.0, 0, 4.5, H, INT, m_wall, [[1.6, 2.5, 0.0, 2.2]])
	WB.wall(self, "x", 4.5, 0, 9, H, INT, m_wall, [[3.6, 4.6, 0.0, 2.3], [6.6, 7.5, 0.0, 2.15]])
	WB.wall(self, "x", 5.7, 0, 9, H, INT, m_wall, [[3.6, 4.4, 0.0, 2.15], [5.6, 6.4, 0.0, 2.15], [7.6, 8.4, 0.0, 2.15]])
	WB.wall(self, "z", 5.0, 5.7, 9, H, INT, m_wall)
	WB.wall(self, "z", 7.2, 5.7, 9, H, INT, m_wall)
	# skirting
	for s in [[0.0, 5.0, 0.012], [0.0, 3.6, 4.44], [4.6, 5.0, 4.44]]:
		WB.box(self, Vector3(s[0], 0, s[2] - 0.006), Vector3(s[1], 0.12, s[2] + 0.006), m_skirt, false)
	for w in front:
		_window(w, 0.0, -1.0)
	_window([1.8, 3.2, 0.9, 2.4], 9.0, 1.0)
	_window([5.6, 6.6, 1.2, 2.2], 9.0, 1.0)
	doors.entrada = Door.make(self, Vector3(9.0, 0, 4.6), "z", 1.0, 2.25, WB.mat("dark_wood", 1.0, Color(0.45, 0.32, 0.22)), -1.0)
	doors.entrada.locked = true
	doors.entrada.locked_text = _first_text("porta_entrada")
	doors.quarto = Door.make(self, Vector3(3.6, 0, 5.7), "x", 0.8, 2.15, m_paint, 1.0)
	doors.wc = Door.make(self, Vector3(5.6, 0, 5.7), "x", 0.8, 2.15, m_paint, 1.0)
	doors.arrumos = Door.make(self, Vector3(7.6, 0, 5.7), "x", 0.8, 2.15, m_paint, 1.0)
	doors.cozinha = Door.make(self, Vector3(6.6, 0, 4.5), "x", 0.9, 2.15, m_paint, -1.0)
	doors.quarto.leaf.rotation_degrees.y = 40.0
	doors.quarto.is_open = true
	room_bounds = {
		"sala": AABB(Vector3(0, 0, 0), Vector3(5, H, 4.5)),
		"cozinha": AABB(Vector3(5, 0, 0), Vector3(4, H, 4.5)),
		"corredor": AABB(Vector3(0, 0, 4.5), Vector3(9, H, 1.2)),
		"quarto": AABB(Vector3(0, 0, 5.7), Vector3(5, H, 3.3)),
		"wc": AABB(Vector3(5, 0, 5.7), Vector3(2.2, H, 3.3)),
		"arrumos": AABB(Vector3(7.2, 0, 5.7), Vector3(1.8, H, 3.3)),
	}


func _window(w: Array, at: float, out: float) -> void:
	var frame := WB.flat(Color(0.94, 0.94, 0.92), 0.4)
	var mid := at + out * EXT / 2
	var x0: float = w[0]
	var x1: float = w[1]
	var y0: float = w[2]
	var y1: float = w[3]
	var bars := [[x0, x0 + 0.06, y0, y1], [x1 - 0.06, x1, y0, y1], [x0, x1, y0, y0 + 0.06], [x0, x1, y1 - 0.06, y1],
		[(x0 + x1) / 2 - 0.03, (x0 + x1) / 2 + 0.03, y0, y1], [x0, x1, y1 - 0.5, y1 - 0.45]]
	for p in bars:
		WB.box(self, Vector3(p[0], p[2], mid - 0.04), Vector3(p[1], p[3], mid + 0.04), frame, false)
	WB.box(self, Vector3(x0 + 0.06, y0 + 0.06, mid - 0.005), Vector3(x1 - 0.06, y1 - 0.06, mid + 0.005), WB.glass(), true)
	WB.box(self, Vector3(x0 - 0.06, y0 - 0.04, at - out * 0.08), Vector3(x1 + 0.06, y0, mid), WB.mat("marble_01", 1.0), false)
	# wooden inside shutters, folded open
	var shutter := WB.flat(Color(0.9, 0.89, 0.85), 0.5)
	WB.box(self, Vector3(x0 - 0.32, y0, at - out * 0.04), Vector3(x0 - 0.04, y1, at - out * 0.07), shutter, false)
	WB.box(self, Vector3(x1 + 0.04, y0, at - out * 0.04), Vector3(x1 + 0.32, y1, at - out * 0.07), shutter, false)
	var fill := WB.omni(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, at - out * 0.9), Color(0.8, 0.85, 0.95), 0.0, 5.5, false)
	fill.set_meta("base", 1.8)
	fill.visible = false
	sky_fills.append(fill)


# =================================================================== sala
func _build_sala() -> void:
	var sofa := WB.model(self, "sofa_03", 0.55, 2.3, 90.0)
	WB.model(self, "throw_pillows_01", 0.6, 1.7, 90.0, 1.0, 0.45, false)
	WB.model(self, "modern_coffee_table_01", 1.75, 2.3, 90.0)
	# a rug
	WB.box(self, Vector3(1.1, 0.0, 1.3), Vector3(3.0, 0.012, 3.3), WB.flat(Color(0.45, 0.22, 0.2), 0.95), false)
	Books.pile(self, Vector3(1.8, 0.42, 2.0), 3, rng, 0.0)
	WB.model(self, "wooden_bookshelf_worn", 3.4, 4.25, 180.0)
	Books.unit(self, Vector3(1.4, 0, 4.38), 180.0, 1.5, 2.0, 0.3, [0.45, 0.9, 1.35, 1.8], WB.mat("dark_wood", 1.0, Color(0.7, 0.6, 0.5)), rng)
	WB.model(self, "potted_plant_02", 4.5, 0.5, 30.0)
	WB.model(self, "potted_plant_04", 0.45, 0.45, 0.0)
	var st := WB.model(self, "side_table_01", 0.5, 3.6, 0.0)
	var top := WB.footprint(st).end.y
	WB.model(self, "standing_picture_frame_01", 0.5, 3.6, 120.0, 1.3, top, false)
	hotspots.fotografia = Hotspot.add(self, Vector3(0.5, top + 0.12, 3.6), Vector3(0.3, 0.3, 0.3), _prompt("fotografia"), func(p): _say("fotografia", p))
	WB.model(self, "wall_clock", 4.94, 3.2, -90.0, 1.0, 2.2, false)
	hotspots.relogio = Hotspot.add(self, Vector3(4.9, 2.3, 3.2), Vector3(0.12, 0.4, 0.4), _prompt("relogio"), func(p): _say("relogio", p))
	WB.model(self, "modern_arm_chair_01", 3.4, 1.4, -120.0)
	hotspots.janela = Hotspot.add(self, Vector3(2.0, 1.5, 0.1), Vector3(3.6, 2.0, 0.2), _prompt("janela"), func(p): _say("janela", p))
	WB.pendant(self, "sala", Vector3(2.5, H, 2.2), 0.9, 1.3, 7.0, Color(0.92, 0.88, 0.78))
	var lamp := WB.omni(self, Vector3(0.5, 1.3, 3.6), Color(1.0, 0.8, 0.55), 0.6, 3.5, true)
	_room("candeeiro", [lamp], [])
	_switch("sala", Vector3(4.92, 1.2, 4.0), -90.0, ["sala"])


# =================================================================== kitchen
func _build_kitchen() -> void:
	var wood := WB.mat("kitchen_wood", 1.0, Color(0.88, 0.85, 0.8))
	var counter := WB.mat("marble_01", 1.0, Color(0.75, 0.73, 0.7))
	WB.box(self, Vector3(8.35, 0, 0.3), Vector3(8.95, 0.88, 4.0), wood)
	WB.box(self, Vector3(8.32, 0.88, 0.28), Vector3(8.98, 0.92, 4.02), counter, false)
	WB.box(self, Vector3(8.6, 1.5, 0.3), Vector3(8.95, 2.2, 4.0), wood)
	WB.model(self, "electric_stove", 8.62, 2.6, -90.0)
	WB.model(self, "vintage_microwave", 8.6, 0.8, -90.0, 1.0, 0.92, false)
	WB.model(self, "jug_01", 8.6, 3.5, 0.0, 1.0, 0.92, false)
	# the fridge with the rota
	WB.box(self, Vector3(5.15, 0, 3.75), Vector3(5.85, 1.85, 4.4), WB.flat(Color(0.92, 0.92, 0.9), 0.3, 0.1))
	var rota := WB.flat(Color(0.98, 0.98, 0.95), 0.9)
	WB.box(self, Vector3(5.3, 1.2, 3.74), Vector3(5.6, 1.6, 3.745), rota, false)
	WB.text(self, "TURNOS OUT.", Vector3(5.45, 1.55, 3.735), 180.0, 0.025, Color(0.1, 0.2, 0.5))
	hotspots.frigorifico = Hotspot.add(self, Vector3(5.5, 1.3, 3.75), Vector3(0.7, 0.6, 0.1), _prompt("frigorifico"), func(p): _say("frigorifico", p))
	WB.model(self, "round_wooden_table_01", 6.6, 1.9, 0.0, 0.6)
	WB.model(self, "dining_chair_02", 6.0, 1.9, 90.0)
	WB.model(self, "dining_chair_02", 7.2, 2.2, -100.0)
	WB.model(self, "wine_bottles_01", 6.7, 1.9, 0.0, 0.8, 0.72, false)
	_plafond("cozinha", Vector3(7.0, H, 2.2), 1.3)
	_switch("cozinha", Vector3(6.5, 1.2, 4.43), 0.0, ["cozinha"])


# =================================================================== bedroom
func _build_bedroom() -> void:
	var bed := WB.model(self, "old_bed_frame", 1.6, 7.6, 90.0)
	var bb := WB.footprint(bed)
	WB.box(self, Vector3(bb.position.x + 0.06, 0.36, bb.position.z + 0.06), Vector3(bb.end.x - 0.06, 0.52, bb.end.z - 0.06), WB.flat(Color(0.88, 0.88, 0.86), 0.9), false)
	WB.box(self, Vector3(bb.position.x + 0.4, 0.52, bb.position.z + 0.04), Vector3(bb.end.x - 0.03, 0.6, bb.end.z - 0.04), WB.flat(Color(0.2, 0.3, 0.42), 0.95), false)
	hotspots.cama = Hotspot.add(self, bb.get_center() + Vector3(0, 0.3, 0), Vector3(bb.size.x, 0.4, bb.size.z), _prompt("cama"), func(p): _say("cama", p))
	# the nightstand and its drawer
	drawer = WB.model(self, "painted_wooden_nightstand", 0.35, 6.25, 90.0, 0.9)
	var nt := WB.footprint(drawer)
	WB.model(self, "alarm_clock_01", 0.35, 6.25, 60.0, 1.0, nt.end.y, false)
	hotspots.gaveta = Hotspot.add(self, nt.get_center(), nt.size + Vector3(0.06, 0.06, 0.06), _prompt("gaveta"), func(p): _say("gaveta", p))
	WB.model(self, "vintage_cabinet_01", 4.6, 7.4, -90.0, 0.8)
	# her scrubs on the chair
	WB.model(self, "dining_chair_02", 3.6, 6.3, 200.0)
	WB.box(self, Vector3(3.4, 0.5, 6.2), Vector3(3.8, 0.56, 6.5), WB.flat(Color(0.25, 0.45, 0.6), 0.95), false)
	WB.box(self, Vector3(3.42, 0.56, 6.48), Vector3(3.78, 0.95, 6.52), WB.flat(Color(0.25, 0.45, 0.6), 0.95), false)
	hotspots.farda = Hotspot.add(self, Vector3(3.6, 0.7, 6.35), Vector3(0.5, 0.5, 0.5), _prompt("farda"), func(p): _say("farda", p))
	var l := WB.omni(self, Vector3(2.5, 2.6, 7.3), Color(1.0, 0.85, 0.65), 0.8, 4.5, true)
	_room("quarto", [l], [])
	var bedside := WB.omni(self, Vector3(0.35, 1.0, 6.25), Color(1.0, 0.78, 0.5), 0.35, 2.2, true)
	_room("cabeceira", [bedside], [])
	_switch("quarto", Vector3(3.4, 1.2, 5.77), 0.0, ["quarto"])


# =================================================================== corridor, wc, storage
func _build_small_rooms() -> void:
	# corridor: a coat rack with her hospital lanyard, shoes
	WB.box(self, Vector3(8.6, 1.6, 5.62), Vector3(8.9, 1.64, 5.68), WB.flat(Color(0.3, 0.25, 0.2), 0.6), false)
	WB.box(self, Vector3(8.65, 1.1, 5.6), Vector3(8.72, 1.6, 5.64), WB.flat(Color(0.2, 0.35, 0.6), 0.8), false)
	WB.box(self, Vector3(8.62, 1.05, 5.59), Vector3(8.75, 1.12, 5.64), WB.flat(Color(0.95, 0.95, 0.95), 0.5), false)
	hotspots.cordao = Hotspot.add(self, Vector3(8.7, 1.3, 5.6), Vector3(0.3, 0.6, 0.15), _prompt("cordao"), func(p): _say("cordao", p))
	_bulb("corredor", Vector3(4.5, H, 5.1), 0.4, 0.8, 5.0)
	_switch("corredor", Vector3(8.93, 1.2, 4.75), -90.0, ["corredor"])
	# wc: tiles to shoulder height, a sink, a mirror
	var tiles := WB.mat("long_white_tiles", 1.0, Color(0.95, 0.95, 0.95))
	WB.wall(self, "z", 5.07, 5.7, 9, 1.6, 0.012, tiles)
	WB.wall(self, "z", 7.13, 5.7, 9, 1.6, 0.012, tiles)
	WB.wall(self, "x", 8.93, 5.0, 7.2, 1.6, 0.012, tiles)
	var porcelain := WB.flat(Color(0.95, 0.95, 0.94), 0.2)
	WB.box(self, Vector3(5.6, 0.8, 8.5), Vector3(6.3, 0.9, 8.95), porcelain)
	WB.box(self, Vector3(5.85, 0, 8.65), Vector3(6.05, 0.8, 8.9), porcelain, false)
	var mirror := StandardMaterial3D.new()
	mirror.albedo_color = Color(0.7, 0.72, 0.75)
	mirror.metallic = 1.0
	mirror.roughness = 0.02
	WB.box(self, Vector3(5.6, 1.15, 8.97), Vector3(6.3, 1.85, 8.99), mirror, false)
	hotspots.espelho = Hotspot.add(self, Vector3(5.95, 1.5, 8.95), Vector3(0.7, 0.7, 0.1), _prompt("espelho"), func(p): _say("espelho", p))
	WB.box(self, Vector3(6.3, 0, 7.6), Vector3(7.1, 0.42, 8.95), porcelain)
	_plafond("wc", Vector3(6.1, H, 7.3), 0.9)
	_switch("wc", Vector3(5.5, 1.2, 5.77), 0.0, ["wc"])
	# storage: boxes, the suitcase she never unpacked from Salgueira
	WB.model(self, "drawer_cabinet", 8.6, 8.4, -90.0)
	WB.model(self, "cardboard_box_01", 7.7, 8.5, 10.0)
	WB.model(self, "cardboard_box_01", 7.72, 8.48, -15.0, 0.9, 0.36, false)
	WB.model(self, "vintage_suitcase", 7.8, 6.3, 80.0)
	_bulb("arrumos", Vector3(8.1, H, 7.3), 0.3, 0.6, 3.5)
	_switch("arrumos", Vector3(7.5, 1.2, 5.77), 0.0, ["arrumos"])


# =================================================================== outside
func _build_outside() -> void:
	var colors := [Color(0.92, 0.82, 0.6), Color(0.86, 0.6, 0.52), Color(0.72, 0.8, 0.85), Color(0.95, 0.92, 0.85)]
	var facade := WB.mat("painted_plaster_wall", 3.0, colors[3])
	# our own facade around the windows, and the floors above and below
	WB.wall(self, "x", -EXT - 0.01, -14, 23, 14, 0.02, facade, [[1.0, 2.1, 3.7, 5.8], [3.0, 4.1, 3.7, 5.8], [6.4, 7.6, 4.1, 5.6]])
	WB.box(self, Vector3(-EXT, -3.2, -EXT), Vector3(9 + EXT, -0.1, 9 + EXT), facade)
	for w in [[1.0, 2.1], [3.0, 4.1]]:
		# little iron balconies under the tall windows
		WB.box(self, Vector3(w[0] - 0.1, -0.05, -0.75), Vector3(w[1] + 0.1, 0.0, -EXT), WB.mat("marble_01", 1.0), false)
		WB.box(self, Vector3(w[0] - 0.1, 0.0, -0.76), Vector3(w[1] + 0.1, 0.95, -0.74), WB.flat(Color(0.1, 0.1, 0.1, 0.9), 0.5, 0.6), false)
	# the street, two floors down
	var y0 := -6.4
	WB.box(self, Vector3(-14, y0 - 0.5, -9.0), Vector3(23, y0, -EXT), WB.mat("cobblestone_floor_04", 1.6, Color(0.75, 0.73, 0.7)))
	WB.box(self, Vector3(-14, y0, -7.4), Vector3(23, y0 + 0.02, -2.4), WB.mat("asphalt_06", 4.0, Color(0.55, 0.55, 0.55)), false)
	WB.model(self, "covered_car", 6.0, -3.2, 90.0, 1.0, y0)
	# the building across the street, windows lit here and there
	var x := -14.0
	var i := 0
	while x < 23.0:
		var w := rng.randf_range(6.0, 9.0)
		var c: Color = colors[i % colors.size()]
		WB.box(self, Vector3(x, y0, -10.0), Vector3(x + w, y0 + rng.randf_range(15.0, 19.0), -9.0), WB.mat("painted_plaster_wall", 3.0, c))
		for fl in 5:
			var wx := x + 0.8
			while wx < x + w - 1.0:
				var lit := rng.randf() < 0.28
				var m := WB.emissive(Color(1.0, 0.78, 0.5) if lit else Color(0.05, 0.06, 0.08), 1.2 if lit else 0.0)
				if lit:
					m.set_meta("energy", 1.2)
					lit_windows.append(m)
				WB.box(self, Vector3(wx, y0 + 1.2 + fl * 3.0, -9.02), Vector3(wx + 0.9, y0 + 2.8 + fl * 3.0, -9.0), m, false)
				wx += 1.6
		x += w
		i += 1
	# tram wires and a street lamp on the wall
	for z in [-5.5, -4.3]:
		WB.box(self, Vector3(-14, y0 + 6.0, z - 0.006), Vector3(23, y0 + 6.012, z + 0.006), WB.flat(Color(0.1, 0.1, 0.1), 0.5, 0.6), false)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(5.0, y0 + 5.0, -1.2)
	lamp.rotation_degrees.x = -90
	lamp.light_color = STREET_SODIUM
	lamp.light_energy = 9.0
	lamp.spot_range = 13.0
	lamp.spot_angle = 70.0
	add_child(lamp)
	street_lights.append(lamp)
	lamps.append(lamp)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, 170, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.06
	moon.shadow_enabled = true
	add_child(moon)


# =================================================================== story
func _build_story_hooks() -> void:
	spawns = {
		"sofa": [Vector3(1.3, 0.02, 2.3), -90.0],
		"entrada": [Vector3(8.3, 0.02, 5.1), 90.0],
		"cama": [Vector3(2.2, 0.02, 6.6), 180.0, -10.0],
		"cozinha": [Vector3(6.6, 0.02, 3.2), 0.0],
	}
	spots = {
		"front_door": Vector3(9.3, 1.3, 5.1), "street": Vector3(4.0, -4.0, -4.0),
		"corridor": Vector3(4.5, 1.5, 5.1), "kitchen": Vector3(7.5, 1.0, 2.0), "wc": Vector3(6.1, 1.0, 7.3),
		"landing": Vector3(10.5, 1.2, 5.1), "window": Vector3(2.0, 1.5, -0.6),
	}
	add_hide("roupeiro", Vector3(4.6, 1.0, 7.4), Vector3(0.4, 1.8, 1.2), "Esconder no roupeiro",
		[Vector3(4.65, 1.45, 7.4), 90.0, -4.0], [Vector3(3.9, 0.02, 7.4), 90.0])
	add_hide("arrumos", Vector3(8.2, 1.0, 6.6), Vector3(1.0, 1.8, 0.4), "Esconder atrás da mala",
		[Vector3(8.4, 1.0, 6.9), 0.0, -8.0], [Vector3(8.1, 0.02, 6.2), 0.0])
	for id in ["quarto", "wc", "arrumos", "cozinha"]:
		var d: Door = doors[id]
		add_change("porta_" + id, d.global_position + Vector3(0.4, 1.0, 0), func(): d.set_open(not d.is_open, true), "door", -22.0)
	add_change("gaveta", Vector3(0.35, 0.5, 6.25), func():
		GameState.set_var("w_drawer_open", true)
		drawer.rotation_degrees.y += 4.0, "click_far", -16.0)
	add_change("relogio", Vector3(4.9, 2.3, 3.2), func(): pass, "click_far", -20.0)
	for id in ["sala", "cozinha", "quarto"]:
		add_change("luz_" + id, room_bounds[id].get_center(), func(): set_room_light(id, not rooms[id].on), "switch", -16.0)


func floor_kind(p: Vector3) -> String:
	return "tile" if (p.x > 5.0 and p.z < 4.5) or (p.x > 5.0 and p.x < 7.2 and p.z > 5.7) else "wood"


func set_daylight(d: float) -> void:
	moon.visible = d < 0.5
	for f in sky_fills:
		f.visible = d > 0.02
		f.light_energy = float(f.get_meta("base")) * d
	for l in street_lights:
		l.visible = d < 0.35
	for m in lit_windows:
		m.emission_energy_multiplier = float(m.get_meta("energy")) * (1.0 - d)
