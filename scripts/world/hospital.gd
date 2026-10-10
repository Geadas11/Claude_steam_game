class_name Hospital
extends Location
## Hospital de Santa Maria, Lisbon — Medicina Interna, piso 6, at night.
## One long corridor with the tubes on by zones; the nurses' station open to
## it (monitors, the patient board, the phone that rings at 03:17); the
## staff room with the lockers; pharmacy and linen room; four wards of three
## beds behind curtains, people asleep under thin blankets; the lift lobby
## at the end, with a window over the city.
##
##   x0..32, z0..12 · corridor z4..6.4 · wards z6.4..12 · ceiling 2.8

const H := 2.8
const EXT := 0.3
const INT := 0.12
const COOL := Color(0.9, 0.95, 1.0)
const WARD_X := [0.0, 7.0, 14.0, 21.0]

var rng := RandomNumberGenerator.new()
var sky_fills: Array[OmniLight3D] = []
var city_lights: Array[StandardMaterial3D] = []
var moon: DirectionalLight3D
var m_door: Material
var phone_light: StandardMaterial3D


func _ready() -> void:
	load_texts("hospital")
	rng.seed = 606
	m_wall = WB.mat("plastered_wall_04", 2.5, Color(1.0, 1.0, 1.0))
	m_ceiling = WB.grid(Color(0.86, 0.86, 0.84), Color(0.62, 0.63, 0.62), 0.6, 0.85)
	m_paint = WB.flat(Color(0.6, 0.7, 0.78), 0.5)
	m_skirt = WB.flat(Color(0.35, 0.42, 0.48), 0.5)
	m_door = WB.flat(Color(0.72, 0.8, 0.86), 0.45)
	_build_shell()
	_build_corridor()
	_build_station()
	_build_staff_room()
	_build_service_rooms()
	_build_wards()
	_build_lobby()
	_build_outside()
	_build_story_hooks()
	for id in ["corredor_a", "corredor_b", "corredor_c", "posto"]:
		set_room_light(id, true)


