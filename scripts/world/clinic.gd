class_name Clinic
extends Location
## Clínica Atlântico, Faro — psiquiatria e saúde mental. Reception at the
## front, one long corridor, Dra. Helena's office, the archive, the nurses'
## station and the service stairs on the street side; six inpatient rooms
## (room 4 already has Daniel's name on the door), linen room and toilets on
## the other. After closing time the corridor goes dark by zones.
##
##   x0..26, z0..16 (street at z<0) · corridor z7..9.2 · ceiling 2.8

const H := 2.8
const EXT := 0.3
const INT := 0.12
const COOL := Color(0.9, 0.95, 1.0)
const ROOM_X := [2.0, 5.4, 8.8, 12.2, 15.6, 19.0]   # inpatient rooms, 3.4 m wide
const STREET_SODIUM := Color(1.0, 0.6, 0.28)

var rng := RandomNumberGenerator.new()
var sky_fills: Array[OmniLight3D] = []
var street_lights: Array[SpotLight3D] = []
var moon: DirectionalLight3D
var tv_mat: StandardMaterial3D
var wheelchair: Node3D
var m_door: Material


func _ready() -> void:
	load_texts("clinica")
	rng.seed = 1105
	m_wall = WB.mat("white_plaster_02", 2.5, Color(0.97, 0.98, 0.96))
	m_ceiling = WB.grid(Color(0.86, 0.86, 0.84), Color(0.62, 0.63, 0.62), 0.6, 0.85)
	m_paint = WB.flat(Color(0.62, 0.72, 0.66), 0.5)
	m_skirt = WB.flat(Color(0.35, 0.4, 0.38), 0.5)
	m_door = WB.flat(Color(0.74, 0.8, 0.76), 0.45)
	_build_shell()
	_build_reception()
	_build_corridor()
	_build_office()
	_build_archive()
	_build_station()
	_build_stairs()
	_build_rooms()
	_build_outside()
	_build_story_hooks()
	for id in ["rececao", "corredor_a", "corredor_b", "corredor_c", "enfermaria"]:
		set_room_light(id, true)