# =================================================================== shell
func _build_shell() -> void:
	var lino := WB.grid(Color(0.68, 0.74, 0.76), Color(0.6, 0.66, 0.68), 0.5, 0.3, 2)
	WB.box(self, Vector3(0, -0.1, 0), Vector3(32, 0, 12), lino)
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(32 + EXT, H + 0.12, 12 + EXT), m_ceiling)
	# outer walls: windows in the wards and the lobby
	var back: Array = []
	for wx in WARD_X:
		back.append([wx + 1.2, wx + 3.0, 0.9, 2.2])
		back.append([wx + 4.0, wx + 5.8, 0.9, 2.2])
	WB.wall(self, "x", 12 + EXT / 2, -EXT, 32 + EXT, H, EXT, m_wall, back)
	WB.wall(self, "x", -EXT / 2, -EXT, 32 + EXT, H, EXT, m_wall, [[1.0, 3.0, 1.0, 2.1], [28.5, 31.5, 0.6, 2.4]])
	WB.wall(self, "z", -EXT / 2, 0, 12, H, EXT, m_wall)
	WB.wall(self, "z", 32 + EXT / 2, 0, 12, H, EXT, m_wall, [[2.0, 10.0, 0.6, 2.4]])
	# north side rooms open on the corridor at z=4
	WB.wall(self, "x", 4.0, 0, 28, H, INT, m_wall, [[4.6, 5.5, 0.0, 2.1], [6.4, 13.6, 1.05, 2.4], [14.6, 15.5, 0.0, 2.1], [18.4, 19.3, 0.0, 2.1], [21.6, 22.4, 0.0, 2.1]])
	WB.wall(self, "z", 6.0, 0, 4, H, INT, m_wall)
	WB.wall(self, "z", 14.0, 0, 4, H, INT, m_wall)
	WB.wall(self, "z", 18.0, 0, 4, H, INT, m_wall)
	WB.wall(self, "z", 21.0, 0, 4, H, INT, m_wall)
	WB.wall(self, "z", 23.5, 0, 4, H, INT, m_wall)
	WB.wall(self, "z", 28.0, 0, 4, H, INT, m_wall)
	# south side: the wards
	var doors_s: Array = []
	for wx in WARD_X:
		doors_s.append([wx + 2.8, wx + 4.2, 0.0, 2.2])
	WB.wall(self, "x", 6.4, 0, 28, H, INT, m_wall, doors_s)
	for wx in [7.0, 14.0, 21.0, 28.0]:
		WB.wall(self, "z", wx, 6.4, 12, H, INT, m_wall)
	doors.pausa = Door.make(self, Vector3(4.6, 0, 4.0), "x", 0.9, 2.1, m_door, 1.0, Rect2(0.3, 1.2, 0.3, 0.5))
	doors.farmacia = Door.make(self, Vector3(14.6, 0, 4.0), "x", 0.9, 2.1, m_door, 1.0)
	doors.farmacia.locked = true
	doors.farmacia.locked_text = _first_text("farmacia")
	doors.rouparia = Door.make(self, Vector3(18.4, 0, 4.0), "x", 0.9, 2.1, m_door, 1.0)
	doors.wc = Door.make(self, Vector3(21.6, 0, 4.0), "x", 0.8, 2.1, m_door, 1.0)
	for i in WARD_X.size():
		doors["enf_%d" % i] = Door.make(self, Vector3(WARD_X[i] + 2.8, 0, 6.4), "x", 1.4, 2.2, m_door, -1.0, Rect2(0.5, 1.25, 0.4, 0.55))
		doors["enf_%d" % i].leaf.rotation_degrees.y = -70.0
		doors["enf_%d" % i].is_open = true
	room_bounds = {
		"pausa": AABB(Vector3(0, 0, 0), Vector3(6, H, 4)),
		"posto": AABB(Vector3(6, 0, 0), Vector3(8, H, 4)),
		"farmacia": AABB(Vector3(14, 0, 0), Vector3(4, H, 4)),
		"rouparia": AABB(Vector3(18, 0, 0), Vector3(3, H, 4)),
		"wc": AABB(Vector3(21, 0, 0), Vector3(2.5, H, 4)),
		"corredor_a": AABB(Vector3(0, 0, 4), Vector3(10, H, 2.4)),
		"corredor_b": AABB(Vector3(10, 0, 4), Vector3(10, H, 2.4)),
		"corredor_c": AABB(Vector3(20, 0, 4), Vector3(8, H, 2.4)),
		"enf_601": AABB(Vector3(0, 0, 6.4), Vector3(7, H, 5.6)),
		"enf_602": AABB(Vector3(7, 0, 6.4), Vector3(7, H, 5.6)),
		"enf_603": AABB(Vector3(14, 0, 6.4), Vector3(7, H, 5.6)),
		"enf_604": AABB(Vector3(21, 0, 6.4), Vector3(7, H, 5.6)),
		"elevadores": AABB(Vector3(28, 0, 0), Vector3(4, H, 12)),
	}


func _tube(zone: String, at: Vector3, energy := 1.0, rng_m := 5.0) -> void:
	var m := WB.model(self, "mounted_fluorescent_lights", at.x, at.z, 90.0, 1.0, H - 0.05, false)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glow := WB.emissive(Color(0.92, 0.96, 1.0), 0.0)
	var panel := WB.box(self, Vector3(at.x - 0.3, H - 0.065, at.z - 0.42), Vector3(at.x + 0.3, H - 0.05, at.z + 0.42), glow, false)
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var l := WB.omni(self, Vector3(at.x, H - 0.25, at.z), COOL, energy, rng_m, true)
	l.shadow_enabled = false
	_room(zone, [l], [glow])


# =================================================================== corridor
func _build_corridor() -> void:
	var band := WB.flat(Color(0.5, 0.62, 0.72), 0.45)
	WB.box(self, Vector3(0.0, 0.0, 4.06), Vector3(28.0, 1.0, 4.075), band, false)
	WB.box(self, Vector3(0.0, 0.0, 6.325), Vector3(28.0, 1.0, 6.34), band, false)
	var rail := WB.flat(Color(0.8, 0.82, 0.84), 0.3, 0.6)
	for seg in [[0.0, 4.5], [5.6, 6.3], [13.7, 14.5], [15.6, 18.3], [19.4, 21.5], [22.5, 28.0]]:
		WB.box(self, Vector3(seg[0], 0.88, 4.09), Vector3(seg[1], 0.93, 4.15), rail, false)
	for x in [1.5, 4.5, 7.5]:
		_tube("corredor_a", Vector3(x, 0, 5.2))
	for x in [11.0, 14.0, 17.0]:
		_tube("corredor_b", Vector3(x, 0, 5.2))
	for x in [21.0, 24.0, 27.0]:
		_tube("corredor_c", Vector3(x, 0, 5.2))
	# night lights along the floor, always on: small and blue
	for x in [2.0, 6.0, 10.0, 14.0, 18.0, 22.0, 26.0]:
		var nl := WB.emissive(Color(0.4, 0.6, 1.0), 1.5)
		WB.box(self, Vector3(x - 0.08, 0.25, 6.31), Vector3(x + 0.08, 0.3, 6.325), nl, false)
	WB.model(self, "wheelchair_01", 9.0, 6.0, 20.0)
	WB.model(self, "WetFloorSign_01", 19.5, 5.0, -20.0)
	WB.model(self, "korean_fire_extinguisher_01", 23.7, 4.25, 180.0)
	WB.model(self, "fire_alarm", 24.4, 4.07, 180.0, 1.0, 1.45, false)
	WB.model(self, "medical_box", 26.5, 4.3, 0.0, 1.0, 1.1, false)
	# a bed left in the corridor, empty, sheets folded
	_bed(Vector3(16.0, 0, 5.9), 90.0, false, false)
	WB.sign(self, "SAÍDA", Vector3(27.5, 2.4, 4.07), 180.0, Color(0.1, 0.55, 0.25), Color(0.95, 1.0, 0.95))
	WB.sign(self, "SAÍDA", Vector3(0.5, 2.4, 6.33), 0.0, Color(0.1, 0.55, 0.25), Color(0.95, 1.0, 0.95))
	WB.text(self, "MEDICINA INTERNA · PISO 6", Vector3(29.0, 2.3, 4.0), -90.0, 0.11, Color(0.15, 0.25, 0.35))
	for i in WARD_X.size():
		WB.text(self, "60%d" % (i + 1), Vector3(WARD_X[i] + 3.5, 2.4, 6.33), 0.0, 0.14, Color(0.15, 0.25, 0.35))
	WB.text(self, "Sala de pausa", Vector3(5.05, 2.25, 4.07), 180.0, 0.05, Color(0.15, 0.25, 0.35))
	WB.text(self, "Farmácia · Acesso reservado", Vector3(15.05, 2.25, 4.07), 180.0, 0.05, Color(0.15, 0.25, 0.35))
	WB.text(self, "Rouparia", Vector3(18.85, 2.25, 4.07), 180.0, 0.05, Color(0.15, 0.25, 0.35))
	_sw(Vector3(0.4, 1.2, 4.12), 180.0, ["corredor_a", "corredor_b", "corredor_c"])


func _sw(at: Vector3, rot: float, targets: Array) -> void:
	_switch(targets[0], at, rot, targets)