# =================================================================== shell
func _build_shell() -> void:
	var lino := WB.grid(Color(0.66, 0.7, 0.66), Color(0.58, 0.61, 0.58), 0.5, 0.3, 2)
	WB.box(self, Vector3(0, -0.1, 7), Vector3(26, 0, 16), lino)
	WB.box(self, Vector3(0, -0.1, 0), Vector3(10, 0, 7), WB.mat("grey_tiles", 1.2, Color(0.85, 0.85, 0.83)))
	WB.box(self, Vector3(10, -0.1, 0), Vector3(15.5, 0, 7), WB.mat("dark_wooden_planks", 1.4, Color(0.85, 0.75, 0.65)))
	WB.box(self, Vector3(15.5, -0.1, 0), Vector3(26, 0, 7), lino)
	WB.box(self, Vector3(-EXT, H, -EXT), Vector3(26 + EXT, H + 0.12, 16 + EXT), m_ceiling)
	# outer walls
	var front := [[0.5, 3.5, 0.9, 2.3], [4.0, 6.0, 0.0, 2.4], [6.5, 9.5, 0.9, 2.3], [11.0, 15.0, 1.0, 2.2], [24.0, 25.4, 1.4, 2.2]]
	WB.wall(self, "x", -EXT / 2, -EXT, 26 + EXT, H, EXT, m_wall, front)
	var back: Array = []
	for x0 in ROOM_X:
		back.append([x0 + 1.6, x0 + 3.0, 1.0, 2.1])
	back.append([0.5, 1.5, 1.6, 2.2])
	WB.wall(self, "x", 16 + EXT / 2, -EXT, 26 + EXT, H, EXT, m_wall, back)
	WB.wall(self, "z", -EXT / 2, 0, 16, H, EXT, m_wall)
	WB.wall(self, "z", 26 + EXT / 2, 0, 16, H, EXT, m_wall, [[3.0, 4.0, 0.0, 2.1]])
	# the corridor walls
	var north := [[13.6, 14.6, 0, 2.1], [16.2, 17.1, 0, 2.1], [19.8, 21.8, 0.95, 2.2], [22.0, 22.9, 0, 2.1], [24.0, 25.0, 0, 2.1]]
	WB.wall(self, "x", 7.0, 10.0, 26, H, INT, m_wall, north)
	var south: Array = [[0.5, 1.3, 0, 2.1], [23.0, 23.9, 0, 2.1]]
	for x0 in ROOM_X:
		south.append([x0 + 0.3, x0 + 1.3, 0, 2.1])
	WB.wall(self, "x", 9.2, 0, 26, H, INT, m_wall, south)
	for x in [10.0, 15.5, 19.5, 23.0]:
		WB.wall(self, "z", x, 0, 7.0 - INT / 2, H, INT, m_wall)
	for x in ROOM_X + [22.4]:
		WB.wall(self, "z", x, 9.2 + INT / 2, 16, H, INT, m_wall)
	# windows: plain on the street side, frosted at the back
	for w in front:
		if w[2] > 0.0:
			_window(w, 0.0, -1.0)
	for w in back:
		_window(w, 16.0, 1.0)
	# doors
	doors.entrada = Door.make(self, Vector3(4.0, 0, 0.0), "x", 2.0, 2.4, WB.glass(), 1.0)
	doors.entrada.locked = true
	doors.entrada.locked_text = _first_text("porta_entrada")
	doors.consultorio = Door.make(self, Vector3(13.6, 0, 7.0), "x", 1.0, 2.1, m_door, 1.0)
	doors.arquivo = Door.make(self, Vector3(16.2, 0, 7.0), "x", 0.9, 2.1, m_door, 1.0)
	doors.escada = Door.make(self, Vector3(24.0, 0, 7.0), "x", 1.0, 2.1, m_door, 1.0, Rect2(0.35, 1.3, 0.3, 0.45))
	doors.saida = Door.make(self, Vector3(26.0, 0, 3.0), "z", 1.0, 2.1, WB.flat(Color(0.5, 0.52, 0.5), 0.4, 0.6), 1.0)
	doors.saida.locked = true
	doors.saida.locked_text = _first_text("porta_saida")
	doors.rouparia = Door.make(self, Vector3(0.5, 0, 9.2), "x", 0.8, 2.1, m_door, -1.0)
	doors.wc = Door.make(self, Vector3(23.0, 0, 9.2), "x", 0.9, 2.1, m_door, -1.0)
	for i in ROOM_X.size():
		doors["quarto_%d" % (i + 1)] = Door.make(self, Vector3(ROOM_X[i] + 0.3, 0, 9.2), "x", 1.0, 2.1, m_door, -1.0, Rect2(0.35, 1.25, 0.25, 0.45))
	room_bounds = {
		"rececao": AABB(Vector3(0, 0, 0), Vector3(10, H, 7)),
		"corredor_a": AABB(Vector3(0, 0, 7), Vector3(9, H, 2.2)),
		"corredor_b": AABB(Vector3(9, 0, 7), Vector3(9, H, 2.2)),
		"corredor_c": AABB(Vector3(18, 0, 7), Vector3(8, H, 2.2)),
		"consultorio": AABB(Vector3(10, 0, 0), Vector3(5.5, H, 7)),
		"arquivo": AABB(Vector3(15.5, 0, 0), Vector3(4, H, 7)),
		"enfermaria": AABB(Vector3(19.5, 0, 0), Vector3(3.5, H, 7)),
		"escada": AABB(Vector3(23, 0, 0), Vector3(3, H, 7)),
		"rouparia": AABB(Vector3(0, 0, 9.2), Vector3(2, H, 6.8)),
		"wc": AABB(Vector3(22.4, 0, 9.2), Vector3(3.6, H, 6.8)),
	}
	for i in ROOM_X.size():
		room_bounds["quarto_%d" % (i + 1)] = AABB(Vector3(ROOM_X[i], 0, 9.2), Vector3(3.4, H, 6.8))


func _window(w: Array, at: float, out: float) -> void:
	var frame := WB.flat(Color(0.82, 0.83, 0.82), 0.35, 0.3)
	var mid := at + out * EXT / 2
	var x0: float = w[0]
	var x1: float = w[1]
	var y0: float = w[2]
	var y1: float = w[3]
	for p in [[x0, x0 + 0.05, y0, y1], [x1 - 0.05, x1, y0, y1], [x0, x1, y0, y0 + 0.05], [x0, x1, y1 - 0.05, y1]]:
		WB.box(self, Vector3(p[0], p[2], mid - 0.04), Vector3(p[1], p[3], mid + 0.04), frame, false)
	var g := WB.glass() if out < 0 else WB.flat(Color(0.75, 0.8, 0.82, 0.8), 0.6)
	WB.box(self, Vector3(x0 + 0.05, y0 + 0.05, mid - 0.005), Vector3(x1 - 0.05, y1 - 0.05, mid + 0.005), g, true)
	WB.box(self, Vector3(x0 - 0.03, y0 - 0.03, at - out * 0.05), Vector3(x1 + 0.03, y0, mid), WB.flat(Color(0.85, 0.85, 0.83), 0.3), false)
	# venetian blinds, half down
	var slats := WB.flat(Color(0.86, 0.86, 0.84), 0.5, 0.2)
	var y := y1 - 0.06
	while y > y0 + (y1 - y0) * 0.45:
		WB.box(self, Vector3(x0 + 0.06, y, at - out * 0.07), Vector3(x1 - 0.06, y + 0.012, at - out * 0.1), slats, false)
		y -= 0.05
	var fill := WB.omni(self, Vector3((x0 + x1) / 2, (y0 + y1) / 2, at - out * 0.9), Color(0.78, 0.84, 0.95), 0.0, 5.5, false)
	fill.set_meta("base", 1.4 * (x1 - x0) / 2.0)
	fill.visible = false
	sky_fills.append(fill)