# =================================================================== nurses' station
func _build_station() -> void:
	var white := WB.flat(Color(0.92, 0.92, 0.9), 0.35)
	var wood := WB.mat("kitchen_wood", 1.0, Color(0.85, 0.8, 0.72))
	# the counter open on the corridor
	WB.box(self, Vector3(6.4, 0, 3.4), Vector3(13.6, 1.05, 3.95), wood)
	WB.box(self, Vector3(6.35, 1.05, 3.35), Vector3(13.65, 1.1, 4.0), white, false)
	WB.box(self, Vector3(6.6, 0.72, 2.7), Vector3(13.4, 0.76, 3.4), white, false)
	for x in [7.6, 9.6, 11.8]:
		_monitor(Vector3(x, 0.76, 3.0), 0.0)
	WB.model(self, "modern_arm_chair_01", 8.6, 2.2, 10.0)
	WB.model(self, "modern_arm_chair_01", 11.0, 2.3, -15.0)
	WB.model(self, "clipboard", 12.6, 3.6, 20.0, 1.0, 1.1, false)
	WB.model(self, "binder_notebook", 7.0, 3.0, -10.0, 1.0, 0.76, false)
	WB.model(self, "stationery_supplies", 10.6, 3.0, 0.0, 1.0, 0.76, false)
	WB.model(self, "office_notepads", 13.0, 3.0, 10.0, 1.0, 0.76, false)
	# the patient board on the back wall
	WB.box(self, Vector3(7.2, 1.3, 0.02), Vector3(10.6, 2.3, 0.05), WB.flat(Color(0.95, 0.96, 0.95), 0.2), false)
	var names := ["601 · Sr. Albano · 82", "601 · D. Fátima · 79", "602 · Sr. Joaquim · 88", "603 · D. Lurdes · 91", "603 · cama 3 · —", "604 · Sr. Rui M. · 34"]
	for k in names.size():
		WB.text(self, names[k], Vector3(7.4 + (k % 2) * 1.7, 2.1 - (k / 2) * 0.28, 0.06), 0.0, 0.04, Color(0.15, 0.2, 0.45))
	hotspots.quadro = Hotspot.add(self, Vector3(8.9, 1.8, 0.1), Vector3(3.4, 1.0, 0.15), _prompt("quadro"), func(p): _say("quadro", p))
	WB.model(self, "wall_clock", 12.4, 0.05, 0.0, 1.0, 2.2, false)
	hotspots.relogio = Hotspot.add(self, Vector3(12.4, 2.3, 0.1), Vector3(0.4, 0.4, 0.15), _prompt("relogio"), func(p): _say("relogio", p))
	# the ward phone, with a light that blinks when it rings
	var phone := WB.box(self, Vector3(12.9, 0.76, 2.9), Vector3(13.2, 0.84, 3.2), WB.flat(Color(0.9, 0.9, 0.88), 0.4), false)
	phone_light = WB.emissive(Color(1.0, 0.3, 0.2), 0.0)
	WB.box(self, Vector3(13.13, 0.84, 2.95), Vector3(13.17, 0.86, 2.99), phone_light, false)
	hotspots.telefone = Hotspot.add(self, Vector3(13.05, 0.82, 3.05), Vector3(0.35, 0.15, 0.35), _prompt("telefone"), func(p): _say("telefone", p))
	for x in [8.0, 11.5]:
		_tube("posto", Vector3(x, 0, 2.0), 0.9)
	_sw(Vector3(6.15, 1.2, 3.8), 90.0, ["posto"])