## A ceiling fluorescent fixture (the model) with its light, in a light zone.
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


# =================================================================== reception
func _build_reception() -> void:
	var white := WB.flat(Color(0.9, 0.9, 0.88), 0.35)
	var wood := WB.mat("kitchen_wood", 1.0, Color(0.85, 0.8, 0.72))
	# the desk, facing the entrance
	WB.box(self, Vector3(6.2, 0, 2.8), Vector3(9.6, 1.05, 3.4), wood)
	WB.box(self, Vector3(9.0, 0, 3.4), Vector3(9.6, 1.05, 5.0), wood)
	WB.box(self, Vector3(6.15, 1.05, 2.75), Vector3(9.65, 1.1, 3.45), white, false)
	WB.box(self, Vector3(6.4, 0.72, 3.4), Vector3(9.0, 0.76, 3.9), white, false)
	_monitor(Vector3(7.4, 0.76, 3.55), 0.0, "rececao_pc")
	WB.model(self, "clipboard", 8.4, 3.1, 15.0, 1.0, 1.1, false)
	WB.model(self, "stationery_supplies", 6.6, 3.1, 0.0, 1.0, 1.1 + 0.07, false)
	WB.model(self, "potted_plant_04", 9.3, 3.1, 0.0, 1.0, 1.1, false)
	WB.model(self, "modern_arm_chair_01", 7.6, 4.4, 180.0)
	hotspots.rececao = Hotspot.add(self, Vector3(7.9, 0.9, 3.1), Vector3(3.4, 0.4, 0.7), _prompt("rececao"), func(p): _say("rececao", p))
	WB.text(self, "CLÍNICA ATLÂNTICO", Vector3(9.92, 2.05, 2.2), -90.0, 0.16, Color(0.2, 0.32, 0.35))
	WB.text(self, "Psiquiatria e Saúde Mental", Vector3(9.92, 1.82, 2.2), -90.0, 0.07, Color(0.3, 0.38, 0.4))
	# waiting area along the west wall
	for i in 6:
		_waiting_chair(Vector3(0.45, 0, 1.2 + i * 0.62), 90.0)
	WB.box(self, Vector3(1.2, 0.0, 2.6), Vector3(1.8, 0.42, 3.4), white)
	Books.pile(self, Vector3(1.5, 0.42, 3.0), 3, rng, 0.08)
	WB.model(self, "potted_plant_01", 0.5, 5.6, 0.0)
	WB.model(self, "potted_plant_01", 3.5, 0.6, 40.0, 0.9)
	# a TV on the wall, off
	WB.box(self, Vector3(0.0, 1.55, 2.2), Vector3(0.06, 2.2, 3.4), WB.flat(Color(0.02, 0.02, 0.02), 0.3))
	tv_mat = WB.emissive(Color(0.5, 0.55, 0.6), 0.0)
	WB.box(self, Vector3(0.061, 1.58, 2.23), Vector3(0.062, 2.17, 3.37), tv_mat, false)
	WB.model(self, "WetFloorSign_01", 3.2, 1.9, 30.0)
	WB.model(self, "korean_fire_extinguisher_01", 3.75, 0.25, 0.0)
	for k in 4:
		WB.pendant(self, "rececao", Vector3(1.8 + (k % 2) * 4.5, H, 1.8 + (k / 2) * 3.0), 0.5, 0.9, 5.0, Color(0.92, 0.92, 0.9))
	_sw(Vector3(3.8, 1.2, 0.07), 180.0, ["rececao"])