func _monitor(at: Vector3, yaw: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	add_child(holder)
	var black := WB.flat(Color(0.03, 0.03, 0.03), 0.4)
	WB.box(holder, Vector3(-0.12, 0, -0.08), Vector3(0.12, 0.015, 0.08), black, false)
	WB.box(holder, Vector3(-0.02, 0.015, -0.02), Vector3(0.02, 0.2, 0.02), black, false)
	WB.box(holder, Vector3(-0.27, 0.15, -0.025), Vector3(0.27, 0.48, 0.0), black, false)
	var scr := WB.emissive(Color(0.2, 0.55, 0.45), 0.5)
	WB.box(holder, Vector3(-0.25, 0.165, 0.0), Vector3(0.25, 0.465, 0.002), scr, false)


# =================================================================== staff room
func _build_staff_room() -> void:
	var steel := WB.flat(Color(0.55, 0.6, 0.65), 0.35, 0.6)
	# lockers along the west wall
	for k in 6:
		var z0 := 0.3 + k * 0.5
		WB.box(self, Vector3(0.05, 0, z0), Vector3(0.55, 1.9, z0 + 0.48), steel)
		WB.box(self, Vector3(0.551, 1.5, z0 + 0.2), Vector3(0.56, 1.6, z0 + 0.28), WB.flat(Color(0.2, 0.2, 0.2), 0.4), false)
	WB.text(self, "S. REIS", Vector3(0.565, 1.75, 1.04), 90.0, 0.035, Color(0.1, 0.1, 0.1))
	hotspots.cacifo = Hotspot.add(self, Vector3(0.3, 1.0, 1.04), Vector3(0.6, 1.9, 0.5), _prompt("cacifo"), func(p): _say("cacifo", p))
	WB.model(self, "sofa_03", 3.0, 0.5, 0.0, 0.9)
	WB.model(self, "round_wooden_table_01", 3.4, 2.4, 0.0, 0.6)
	WB.model(self, "dining_chair_02", 2.7, 2.6, 80.0)
	WB.model(self, "vintage_microwave", 5.6, 3.2, -90.0, 1.0, 0.9, false)
	WB.box(self, Vector3(5.3, 0, 2.6), Vector3(5.9, 0.9, 3.9), WB.mat("kitchen_wood", 1.0, Color(0.85, 0.8, 0.72)))
	WB.model(self, "jug_01", 5.6, 2.8, 0.0, 1.0, 0.9, false)
	var l := WB.omni(self, Vector3(3.0, 2.5, 2.0), COOL, 0.7, 5.0, true)
	_room("pausa", [l], [])
	_sw(Vector3(4.4, 1.2, 3.88), 0.0, ["pausa"])


func _build_service_rooms() -> void:
	# pharmacy: shelves behind a locked door
	WB.model(self, "steel_frame_shelves_01", 16.0, 0.4, 0.0)
	WB.model(self, "medical_box", 15.2, 0.4, 0.0, 1.0, 1.2, false)
	var lf := WB.omni(self, Vector3(16.0, 2.5, 2.0), COOL, 0.5, 4.0, true)
	_room("farmacia", [lf], [])
	# linen: stacked white sheets
	WB.model(self, "steel_frame_shelves_03", 19.5, 0.4, 0.0)
	for k in 3:
		WB.box(self, Vector3(18.9, 0.4 + k * 0.5, 0.2), Vector3(20.1, 0.6 + k * 0.5, 0.6), WB.flat(Color(0.94, 0.95, 0.96), 0.9), false)
	var lr := WB.omni(self, Vector3(19.5, 2.5, 2.0), COOL, 0.5, 3.5, true)
	_room("rouparia", [lr], [])
	_sw(Vector3(18.25, 1.2, 3.88), 0.0, ["rouparia"])
	var lw := WB.omni(self, Vector3(22.2, 2.5, 2.0), COOL, 0.5, 3.0, true)
	_room("wc", [lw], [])
	_sw(Vector3(21.45, 1.2, 3.88), 0.0, ["wc"])


# =================================================================== wards
func _build_wards() -> void:
	for i in WARD_X.size():
		var wx: float = WARD_X[i]
		var occupied := [true, i != 2, i != 3]
		for b in 3:
			_bed(Vector3(wx + 1.2 + b * 2.2, 0, 10.6), 180.0, occupied[b], true)
		var l := WB.omni(self, Vector3(wx + 3.5, 2.5, 9.2), Color(0.7, 0.78, 1.0), 0.25, 6.0, true)
		_room("enf_60%d" % (i + 1), [l], [])
		_switch("enf_60%d" % (i + 1), Vector3(wx + 2.6, 1.2, 6.47), 0.0, ["enf_60%d" % (i + 1)])
	hotspots.cama_603 = Hotspot.add(self, Vector3(WARD_X[2] + 1.2 + 2 * 2.2, 0.7, 10.6), Vector3(1.0, 0.5, 2.0), _prompt("cama_603"), func(p): _say("cama_603", p))
	hotspots.janela = Hotspot.add(self, Vector3(WARD_X[3] + 4.9, 1.5, 11.9), Vector3(1.8, 1.3, 0.2), _prompt("janela"), func(p): _say("janela", p))


## A hospital bed: steel frame, mattress, pillow, a blanket — with someone
## asleep under it when `sleeper`; a curtain on a rail around it.
func _bed(at: Vector3, yaw: float, sleeper: bool, curtain: bool) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	add_child(holder)
	var steel := WB.flat(Color(0.8, 0.82, 0.84), 0.3, 0.7)
	var sheet := WB.flat(Color(0.93, 0.94, 0.95), 0.9)
	# frame: four legs on castors, a thin deck, side rails, tube head and foot ends
	for lx in [-0.42, 0.42]:
		for lz in [-0.92, 0.92]:
			WB.box(holder, Vector3(lx - 0.025, 0.06, lz - 0.025), Vector3(lx + 0.025, 0.46, lz + 0.025), steel, false)
			WB.box(holder, Vector3(lx - 0.04, 0.0, lz - 0.04), Vector3(lx + 0.04, 0.06, lz + 0.04), WB.flat(Color(0.12, 0.12, 0.12), 0.6), false)
	WB.box(holder, Vector3(-0.47, 0.42, -0.98), Vector3(0.47, 0.5, 0.98), steel, true)
	WB.box(holder, Vector3(-0.45, 0.5, -0.96), Vector3(0.45, 0.66, 0.96), sheet, false)
	for side in [-1.0, 1.0]:
		WB.box(holder, Vector3(side * 0.49 - 0.012, 0.72, -0.55), Vector3(side * 0.49 + 0.012, 0.75, 0.45), steel, false)
		for rz in [-0.5, 0.4]:
			WB.box(holder, Vector3(side * 0.49 - 0.01, 0.5, rz - 0.01), Vector3(side * 0.49 + 0.01, 0.75, rz + 0.01), steel, false)
	for ez in [-1.0, 1.0]:
		var top := 1.05 if ez < 0 else 0.85
		WB.box(holder, Vector3(-0.47, 0.5, ez - 0.02), Vector3(-0.44, top, ez + 0.02), steel, false)
		WB.box(holder, Vector3(0.44, 0.5, ez - 0.02), Vector3(0.47, top, ez + 0.02), steel, false)
		WB.box(holder, Vector3(-0.47, top - 0.03, ez - 0.02), Vector3(0.47, top, ez + 0.02), steel, false)
		WB.box(holder, Vector3(-0.44, 0.62, ez - 0.012), Vector3(0.44, top - 0.08, ez + 0.012), WB.flat(Color(0.86, 0.88, 0.9), 0.4), false)
	WB.box(holder, Vector3(-0.3, 0.66, -0.95), Vector3(0.3, 0.78, -0.6), sheet, false)
	var blanket := WB.flat(Color(0.55, 0.68, 0.8), 0.95)
	if sleeper:
		# someone asleep: a long low hump and a head on the pillow
		var hump := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.24
		cm.height = 1.6
		hump.mesh = cm
		hump.material_override = blanket
		hump.rotation_degrees.x = 90.0
		hump.scale = Vector3(1.0, 1.0, 0.55)
		hump.position = Vector3(0.0, 0.74, 0.15)
		holder.add_child(hump)
		var head := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.1
		sm.height = 0.19
		head.mesh = sm
		head.material_override = WB.flat(Color(0.75, 0.62, 0.55), 0.7)
		head.position = Vector3(0.03, 0.84, -0.72)
		holder.add_child(head)
	else:
		WB.box(holder, Vector3(-0.47, 0.66, 0.2), Vector3(0.47, 0.7, 0.98), blanket, false)
	if curtain:
		var cur := StandardMaterial3D.new()
		cur.albedo_color = Color(0.72, 0.82, 0.86, 0.9)
		cur.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cur.cull_mode = BaseMaterial3D.CULL_DISABLED
		WB.box(holder, Vector3(-0.95, 0.35, -1.1), Vector3(-0.94, 2.3, 0.9), cur, false)
		WB.box(holder, Vector3(-0.95, 2.4, -1.1), Vector3(0.95, 2.42, 1.2), WB.flat(Color(0.7, 0.7, 0.72), 0.3, 0.8), false)
		# a monitor on a pole, green line
		WB.box(holder, Vector3(0.62, 0.0, -0.92), Vector3(0.65, 1.6, -0.89), steel, false)
		var scr := WB.emissive(Color(0.1, 0.8, 0.4), 0.6 if sleeper else 0.0)
		WB.box(holder, Vector3(0.52, 1.35, -0.95), Vector3(0.76, 1.55, -0.94), scr, false)


# =================================================================== lift lobby
func _build_lobby() -> void:
	var steel := WB.flat(Color(0.7, 0.72, 0.74), 0.25, 0.9)
	for z in [3.0, 7.0]:
		WB.box(self, Vector3(28.05, 0, z - 0.6), Vector3(28.1, 2.2, z + 0.6), steel, false)
		WB.box(self, Vector3(28.1, 1.2, z + 0.75), Vector3(28.12, 1.3, z + 0.85), WB.emissive(Color(1.0, 0.8, 0.4), 0.8), false)
	hotspots.elevador = Hotspot.add(self, Vector3(28.15, 1.1, 5.0), Vector3(0.2, 2.2, 5.0), _prompt("elevador"), func(p): _say("elevador", p))
	WB.model(self, "modular_street_seating", 30.2, 9.5, 0.0)
	WB.model(self, "potted_plant_01", 31.5, 11.3, 0.0)
	for x in [30.0]:
		_tube("elevadores", Vector3(x, 0, 3.0), 0.8)
		_tube("elevadores", Vector3(x, 0, 8.0), 0.8)


# =================================================================== outside: Lisbon at night
func _build_outside() -> void:
	# the city beyond the lobby window and the ward windows: a field of lights
	var ground := WB.flat(Color(0.02, 0.02, 0.03), 0.9)
	WB.box(self, Vector3(-60, -20.5, -60), Vector3(120, -20, 80), ground, false)
	for k in 260:
		var p := Vector3(rng.randf_range(-50, 110), -20 + rng.randf_range(0.0, 14.0), rng.randf_range(-50, 70))
		if p.x > -2 and p.x < 34 and p.z > -2 and p.z < 14:
			continue
		var c := Color(1.0, 0.75, 0.45) if rng.randf() < 0.7 else Color(0.85, 0.9, 1.0)
		var m := WB.emissive(c, rng.randf_range(1.0, 2.5))
		m.set_meta("energy", m.emission_energy_multiplier)
		city_lights.append(m)
		WB.box(self, p, p + Vector3(0.6, 0.4, 0.6), m, false)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, 150, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.05
	add_child(moon)


# =================================================================== story
func _build_story_hooks() -> void:
	spawns = {
		"posto": [Vector3(9.8, 0.02, 2.4), 180.0],
		"pausa": [Vector3(2.4, 0.02, 2.2), 180.0],
		"corredor": [Vector3(2.0, 0.02, 5.2), -90.0],
		"elevadores": [Vector3(29.5, 0.02, 5.0), 90.0],
	}
	spots = {
		"front_door": Vector3(28.2, 1.3, 5.0), "corridor": Vector3(20.0, 1.5, 5.2),
		"landing": Vector3(30.0, 1.2, 5.0), "kitchen": Vector3(5.6, 1.0, 3.0), "wc": Vector3(22.2, 1.0, 2.0),
		"street": Vector3(30.0, -5.0, -5.0), "window": Vector3(30.0, 1.5, -0.5),
	}
	add_hide("rouparia", Vector3(19.5, 1.0, 1.2), Vector3(1.4, 1.8, 0.4), "Esconder atrás dos lençóis",
		[Vector3(19.5, 1.45, 1.6), 0.0, -4.0], [Vector3(19.5, 0.02, 2.6), 0.0])
	add_hide("cortina", Vector3(WARD_X[2] + 5.6, 1.0, 10.0), Vector3(0.3, 1.8, 1.6), "Esconder atrás da cortina",
		[Vector3(WARD_X[2] + 6.2, 1.4, 10.0), 90.0, -6.0], [Vector3(WARD_X[2] + 5.4, 0.02, 9.2), 90.0])
	add_hide("pausa", Vector3(0.7, 1.0, 3.6), Vector3(0.4, 1.8, 0.6), "Esconder atrás dos cacifos",
		[Vector3(0.4, 1.45, 3.75), 90.0, -4.0], [Vector3(1.3, 0.02, 3.4), -90.0])
	for z in ["corredor_a", "corredor_b", "corredor_c"]:
		add_change("luz_" + z, room_bounds[z].get_center(), func(): set_room_light(z, not rooms[z].on), "switch", -16.0)
	for id in ["pausa", "rouparia", "wc"]:
		var d: Door = doors[id]
		add_change("porta_" + id, d.global_position + Vector3(0.45, 1.0, 0), func(): d.set_open(not d.is_open, true), "door", -22.0)
	add_change("telefone", Vector3(13.05, 0.9, 3.05), func(): ring_phone(6.0), "beep", -10.0)


## The ward phone rings (its light blinks) for a while.
func ring_phone(secs: float) -> void:
	var t := 0.0
	while t < secs and is_inside_tree():
		phone_light.emission_energy_multiplier = 2.0
		if get_parent() is GameWorld:
			(get_parent() as GameWorld).play_at("beep", Vector3(13.05, 1.0, 3.05), -8.0, 1.6)
		await get_tree().create_timer(0.5).timeout
		phone_light.emission_energy_multiplier = 0.0
		await get_tree().create_timer(0.7).timeout
		t += 1.2


func floor_kind(_p: Vector3) -> String:
	return "tile"


func set_daylight(d: float) -> void:
	moon.visible = d < 0.5
	for m in city_lights:
		m.emission_energy_multiplier = float(m.get_meta("energy")) * (1.0 - d)