func _waiting_chair(at: Vector3, yaw: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	add_child(holder)
	var chrome := WB.flat(Color(0.7, 0.7, 0.72), 0.25, 0.9)
	var fabric := WB.flat(Color(0.2, 0.32, 0.36), 0.9)
	for x in [-0.24, 0.24]:
		WB.box(holder, Vector3(x - 0.015, 0, -0.2), Vector3(x + 0.015, 0.44, -0.17), chrome, false)
		WB.box(holder, Vector3(x - 0.015, 0, 0.22), Vector3(x + 0.015, 0.44, 0.25), chrome, false)
	WB.box(holder, Vector3(-0.26, 0.44, -0.22), Vector3(0.26, 0.5, 0.24), fabric, true)
	WB.box(holder, Vector3(-0.26, 0.5, -0.24), Vector3(0.26, 0.92, -0.18), fabric, false)


func _monitor(at: Vector3, yaw: float, id: String) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	add_child(holder)
	var black := WB.flat(Color(0.03, 0.03, 0.03), 0.4)
	WB.box(holder, Vector3(-0.12, 0, -0.08), Vector3(0.12, 0.015, 0.08), black, false)
	WB.box(holder, Vector3(-0.02, 0.015, -0.02), Vector3(0.02, 0.2, 0.02), black, false)
	WB.box(holder, Vector3(-0.27, 0.15, -0.025), Vector3(0.27, 0.48, 0.0), black, false)
	var scr := WB.emissive(Color(0.25, 0.4, 0.55), 0.35)
	WB.box(holder, Vector3(-0.25, 0.165, 0.0), Vector3(0.25, 0.465, 0.002), scr, false)
	holder.set_meta("screen", scr)
	set_meta(id, holder)


# =================================================================== corridor
func _build_corridor() -> void:
	# a pale green band along the bottom, handrails, the fluorescent tubes
	var band := WB.flat(Color(0.55, 0.66, 0.6), 0.45)
	WB.box(self, Vector3(10.0, 0.0, 7.06), Vector3(26.0, 1.05, 7.075), band, false)
	WB.box(self, Vector3(0.0, 0.0, 9.125), Vector3(26.0, 1.05, 9.14), band, false)
	var rail := WB.mat("kitchen_wood", 1.0, Color(0.75, 0.65, 0.55))
	for seg in [[10.0, 13.5], [14.7, 16.1], [17.2, 19.7], [23.0, 23.9], [25.1, 26.0]]:
		WB.box(self, Vector3(seg[0], 0.88, 7.09), Vector3(seg[1], 0.94, 7.16), rail, false)
	var prev := 1.4
	for i in ROOM_X.size() + 1:
		var x_end: float = ROOM_X[i] + 0.25 if i < ROOM_X.size() else 22.95
		if x_end - prev > 0.3:
			WB.box(self, Vector3(prev, 0.88, 9.04), Vector3(x_end, 0.94, 9.11), rail, false)
		prev = (ROOM_X[i] + 1.35) if i < ROOM_X.size() else 23.95
	for x in [1.5, 4.5, 7.5]:
		_tube("corredor_a", Vector3(x, 0, 8.1))
	for x in [10.5, 13.5, 16.5]:
		_tube("corredor_b", Vector3(x, 0, 8.1))
	for x in [19.5, 22.5, 25.0]:
		_tube("corredor_c", Vector3(x, 0, 8.1))
	# props
	wheelchair = WB.model(self, "wheelchair_01", 18.4, 8.6, -70.0)
	WB.model(self, "WetFloorSign_01", 12.3, 8.0, 10.0)
	WB.model(self, "korean_fire_extinguisher_01", 19.65, 7.25, 180.0)
	WB.model(self, "fire_alarm", 18.9, 7.07, 180.0, 1.0, 1.45, false)
	for i in 3:
		_waiting_chair(Vector3(4.3 + i * 0.6, 0, 7.45), 180.0)
	# exit signs, always lit
	WB.sign(self, "SAÍDA", Vector3(24.5, 2.4, 7.07), 180.0, Color(0.1, 0.55, 0.25), Color(0.95, 1.0, 0.95))
	WB.sign(self, "SAÍDA", Vector3(5.0, 2.55, 0.07), 180.0, Color(0.1, 0.55, 0.25), Color(0.95, 1.0, 0.95))
	WB.sign(self, "SAÍDA", Vector3(25.93, 2.3, 3.5), -90.0, Color(0.1, 0.55, 0.25), Color(0.95, 1.0, 0.95))
	# room signs
	for i in ROOM_X.size():
		WB.text(self, "%d" % (i + 1), Vector3(ROOM_X[i] + 1.55, 1.9, 9.13), 180.0, 0.14, Color(0.2, 0.3, 0.32))
	WB.text(self, "Consultório 2 · Dra. Helena Sousa", Vector3(15.1, 1.9, 7.07), 180.0, 0.05, Color(0.2, 0.3, 0.32))
	WB.text(self, "Arquivo · Reservado", Vector3(17.6, 1.9, 7.07), 180.0, 0.05, Color(0.2, 0.3, 0.32))
	WB.text(self, "Enfermagem", Vector3(20.8, 2.4, 7.07), 180.0, 0.07, Color(0.2, 0.3, 0.32))
	WB.text(self, "Rouparia", Vector3(1.45, 1.9, 9.13), 180.0, 0.05, Color(0.2, 0.3, 0.32))
	_sw(Vector3(9.4, 1.2, 7.4), -90.0, ["corredor_a", "corredor_b", "corredor_c"])


# =================================================================== Dra. Helena's office
func _build_office() -> void:
	var wood := WB.mat("dark_wood", 1.0, Color(0.6, 0.48, 0.38))
	WB.box(self, Vector3(11.6, 0.73, 1.9), Vector3(13.8, 0.78, 2.8), wood)
	WB.box(self, Vector3(11.65, 0, 1.95), Vector3(12.1, 0.73, 2.75), wood, false)
	WB.box(self, Vector3(13.3, 0, 1.95), Vector3(13.75, 0.73, 2.75), wood, false)
	WB.model(self, "modern_arm_chair_01", 12.7, 1.35, 0.0)
	WB.model(self, "ArmChair_01", 12.0, 4.1, 160.0)
	WB.model(self, "ArmChair_01", 13.6, 4.1, 200.0)
	WB.box(self, Vector3(11.2, 0, 3.3), Vector3(14.4, 0.012, 5.2), WB.flat(Color(0.35, 0.38, 0.42), 0.95), false)
	_monitor(Vector3(13.0, 0.78, 2.15), 200.0, "helena_pc")
	WB.model(self, "office_notepads", 12.3, 2.4, 10.0, 0.5, 0.78, false)
	WB.model(self, "clipboard", 11.95, 2.3, -20.0, 1.0, 0.78, false)
	for i in 2:
		Books.unit(self, Vector3(15.3, 0, 2.0 + i * 1.1), -90.0, 1.0, 2.2, 0.32, [0.4, 0.8, 1.2, 1.6], WB.flat(Color(0.85, 0.85, 0.82), 0.4), rng, 0.85)
	WB.model(self, "drawer_cabinet", 10.32, 5.6, 90.0, 0.8)
	WB.model(self, "potted_plant_01", 10.6, 0.6, 0.0)
	for k in 3:
		var f := WB.model(self, "fancy_picture_frame_01", 10.07, 2.2 + k * 0.75, 90.0, 0.55, 1.6 + (k % 2) * 0.35, false)
		f.name = "diploma_%d" % k
	_floor_lamp(Vector3(14.9, 0, 5.8))
	var desk_lamp := WB.omni(self, Vector3(11.9, 1.2, 2.3), Color(1.0, 0.82, 0.6), 0.9, 3.0, true)
	_room("consultorio", [desk_lamp], [])
	WB.model(self, "desk_lamp_arm_01", 11.9, 2.4, 160.0, 0.9, 0.78, false)
	hotspots.computador = Hotspot.add(self, Vector3(13.0, 1.1, 2.15), Vector3(0.6, 0.45, 0.2), _prompt("computador"), func(p): _say("computador", p))
	hotspots.secretaria_helena = Hotspot.add(self, Vector3(12.7, 0.85, 2.35), Vector3(2.2, 0.3, 0.9), _prompt("secretaria_helena"), func(p): _say("secretaria_helena", p))
	hotspots.diplomas = Hotspot.add(self, Vector3(10.1, 2.0, 2.95), Vector3(0.1, 0.8, 1.7), _prompt("diplomas"), func(p): _say("diplomas", p))
	_tube("consultorio", Vector3(12.7, 0, 3.5), 0.8)
	_sw(Vector3(13.4, 1.2, 6.93), 0.0, ["consultorio"])


func _floor_lamp(at: Vector3) -> void:
	var metal := WB.flat(Color(0.15, 0.13, 0.1), 0.4, 0.8)
	WB.box(self, at + Vector3(-0.14, 0, -0.14), at + Vector3(0.14, 0.03, 0.14), metal, false)
	WB.box(self, at + Vector3(-0.012, 0.03, -0.012), at + Vector3(0.012, 1.45, 0.012), metal, false)
	var l := WB.omni(self, at + Vector3(0, 1.45, 0), Color(1.0, 0.8, 0.55), 0.7, 3.5, false)
	_room("consultorio", [l], [])


# =================================================================== archive
func _build_archive() -> void:
	var cardboard := WB.flat(Color(0.62, 0.5, 0.36), 0.85)
	var blue := WB.flat(Color(0.2, 0.3, 0.5), 0.6)
	for row in 3:
		var z := 1.4 + row * 1.6
		var shelf := WB.model(self, "steel_frame_shelves_01", 17.5, z, 0.0, 0.1)
		var fb := WB.footprint(shelf)
		# archive boxes and binders on each level
		for lvl in 4:
			var y := 0.12 + lvl * 0.52
			var x := fb.position.x + 0.05
			while x < fb.end.x - 0.3:
				var w := rng.randf_range(0.08, 0.12) if rng.randf() < 0.6 else 0.32
				var m: Material = blue if w < 0.2 else cardboard
				WB.box(self, Vector3(x, y, z - 0.18), Vector3(x + w - 0.01, y + (0.3 if w < 0.2 else 0.25), z + 0.18), m, false)
				x += w
	WB.model(self, "drawer_cabinet", 19.1, 6.3, -90.0, 0.8)
	WB.model(self, "drawer_cabinet", 15.85, 6.3, 90.0, 0.8)
	hotspots.ficha = Hotspot.add(self, Vector3(19.0, 1.0, 6.3), Vector3(0.4, 1.6, 0.9), _prompt("ficha"), func(p): _say("ficha", p))
	_tube("arquivo", Vector3(17.5, 0, 2.2), 0.7)
	_tube("arquivo", Vector3(17.5, 0, 5.2), 0.7)
	_sw(Vector3(17.25, 1.2, 6.93), 0.0, ["arquivo"])


# =================================================================== nurses' station
func _build_station() -> void:
	var white := WB.flat(Color(0.92, 0.92, 0.9), 0.35)
	WB.box(self, Vector3(19.75, 0.95, 6.85), Vector3(21.85, 1.0, 7.3), white, false)
	WB.box(self, Vector3(19.7, 0.72, 5.6), Vector3(22.6, 0.76, 6.6), white)
	_monitor(Vector3(20.6, 0.76, 6.1), 180.0, "enfermaria_pc")
	WB.model(self, "medical_box", 21.6, 6.1, 10.0, 1.0, 0.76, false)
	WB.model(self, "clipboard", 22.1, 6.3, -15.0, 1.0, 0.76, false)
	WB.model(self, "modern_arm_chair_01", 20.8, 5.1, 180.0, 0.9)
	# the key box on the wall
	WB.box(self, Vector3(19.6, 1.3, 2.2), Vector3(19.66, 1.9, 2.8), WB.flat(Color(0.75, 0.75, 0.73), 0.4, 0.6), false)
	WB.text(self, "CHAVES", Vector3(19.67, 1.82, 2.5), 90.0, 0.05, Color(0.15, 0.15, 0.15))
	hotspots.chaves = Hotspot.add(self, Vector3(19.65, 1.6, 2.5), Vector3(0.12, 0.6, 0.6), _prompt("chaves"), func(p): _say("chaves", p))
	_tube("enfermaria", Vector3(21.2, 0, 4.0), 0.9)
	_sw(Vector3(22.95, 1.2, 6.4), -90.0, ["enfermaria"])


func _build_stairs() -> void:
	var concrete := WB.mat("painted_concrete", 1.5, Color(0.7, 0.7, 0.68))
	# going down, behind a locked gate
	for i in 8:
		WB.box(self, Vector3(23.2, -0.1 - (i + 1) * 0.17, 0.4 + i * 0.28), Vector3(24.6, -0.1 - i * 0.17, 0.4 + (i + 1) * 0.28), concrete, false)
	var gate := WB.flat(Color(0.3, 0.3, 0.3), 0.4, 0.8)
	for k in 9:
		WB.box(self, Vector3(23.2 + k * 0.17, 0, 2.9), Vector3(23.22 + k * 0.17, 1.1, 2.92), gate, true)
	var bulb := WB.omni(self, Vector3(24.5, 2.5, 3.5), Color(1.0, 0.85, 0.65), 0.6, 4.0, true)
	_room("escada", [bulb], [])
	hotspots.portao = Hotspot.add(self, Vector3(23.9, 0.6, 2.91), Vector3(1.5, 1.1, 0.1), _prompt("portao"), func(p): _say("portao", p))


# =================================================================== inpatient rooms
func _build_rooms() -> void:
	var linen := WB.flat(Color(0.88, 0.89, 0.88), 0.9)
	var blanket := WB.flat(Color(0.55, 0.65, 0.7), 0.95)
	for i in ROOM_X.size():
		var x0: float = ROOM_X[i]
		var id := "quarto_%d" % (i + 1)
		var bed := WB.model(self, "old_bed_frame", x0 + 2.2, 14.6, 0.0)
		var bb := WB.footprint(bed)
		WB.box(self, Vector3(bb.position.x + 0.06, 0.36, bb.position.z + 0.06), Vector3(bb.end.x - 0.06, 0.52, bb.end.z - 0.06), linen, false)
		if i != 3:
			WB.box(self, Vector3(bb.position.x + 0.04, 0.52, bb.position.z + 0.5), Vector3(bb.end.x - 0.04, 0.58, bb.end.z - 0.03), blanket, false)
		WB.box(self, Vector3(bb.position.x + 0.15, 0.52, bb.end.z - 0.42), Vector3(bb.end.x - 0.15, 0.64, bb.end.z - 0.1), linen, false)
		WB.model(self, "painted_wooden_nightstand", x0 + 3.0, 15.6, 180.0, 0.9)
		WB.model(self, "dining_chair_02", x0 + 0.7, 13.0, 60.0)
		var l := WB.omni(self, Vector3(x0 + 1.7, H - 0.3, 12.6), Color(0.95, 0.95, 0.92), 0.8, 4.5, true)
		var glow := WB.emissive(Color(0.95, 0.97, 1.0), 0.0)
		WB.box(self, Vector3(x0 + 1.4, H - 0.03, 12.3), Vector3(x0 + 2.0, H - 0.01, 12.9), glow, false)
		_room(id, [l], [glow])
		_sw(Vector3(x0 + 1.45, 1.2, 9.27), 0.0, [id])
	# room 4 is waiting for someone: a bag on the bed, a card on the door
	var x4: float = ROOM_X[3]
	WB.model(self, "vintage_suitcase", x4 + 2.2, 14.3, 80.0, 0.45, 0.52, false)
	WB.box(self, Vector3(x4 + 1.75, 0.52, 13.4), Vector3(x4 + 2.5, 0.58, 13.85), WB.flat(Color(0.82, 0.84, 0.86), 0.9), false)
	WB.box(self, Vector3(x4 + 0.85, 1.5, 9.13), Vector3(x4 + 1.25, 1.62, 9.14), WB.flat(Color(0.95, 0.95, 0.9), 0.6), false)
	WB.text(self, "Daniel R.", Vector3(x4 + 1.05, 1.56, 9.125), 180.0, 0.035, Color(0.1, 0.1, 0.1))
	hotspots.cartao_quarto = Hotspot.add(self, Vector3(x4 + 1.05, 1.56, 9.12), Vector3(0.45, 0.2, 0.08), _prompt("cartao_quarto"), func(p): _say("cartao_quarto", p))
	hotspots.cama_4 = Hotspot.add(self, Vector3(x4 + 2.2, 0.6, 14.6), Vector3(1.0, 0.4, 2.0), _prompt("cama_4"), func(p): _say("cama_4", p))
	# linen room: shelves of folded sheets
	for lvl in 5:
		WB.box(self, Vector3(0.1, 0.3 + lvl * 0.42, 11.0), Vector3(0.6, 0.32 + lvl * 0.42, 15.8), WB.flat(Color(0.7, 0.7, 0.68), 0.5, 0.5), false)
		var z := 11.1
		while z < 15.6:
			WB.box(self, Vector3(0.12, 0.32 + lvl * 0.42, z), Vector3(0.55, 0.32 + lvl * 0.42 + rng.randf_range(0.12, 0.25), z + 0.38), linen, false)
			z += 0.45
	var lb := WB.omni(self, Vector3(1.0, 2.5, 12.6), Color(1.0, 0.88, 0.7), 0.5, 3.5, true)
	_room("rouparia", [lb], [])
	# toilets: a sink and a mirror
	var wl := WB.omni(self, Vector3(24.2, 2.5, 12.6), COOL, 0.6, 4.0, true)
	_room("wc", [wl], [])
	WB.box(self, Vector3(25.5, 0.78, 11.0), Vector3(26.0, 0.9, 11.6), WB.flat(Color(0.93, 0.93, 0.92), 0.12), true)
	WB.box(self, Vector3(25.97, 1.2, 10.9), Vector3(26.0, 1.9, 11.7), WB.flat(Color(0.9, 0.92, 0.94), 0.02, 1.0), false)


# =================================================================== street
func _build_outside() -> void:
	var facade := WB.mat("painted_plaster_wall", 3.0, Color(0.92, 0.92, 0.9))
	var pav := WB.mat("stone_pavers", 1.4, Color(0.75, 0.75, 0.75))
	var asphalt := WB.mat("asphalt_06", 4.0, Color(0.6, 0.6, 0.6))
	WB.box(self, Vector3(-EXT, -0.6, -EXT), Vector3(26 + EXT, -0.1, 16 + EXT), facade)
	WB.box(self, Vector3(-30, -1.0, -3.0), Vector3(50, -0.45, -EXT), pav)
	WB.box(self, Vector3(-30, -1.2, -10.0), Vector3(50, -0.6, -3.0), asphalt)
	WB.box(self, Vector3(-30, -1.0, -13.0), Vector3(50, -0.45, -10.0), pav)
	WB.box(self, Vector3(-30, -0.45, -14.0), Vector3(50, 1.2, -13.0), facade)
	WB.box(self, Vector3(3.6, -0.45, -1.2), Vector3(6.4, -0.1, -EXT), WB.mat("marble_01", 1.0, Color(0.75, 0.75, 0.72)))
	WB.text(self, "CLÍNICA ATLÂNTICO", Vector3(5.0, 2.65, -0.33), 180.0, 0.22, Color(0.2, 0.3, 0.32))
	for x in [-2.0, 12.0, 26.0]:
		WB.model(self, "street_lamp_01", x, -2.75, 0.0, 1.0, -0.45)
		var l := SpotLight3D.new()
		l.position = Vector3(x, 3.25, -3.0)
		l.rotation_degrees.x = -90
		l.light_color = STREET_SODIUM
		l.light_energy = 8.0
		l.spot_range = 11.0
		l.spot_angle = 62.0
		l.spot_angle_attenuation = 3.0
		l.shadow_enabled = true
		add_child(l)
		street_lights.append(l)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-40, 160, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.05
	moon.shadow_enabled = true
	add_child(moon)


# =================================================================== story
func _sw(at: Vector3, rot: float, targets: Array, prompt := "") -> void:
	_switch(targets[0], at, rot, targets, prompt)


func _build_story_hooks() -> void:
	spawns = {
		"entrada": [Vector3(5.0, 0.02, 1.4), 180.0],
		"consulta": [Vector3(12.8, 0.02, 4.6), 0.0, -8.0],
		"corredor": [Vector3(6.0, 0.02, 8.1), -90.0],
		"quarto_4": [Vector3(ROOM_X[3] + 1.0, 0.02, 11.0), 180.0],
	}
	spots = {
		"front_door": Vector3(5.0, 1.3, -0.5), "street": Vector3(5.0, 0.5, -6.0),
		"corridor": Vector3(14.0, 1.6, 8.1), "landing": Vector3(24.5, 1.0, 1.5),
		"kitchen": Vector3(20.8, 1.0, 5.0), "wc": Vector3(24.2, 1.0, 12.6), "window": Vector3(13.0, 1.6, -0.6),
	}
	add_hide("cama_4", Vector3(ROOM_X[3] + 2.2, 0.25, 13.55), Vector3(1.0, 0.4, 0.2), "Esconder debaixo da cama",
		[Vector3(ROOM_X[3] + 2.2, 0.18, 14.4), 180.0, 4.0], [Vector3(ROOM_X[3] + 1.2, 0.02, 13.0), 180.0])
	add_hide("arquivo", Vector3(17.5, 1.0, 3.8), Vector3(1.0, 1.8, 0.3), "Esconder entre as estantes",
		[Vector3(17.5, 1.5, 3.8), 0.0, -4.0], [Vector3(16.5, 0.02, 3.8), 0.0])
	add_hide("rouparia", Vector3(1.0, 1.0, 15.5), Vector3(1.0, 1.8, 0.5), "Esconder atrás dos lençóis",
		[Vector3(1.1, 1.5, 15.6), 180.0, -4.0], [Vector3(1.2, 0.02, 14.0), 0.0])
	add_hide("consultorio", Vector3(12.7, 0.4, 2.35), Vector3(1.4, 0.7, 0.6), "Esconder debaixo da secretária",
		[Vector3(12.7, 0.4, 2.3), 180.0, 4.0], [Vector3(12.7, 0.02, 3.6), 0.0])
	# things that change: room doors, the wheelchair, the TV, the corridor tubes
	for i in ROOM_X.size():
		var d: Door = doors["quarto_%d" % (i + 1)]
		add_change("porta_q%d" % (i + 1), d.global_position + Vector3(0.5, 1.0, 0), func(): d.set_open(not d.is_open, true), "door", -22.0)
	add_change("cadeira_rodas", wheelchair.position + Vector3(0, 0.6, 0), func():
		wheelchair.position.x += randf_range(-1.2, 1.2)
		wheelchair.rotation_degrees.y += randf_range(-60, 60), "click_far", -18.0)
	add_change("tv", Vector3(0.1, 1.9, 2.8), func(): tv_mat.emission_energy_multiplier = 0.6 if tv_mat.emission_energy_multiplier == 0.0 else 0.0, "click_far", -14.0)
	for z in ["corredor_a", "corredor_b", "corredor_c"]:
		add_change("luz_" + z, room_bounds[z].get_center(), func(): set_room_light(z, not rooms[z].on), "switch", -16.0)


func set_daylight(d: float) -> void:
	var night := d < 0.35
	for l in street_lights:
		l.visible = night
	moon.visible = d < 0.5
	for f in sky_fills:
		f.visible = d > 0.02
		f.light_energy = float(f.get_meta("base")) * d
