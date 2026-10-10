class_name Road
extends Location
## The way to the Cais Velho, the night Daniel walked it — and walks it again.
##   Rua das Gaivotas (his building, nº 12)  x -30..60
##   EN125, fields, the petrol station        x 60..200
##   Largo do Cais: the café with the camera, the bar O Farol   x 200..245
##   the Cais Velho: stone quay, wooden end, the steps down to the water
## The sea is to the south (z > 22). One place, several spawns; the story's
## "cais" is this place too.

const SEA_Y := -1.6
const QUAY_Y := 0.5
const DECK_Y := 0.56
const STREET_SODIUM := Color(1.0, 0.6, 0.28)

var rng := RandomNumberGenerator.new()
var street_lights: Array[Light3D] = []
var lit_windows: Array[StandardMaterial3D] = []
var moon: DirectionalLight3D
var rain_fx: GPUParticles3D
var raining := true
var broken_lamp: SpotLight3D
var marker_light: StandardMaterial3D
var _t := 0.0
var _broken_t := 0.0

var m_asphalt: Material
var m_pav: Material
var m_calcada: Material
var m_stone: Material
var m_deck: Material
var m_ground: Material
var m_sand: Material


func _ready() -> void:
	loc_id = "caminho"
	aliases = ["cais"]
	outdoor = true
	nav_cell = 0.25
	load_texts("caminho")
	rng.seed = 1410
	m_asphalt = WB.mat("asphalt_06", 4.0, Color(0.55, 0.55, 0.55), 0.45)
	m_pav = WB.mat("stone_pavers", 1.4, Color(0.7, 0.7, 0.7), 0.5)
	m_calcada = WB.mat("cobblestone_floor_04", 1.6, Color(0.82, 0.8, 0.76), 0.45)
	m_stone = WB.mat("rough_block_wall", 2.5, Color(0.6, 0.58, 0.55))
	m_deck = WB.mat("weathered_planks", 1.6, Color(0.7, 0.62, 0.52), 0.6)
	m_ground = WB.mat("forest_ground_05", 4.0, Color(0.55, 0.55, 0.5))
	m_sand = WB.mat("damp_sand", 3.0, Color(0.7, 0.66, 0.6), 0.5)
	m_wall = WB.mat("painted_plaster_wall", 3.0, Color(0.86, 0.82, 0.74))
	_build_gaivotas()
	_build_en125()
	_build_station()
	_build_largo()
	_build_shore_and_quay()
	_build_sea()
	_build_bounds()
	_build_story_hooks()
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, 150, 0)
	moon.light_color = Color(0.55, 0.65, 0.9)
	moon.light_energy = 0.06
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	moon.light_volumetric_fog_energy = 0.0
	add_child(moon)


# =================================================================== helpers
func _ground(x0: float, z0: float, x1: float, z1: float, top: float, m: Material) -> void:
	WB.box(self, Vector3(x0, top - 0.5, z0), Vector3(x1, top, z1), m)


## A row building: front at z_front facing `out` (-1 = facing -z), `floors`
## storeys, windows (some lit), a door, eaves.
func _building(x0: float, x1: float, z_front: float, depth: float, floors: int, out: float, color: Color, door_x := -1.0, number := "", lit := 0.15) -> void:
	var h := floors * 3.0 + 0.6
	var zb := z_front - out * depth
	var mat := WB.mat("painted_plaster_wall", 3.0, color)
	WB.box(self, Vector3(x0, 0, minf(z_front, zb)), Vector3(x1, h, maxf(z_front, zb)), mat)
	WB.box(self, Vector3(x0 - 0.05, h, minf(z_front, zb) - 0.3 * absf(out)), Vector3(x1 + 0.05, h + 0.25, maxf(z_front, zb) + 0.3 * absf(out)), WB.flat(Color(0.45, 0.25, 0.18), 0.8))
	var dark := WB.flat(Color(0.03, 0.035, 0.045), 0.08, 0.3)
	var frame := WB.flat(Color(0.85, 0.83, 0.8), 0.5)
	var f := z_front + out * 0.02
	for fl in floors:
		var x := x0 + 1.0
		while x < x1 - 1.2:
			if fl == 0 and door_x >= 0.0 and absf(x + 0.55 - door_x) < 1.2:
				x += 2.2
				continue
			var y := 0.9 + fl * 3.0
			var m: Material = dark
			if rng.randf() < lit:
				var e := WB.emissive(Color(0.9, 0.6, 0.32), rng.randf_range(0.12, 0.3))
				e.set_meta("energy", e.emission_energy_multiplier)
				lit_windows.append(e)
				m = e
			WB.box(self, Vector3(x - 0.06, y - 0.06, minf(f, f + out * 0.04)), Vector3(x + 1.16, y + 1.56, maxf(f, f + out * 0.04)), frame, false)
			WB.box(self, Vector3(x, y, minf(f + out * 0.04, f + out * 0.05)), Vector3(x + 1.1, y + 1.5, maxf(f + out * 0.04, f + out * 0.05)), m, false)
			if fl > 0 and rng.randf() < 0.3:
				# a little iron balcony
				WB.box(self, Vector3(x - 0.15, y - 0.1, minf(f, f + out * 0.6)), Vector3(x + 1.25, y - 0.05, maxf(f, f + out * 0.6)), WB.flat(Color(0.12, 0.12, 0.12), 0.5, 0.6), false)
				WB.box(self, Vector3(x - 0.15, y - 0.05, minf(f + out * 0.57, f + out * 0.6)), Vector3(x + 1.25, y + 0.85, maxf(f + out * 0.57, f + out * 0.6)), WB.flat(Color(0.12, 0.12, 0.12, 0.85), 0.5, 0.6), false)
			x += 2.2
	if door_x >= 0.0:
		WB.box(self, Vector3(door_x - 0.6, 0, minf(f, f + out * 0.05)), Vector3(door_x + 0.6, 2.4, maxf(f, f + out * 0.05)), WB.mat("dark_wood", 1.0, Color(0.35, 0.25, 0.18)), false)
		if number != "":
			WB.text(self, number, Vector3(door_x, 2.65, f + out * 0.06), 0.0 if out > 0 else 180.0, 0.16, Color(0.2, 0.2, 0.2))


func _lamp(x: float, z: float, yaw: float, shadow := true, y := 0.0) -> SpotLight3D:
	WB.model(self, "street_lamp_01", x, z, yaw, 1.0, y)
	var l := SpotLight3D.new()
	l.position = Vector3(x, y + 3.25, z)
	l.rotation_degrees.x = -90
	l.light_color = STREET_SODIUM
	l.light_energy = 11.0
	l.spot_range = 16.0
	l.spot_angle = 74.0
	l.spot_angle_attenuation = 3.0
	l.shadow_enabled = shadow
	l.light_volumetric_fog_energy = 1.5
	add_child(l)
	var fill := WB.omni(self, Vector3(x, y + 3.0, z), STREET_SODIUM, 0.9, 11.0, false)
	fill.light_volumetric_fog_energy = 0.4
	l.set_meta("fill", fill)
	var glow := WB.emissive(STREET_SODIUM, 4.0)
	var g := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.12
	g.mesh = sm
	g.material_override = glow
	g.position = Vector3(x, y + 3.4, z)
	add_child(g)
	l.set_meta("glow", glow)
	street_lights.append(l)
	lamps.append(l)
	return l


func _sign(x: float, z: float, yaw: float, t: String) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(x, 0, z)
	holder.rotation_degrees.y = yaw
	add_child(holder)
	var metal := WB.flat(Color(0.5, 0.5, 0.5), 0.4, 0.8)
	WB.box(holder, Vector3(-0.04, 0, -0.04), Vector3(0.04, 2.2, 0.04), metal)
	WB.box(holder, Vector3(-0.7, 2.2, -0.02), Vector3(0.7, 2.75, 0.02), WB.flat(Color(0.9, 0.9, 0.88), 0.4), false)
	WB.text(holder, t, Vector3(0, 2.47, 0.025), 0.0, 0.11, Color(0.1, 0.15, 0.35))


# =================================================================== Rua das Gaivotas
func _build_gaivotas() -> void:
	_ground(-30, -3.5, 60, 3.5, -0.05, m_asphalt)
	_ground(-30, -6.0, 60, -3.5, 0.1, m_pav)
	_ground(-30, 3.5, 60, 6.0, 0.1, m_pav)
	var colors := [Color(0.88, 0.84, 0.74), Color(0.85, 0.78, 0.66), Color(0.8, 0.84, 0.86), Color(0.9, 0.86, 0.8), Color(0.82, 0.7, 0.6)]
	var x := -30.0
	var i := 0
	while x < 60.0:
		var w := rng.randf_range(6.0, 10.0)
		if x <= 0.0 and x + w > 0.0:
			w = -x
		if absf(x) < 0.01:
			# Daniel's building: nº 12, his sala lit on the ground floor
			_building(0.0, 10.0, -6.0, 9.0, 3, 1.0, Color(0.86, 0.82, 0.74), 8.6, "12", 0.1)
			var sala := WB.emissive(Color(1.0, 0.72, 0.42), 0.9)
			WB.box(self, Vector3(1.0, 1.35, -5.99), Vector3(2.2, 2.85, -5.96), sala, false)
			WB.box(self, Vector3(3.2, 1.35, -5.99), Vector3(4.4, 2.85, -5.96), sala, false)
			x = 10.0
			continue
		if w > 0.5:
			_building(x, x + w, -6.0, 9.0, rng.randi_range(2, 3), 1.0, colors[i % colors.size()], x + w * 0.5 if rng.randf() < 0.6 else -1.0, str(2 * i + 14))
			_building(x, x + w, 6.0, 9.0, rng.randi_range(2, 3), -1.0, colors[(i + 2) % colors.size()], x + w * 0.5 if rng.randf() < 0.6 else -1.0, str(2 * i + 15))
		x += w
		i += 1
	for lx in [-16.0, 3.0, 18.0, 33.0, 48.0]:
		_lamp(lx, -4.7, 0.0, lx == 3.0, 0.1)
	WB.model(self, "covered_car", 14.0, 2.5, 90.0)
	WB.model(self, "metal_trash_can", -3.0, -5.2, 0.0, 1.0, 0.1)
	WB.model(self, "fire_hydrant", 30.0, -5.6, 0.0, 1.0, 0.1)
	WB.text(self, "Rua das Gaivotas", Vector3(-1.0, 3.2, -5.98), 0.0, 0.18, Color(0.15, 0.2, 0.4))


# =================================================================== EN125
func _build_en125() -> void:
	_ground(60, -3.5, 200, 3.5, -0.05, m_asphalt)
	_ground(60, -45, 200, -3.5, 0.0, m_ground)
	_ground(60, 3.5, 150, 22.0, 0.0, m_ground)
	# road paint: the centre line and the edges
	var paint := WB.flat(Color(0.8, 0.8, 0.75), 0.6)
	var x := 61.0
	while x < 199.0:
		WB.box(self, Vector3(x, -0.045, -0.06), Vector3(x + 3.0, -0.04, 0.06), paint, false)
		x += 6.0
	WB.box(self, Vector3(60, -0.045, -3.3), Vector3(200, -0.04, -3.2), paint, false)
	WB.box(self, Vector3(60, -0.045, 3.2), Vector3(200, -0.04, 3.3), paint, false)
	# low dry-stone walls along the fields, shrubs, poles with wires
	for side in [-1.0, 1.0]:
		WB.box(self, Vector3(60, 0, side * 5.0 - 0.3), Vector3(200, 0.7, side * 5.0 + 0.3), m_stone)
	var px := 64.0
	while px < 200.0:
		var pole := WB.flat(Color(0.32, 0.26, 0.2), 0.8)
		WB.box(self, Vector3(px - 0.12, 0, -7.12), Vector3(px + 0.12, 8.0, -6.88), pole)
		WB.box(self, Vector3(px - 0.9, 7.5, -7.05), Vector3(px + 0.9, 7.6, -6.95), pole, false)
		px += 30.0
	for k in 3:
		var y := 7.3 - k * 0.08
		WB.box(self, Vector3(64, y, -7.02 + k * 0.5 - 0.5), Vector3(200, y + 0.015, -7.0 + k * 0.5 - 0.5), WB.flat(Color(0.05, 0.05, 0.05), 0.5), false)
	for k in 26:
		var sx := rng.randf_range(62, 198)
		var sz := rng.randf_range(-40, -8) if rng.randf() < 0.6 else rng.randf_range(8, 20)
		if sx > 106 and sx < 146 and sz < 0:
			continue
		WB.model(self, "shrub_02", sx, sz, rng.randf_range(0, 360), rng.randf_range(0.5, 0.9), 0.0, false)
	for k in 8:
		WB.model(self, "boulder_01", rng.randf_range(62, 198), rng.randf_range(-40, -10), rng.randf_range(0, 360), rng.randf_range(0.6, 1.4), 0.0, false)
	_sign(66.0, -4.2, 0.0, "EN125")
	_sign(190.0, -4.2, 0.0, "Cais Velho →")
	for lx in [80.0, 105.0, 150.0, 175.0, 196.0]:
		_lamp(lx, -4.2, 0.0, false)


# =================================================================== the petrol station
func _build_station() -> void:
	var white := WB.flat(Color(0.88, 0.88, 0.86), 0.4)
	var red := WB.flat(Color(0.65, 0.12, 0.1), 0.45)
	_ground(108, -32, 145, -5.2, 0.02, WB.mat("concrete_wall_003", 3.0, Color(0.6, 0.6, 0.58), 0.6))
	# canopy on four pillars
	for p in [Vector2(113, -11), Vector2(131, -11), Vector2(113, -20), Vector2(131, -20)]:
		WB.box(self, Vector3(p.x - 0.25, 0, p.y - 0.25), Vector3(p.x + 0.25, 4.6, p.y + 0.25), white)
	WB.box(self, Vector3(111, 4.6, -22), Vector3(133, 5.4, -9), white)
	WB.box(self, Vector3(111, 4.6, -9.05), Vector3(133, 5.4, -8.95), red, false)
	WB.text(self, "COMBUSTÍVEIS · 24 h", Vector3(122, 5.0, -8.92), 0.0, 0.4, Color(0.95, 0.95, 0.92))
	# pumps on two islands
	for ix in [117.0, 127.0]:
		WB.box(self, Vector3(ix - 2.5, 0, -16.2), Vector3(ix + 2.5, 0.18, -14.8), WB.mat("concrete_wall_003", 1.0, Color(0.7, 0.7, 0.68)))
		for dx in [-1.4, 1.4]:
			WB.box(self, Vector3(ix + dx - 0.35, 0.18, -15.8), Vector3(ix + dx + 0.35, 1.9, -15.2), white)
			WB.box(self, Vector3(ix + dx - 0.36, 1.55, -15.81), Vector3(ix + dx + 0.36, 1.85, -15.19), red, false)
			var scr := WB.emissive(Color(0.3, 0.8, 0.4), 0.6)
			WB.box(self, Vector3(ix + dx - 0.18, 1.2, -15.82), Vector3(ix + dx + 0.18, 1.35, -15.81), scr, false)
	# the shop, closed, and the night window (guiché)
	WB.box(self, Vector3(128, 0, -32), Vector3(142, 3.6, -24), WB.mat("painted_plaster_wall", 3.0, Color(0.9, 0.9, 0.88)))
	WB.model(self, "rollershutter_door", 131.5, -23.85, 0.0, 1.0)
	var kiosk := WB.emissive(Color(1.0, 0.92, 0.75), 0.8)
	WB.box(self, Vector3(137.5, 1.0, -23.99), Vector3(139.5, 2.2, -23.96), kiosk, false)
	WB.text(self, "PAGAMENTO NOTURNO", Vector3(138.5, 2.45, -23.94), 0.0, 0.12, Color(0.15, 0.15, 0.15))
	var kl := WB.omni(self, Vector3(138.5, 1.6, -23.2), Color(1.0, 0.9, 0.72), 0.8, 4.0, false)
	street_lights.append(kl)
	WB.model(self, "security_light", 134.0, -23.75, 0.0, 1.0, 3.2, false)
	var cl := WB.omni(self, Vector3(122, 4.4, -15.5), Color(0.9, 0.95, 1.0), 2.2, 14.0, true)
	street_lights.append(cl)
	WB.model(self, "utility_box_01", 142.5, -23.4, 0.0, 1.0, 0.02)
	WB.model(self, "metal_trash_can", 126.0, -24.0, 0.0, 1.0, 0.02)
	hotspots.guiche = Hotspot.add(self, Vector3(138.5, 1.6, -23.9), Vector3(2.2, 1.4, 0.3), _prompt("guiche"), func(p): _say("guiche", p))


# =================================================================== Largo do Cais
func _build_largo() -> void:
	_ground(200, -26, 248, 20, 0.08, m_calcada)
	# the café with the camera over the door, and the bar O Farol
	_building(200.0, 214.0, -26.0, 10.0, 2, 1.0, Color(0.92, 0.88, 0.8), -1.0, "", 0.1)
	WB.model(self, "rollershutter_door", 205.0, -25.85, 0.0, 1.0, 0.08)
	WB.box(self, Vector3(202, 3.0, -25.95), Vector3(212, 3.5, -25.9), WB.flat(Color(0.15, 0.25, 0.3), 0.5), false)
	WB.text(self, "CAFÉ DO LARGO", Vector3(207, 3.25, -25.88), 0.0, 0.26, Color(0.95, 0.92, 0.85))
	# the camera that saw the car at 03:04
	WB.box(self, Vector3(209.7, 2.75, -25.9), Vector3(210.0, 2.95, -25.55), WB.flat(Color(0.85, 0.85, 0.83), 0.4), false)
	var led := WB.emissive(Color(1.0, 0.1, 0.1), 2.0)
	WB.box(self, Vector3(209.82, 2.8, -25.56), Vector3(209.86, 2.84, -25.54), led, false)
	hotspots.camara = Hotspot.add(self, Vector3(209.85, 2.85, -25.7), Vector3(0.5, 0.4, 0.5), _prompt("camara"), func(p): _say("camara", p))
	_building(214.0, 228.0, -26.0, 10.0, 3, 1.0, Color(0.82, 0.74, 0.62), 221.0, "4", 0.2)
	_building(228.0, 246.0, -26.0, 10.0, 2, 1.0, Color(0.2, 0.28, 0.32), 236.0, "", 0.0)
	var neon := WB.emissive(Color(0.3, 0.75, 1.0), 2.4)
	WB.text(self, "O FAROL", Vector3(237, 3.6, -25.9), 0.0, 0.5, Color(0.6, 0.85, 1.0)).modulate = Color(0.6, 0.85, 1.0)
	WB.box(self, Vector3(232, 3.25, -25.97), Vector3(242, 3.32, -25.94), neon, false)
	var nl := WB.omni(self, Vector3(237, 3.4, -24.8), Color(0.35, 0.7, 1.0), 0.7, 6.0, false)
	street_lights.append(nl)
	hotspots.farol = Hotspot.add(self, Vector3(236, 1.2, -25.8), Vector3(1.4, 2.4, 0.3), _prompt("farol"), func(p): _say("farol", p))
	# benches, a lamp, cars, bins
	WB.model(self, "modular_street_seating", 222.0, 6.0, 180.0, 0.6, 0.08)
	WB.model(self, "modular_street_seating", 212.0, 12.0, 90.0, 0.6, 0.08)
	_lamp(222.0, -2.0, 0.0, true, 0.08)
	_lamp(240.0, 14.0, 180.0, false, 0.08)
	WB.model(self, "covered_car", 244.0, -6.0, 0.0, 1.0, 0.08)
	WB.model(self, "metal_trash_can", 201.5, -22.0, 90.0, 1.0, 0.08)
	WB.model(self, "fire_hydrant", 215.0, -24.8, 0.0, 1.0, 0.08)
	WB.model(self, "concrete_road_barrier", 230.0, 18.0, 0.0, 1.0, 0.08)
	WB.model(self, "concrete_road_barrier", 212.0, 18.0, 0.0, 1.0, 0.08)


# =================================================================== the shore and the Cais Velho
func _build_shore_and_quay() -> void:
	# sea wall along the largo and the beach east and west
	WB.box(self, Vector3(150, -3.0, 20), Vector3(216, 0.08, 22), m_stone)
	WB.box(self, Vector3(226, -3.0, 20), Vector3(300, 0.08, 22), m_stone)
	var rail := WB.flat(Color(0.2, 0.22, 0.22), 0.4, 0.8)
	for seg in [[150.0, 216.0], [226.0, 300.0]]:
		WB.box(self, Vector3(seg[0], 1.0, 20.9), Vector3(seg[1], 1.06, 21.0), rail, false)
		var x: float = seg[0]
		while x < seg[1]:
			WB.box(self, Vector3(x, 0.08, 20.92), Vector3(x + 0.05, 1.0, 20.98), rail, false)
			x += 2.0
	_ground(150, 22, 205, 34, -1.2, m_sand)
	_ground(237, 22, 300, 34, -1.2, m_sand)
	# rocks against the quay foot
	var r1 := WB.model(self, "coast_rocks_01", 200.0, 40.0, 30.0, 0.35, -2.4, false)
	var r2 := WB.model(self, "coast_rocks_01", 244.0, 42.0, 200.0, 0.3, -2.4, false)
	# the stone quay
	WB.box(self, Vector3(216, -4.0, 20), Vector3(226, QUAY_Y, 90), m_stone)
	WB.box(self, Vector3(216.05, QUAY_Y, 20), Vector3(225.95, QUAY_Y + 0.02, 90), WB.mat("concrete_wall_003", 2.5, Color(0.55, 0.55, 0.53), 0.5), false)
	# granite kerb on both edges
	for x in [216.0, 225.7]:
		WB.box(self, Vector3(x, QUAY_Y, 20), Vector3(x + 0.3, QUAY_Y + 0.18, 90), WB.mat("marble_01", 1.0, Color(0.5, 0.5, 0.48)), false)
	# bollards
	var iron := WB.flat(Color(0.08, 0.08, 0.08), 0.5, 0.7)
	var z := 26.0
	while z < 90.0:
		for x in [216.6, 225.4]:
			var b := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.18
			cm.bottom_radius = 0.22
			cm.height = 0.55
			b.mesh = cm
			b.material_override = iron
			b.position = Vector3(x, QUAY_Y + 0.275, z)
			add_child(b)
		z += 9.0
	# the wooden end of the pier, on posts
	WB.box(self, Vector3(214, DECK_Y - 0.12, 90), Vector3(228, DECK_Y, 108), m_deck)
	var post := WB.mat("dark_wood", 1.0, Color(0.3, 0.25, 0.2))
	for px in [214.3, 221.0, 227.7]:
		for pz in [91.0, 96.0, 101.0, 106.0, 107.7]:
			WB.box(self, Vector3(px - 0.15, -4.0, pz - 0.15), Vector3(px + 0.15, DECK_Y - 0.12, pz + 0.15), post, false)
	# railing on the wooden end, broken on the east side by the steps
	var rw := WB.mat("weathered_planks", 1.0, Color(0.55, 0.5, 0.42))
	for seg in [[Vector3(214, 0, 90), Vector3(214, 0, 108)], [Vector3(214, 0, 108), Vector3(228, 0, 108)], [Vector3(228, 0, 90), Vector3(228, 0, 99.0)], [Vector3(228, 0, 104.5), Vector3(228, 0, 108)]]:
		var a: Vector3 = seg[0]
		var bb: Vector3 = seg[1]
		var lo := Vector3(minf(a.x, bb.x) - 0.04, DECK_Y + 0.95, minf(a.z, bb.z) - 0.04)
		var hi := Vector3(maxf(a.x, bb.x) + 0.04, DECK_Y + 1.02, maxf(a.z, bb.z) + 0.04)
		WB.box(self, lo, hi, rw, false)
		var n := int(a.distance_to(bb) / 1.5)
		for k in n + 1:
			var p := a.lerp(bb, float(k) / maxf(1, n))
			WB.box(self, Vector3(p.x - 0.05, DECK_Y, p.z - 0.05), Vector3(p.x + 0.05, DECK_Y + 1.0, p.z + 0.05), rw, false)
	# a piece of railing hanging, broken
	var broken := WB.box(self, Vector3(-0.04, -0.5, -0.04), Vector3(0.04, 0.5, 0.04), rw, false)
	broken.position = Vector3(228.1, DECK_Y + 0.3, 100.2)
	broken.rotation_degrees = Vector3(35, 0, 20)
	# the steps down to the water (where she fell)
	for k in 9:
		var y := DECK_Y - 0.2 - k * 0.24
		WB.box(self, Vector3(228.0 + k * 0.0, y - 0.2, 99.3), Vector3(229.6, y, 104.2), m_stone)
	WB.box(self, Vector3(229.6, -4.0, 99.3), Vector3(230.0, DECK_Y, 104.2), m_stone)
	hotspots.escadas = Hotspot.add(self, Vector3(228.8, DECK_Y - 0.4, 101.7), Vector3(1.6, 1.0, 4.9), _prompt("escadas"), func(p): _say("escadas", p))
	# lamps on the quay; the one at the end is dying
	for lz in [30.0, 46.0, 62.0, 78.0]:
		_lamp(216.7, lz, 90.0, lz == 84.0, QUAY_Y)
	broken_lamp = _lamp(227.3, 106.8, -90.0, true, DECK_Y)
	# fishing life
	WB.model(self, "lifebuoy", 225.9, 45.0, -90.0, 1.0, QUAY_Y + 1.0, false)
	WB.box(self, Vector3(225.85, QUAY_Y, 44.95), Vector3(225.95, QUAY_Y + 1.5, 45.05), WB.flat(Color(0.3, 0.3, 0.3), 0.5, 0.6))
	WB.model(self, "wooden_barrels_01", 220.5, 70.0, 20.0, 0.6, QUAY_Y)
	for k in 6:
		WB.model(self, "plastic_crate_01" if k % 2 == 0 else "wooden_crate_01", 223.5 + rng.randf_range(-0.6, 0.6), 55.0 + k * 0.5, rng.randf_range(0, 360), 1.0, QUAY_Y, false)
	WB.model(self, "metal_jerrycan", 222.5, 53.0, 30.0, 1.0, QUAY_Y)
	WB.model(self, "rubber_boots", 219.0, 76.0, 60.0, 1.0, QUAY_Y, false)
	WB.model(self, "wooden_bucket_01", 218.5, 76.4, 0.0, 1.0, QUAY_Y, false)
	WB.model(self, "Lantern_01", 214.6, 107.5, 0.0, 1.5, DECK_Y, false)
	WB.model(self, "old_tyre", 225.9, 64.0, 90.0, 1.0, QUAY_Y - 0.2, false)
	# the faded flowers tied to a post (January — IMG_1433)
	var post2 := WB.box(self, Vector3(227.5, DECK_Y, 98.8), Vector3(227.7, DECK_Y + 1.2, 99.0), post, false)
	for k in 5:
		var fl := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.05
		fl.mesh = sm
		fl.material_override = WB.flat(Color(0.55, 0.35, 0.3).lerp(Color(0.5, 0.48, 0.42), rng.randf()), 0.9)
		fl.position = Vector3(227.6 + rng.randf_range(-0.08, 0.08), DECK_Y + 0.95 + rng.randf_range(-0.1, 0.1), 98.75)
		add_child(fl)
	hotspots.flores = Hotspot.add(self, Vector3(227.6, DECK_Y + 1.0, 98.85), Vector3(0.3, 0.4, 0.3), _prompt("flores"), func(p): _say("flores", p))
	# boats: moored on the west side, two pulled up on the sand
	var paints := [[Color(0.1, 0.3, 0.6), Color(0.85, 0.85, 0.8), Color(0.55, 0.12, 0.1)],
		[Color(0.1, 0.45, 0.3), Color(0.9, 0.8, 0.2), Color(0.12, 0.2, 0.4)],
		[Color(0.7, 0.2, 0.15), Color(0.85, 0.85, 0.8), Color(0.15, 0.3, 0.55)]]
	for k in 3:
		var bt := Sea.boat(self, Vector3(212.4, SEA_Y + 0.72, 36.0 + k * 15.0), 0.0, 6.0, paints[k], rng)
		bt.set_meta("bob", rng.randf() * TAU)
		bt.add_to_group("rocking_boats")
	Sea.boat(self, Vector3(194.0, -0.25, 27.0), 70.0, 5.0, paints[1], rng).rotation_degrees.z = 8.0
	Sea.boat(self, Vector3(242.0, -0.25, 26.0), -60.0, 5.5, paints[2], rng).rotation_degrees.z = -6.0
	# out at sea: a buoy and the lateral marker blinking red
	WB.model(self, "ocean_buoy", 236.0, 118.0, 0.0, 1.0, SEA_Y - 0.6, false)
	var marker := WB.model(self, "lateral_sea_marker", 262.0, 170.0, 0.0, 1.0, SEA_Y - 1.0, false)
	marker_light = WB.emissive(Color(1.0, 0.15, 0.1), 0.0)
	var ml := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.25
	mm.height = 0.4
	ml.mesh = mm
	ml.material_override = marker_light
	ml.position = Vector3(262.0, WB.footprint(marker).end.y + 0.2, 170.0)
	add_child(ml)


func _build_sea() -> void:
	Sea.water(self, Vector3(230, SEA_Y, 190), 520.0)
	# a dark sea floor so shallow water is not bottomless
	WB.box(self, Vector3(-40, -9.0, 22), Vector3(480, -8.0, 450), WB.flat(Color(0.05, 0.06, 0.06), 1.0), false)


## Invisible walls: the fields, the sea, the ends of the streets.
func _build_bounds() -> void:
	var walls := [
		[Vector3(-30, -1, -6.2), Vector3(60, 4, -6.0)],      # house fronts (north)
		[Vector3(-30, -1, 6.0), Vector3(60, 4, 6.2)],        # house fronts (south)
		[Vector3(-31, -1, -6.2), Vector3(-30, 4, 6.2)],      # far end of the street
		[Vector3(60, -1, -46), Vector3(200, 4, -45)],
		[Vector3(60, -1, 4.6), Vector3(108, 4, 5.4)],        # fields south of the road (walls)
		[Vector3(108, -1, 22.0), Vector3(150, 4, 23.0)],
		[Vector3(150, -1, 22), Vector3(151, 4, 34)],
		[Vector3(150, -1, 33.5), Vector3(216, 4, 34.5)],     # the water's edge (west beach)
		[Vector3(226, -1, 33.5), Vector3(300, 4, 34.5)],     # the water's edge (east beach)
		[Vector3(300, -1, 20), Vector3(301, 4, 35)],
		[Vector3(248, -1, -27), Vector3(249, 4, 20)],
		[Vector3(199, -1, -27), Vector3(248, 4, -26)],
		[Vector3(215.6, -2, 34.5), Vector3(216, 4, 90)],     # quay edges
		[Vector3(226, -2, 34.5), Vector3(226.4, 4, 90)],
		[Vector3(213.6, -2, 90), Vector3(214, 4, 108.4)],
		[Vector3(213.6, -2, 108), Vector3(228.4, 4, 108.4)],
		[Vector3(228, -2, 90), Vector3(228.4, 4, 99.2)],
		[Vector3(228, -2, 104.3), Vector3(228.4, 4, 108.4)],
		[Vector3(229.6, -4, 99.2), Vector3(230.0, 4, 104.3)],  # the bottom of the steps
		[Vector3(228.0, -4, 98.9), Vector3(229.6, 4, 99.3)],
		[Vector3(228.0, -4, 104.2), Vector3(229.6, 4, 104.6)],
	]
	for w in walls:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		var a: Vector3 = w[0]
		var b: Vector3 = w[1]
		sh.size = (b - a).abs()
		cs.shape = sh
		cs.position = (a + b) / 2
		sb.add_child(cs)
		sb.set_meta("bound", true)
		add_child(sb)


# =================================================================== story
func _build_story_hooks() -> void:
	spawns = {
		"casa": [Vector3(7.0, 0.12, -4.6), -90.0],
		"en125": [Vector3(62.0, 0.02, 1.5), -90.0],
		"bombas": [Vector3(122.0, 0.05, -7.0), 0.0],
		"largo": [Vector3(204.0, 0.1, 0.0), -90.0],
		"cais": [Vector3(221.0, QUAY_Y + 0.05, 24.0), 180.0],
		"fim": [Vector3(221.0, DECK_Y + 0.05, 99.0), 180.0],
	}
	spots = {
		"front_door": Vector3(221.0, 1.2, 60.0), "street": Vector3(205.0, 1.0, 0.0),
		"corridor": Vector3(221.0, 1.4, 80.0), "landing": Vector3(221.0, 1.2, 40.0),
		"kitchen": Vector3(237.0, 1.5, -24.0), "wc": Vector3(229.0, -0.6, 101.7), "window": Vector3(212.0, -1.0, 50.0),
	}
	add_hide("barcos", Vector3(194.0, -0.4, 27.0), Vector3(2.2, 1.0, 4.6), "Esconder atrás do barco",
		[Vector3(195.6, -0.3, 25.6), -30.0, 0.0], [Vector3(196.5, -1.15, 25.0), -60.0])
	add_hide("bombas", Vector3(142.6, 0.8, -26.5), Vector3(0.8, 1.6, 2.0), "Esconder atrás da loja",
		[Vector3(143.3, 1.4, -26.0), 160.0, 0.0], [Vector3(142.6, 0.05, -22.5), 180.0])
	add_hide("barris", Vector3(220.5, QUAY_Y + 0.5, 70.0), Vector3(2.6, 1.0, 2.0), "Esconder atrás dos barris",
		[Vector3(219.2, QUAY_Y + 0.6, 71.8), 180.0, 0.0], [Vector3(219.0, QUAY_Y + 0.05, 73.0), 0.0])
	# what can change: the dying lamp, a boat's rope, lights in windows
	add_change("candeeiro_cais", broken_lamp.position, func(): broken_lamp.visible = not broken_lamp.visible, "click_far", -14.0)
	for k in 3:
		add_change("janela_%d" % k, Vector3(rng.randf_range(-20, 50), 4.0, -6.2), func():
			if not lit_windows.is_empty():
				var m: StandardMaterial3D = lit_windows[randi() % lit_windows.size()]
				m.emission_energy_multiplier = 0.0 if m.emission_energy_multiplier > 0.0 else float(m.get_meta("energy")), "click_far", -24.0)


## An overcast night over a small town: the clouds glow a little orange.
func tweak_env(e: Environment) -> void:
	e.background_color = Color(0.03, 0.028, 0.03)
	e.ambient_light_color = Color(0.55, 0.47, 0.42)
	e.ambient_light_energy = 0.14
	e.volumetric_fog_density = 0.008
	e.volumetric_fog_albedo = Color(0.8, 0.78, 0.76)
	e.ssr_enabled = Settings.get_value("graphics", "alta") == "alta"
	e.ssr_max_steps = 48


func floor_kind(p: Vector3) -> String:
	if p.z > 90.0 and p.x > 213.0 and p.x < 229.0:
		return "wood"
	return "tile"


func _process(delta: float) -> void:
	_t += delta
	for b in get_tree().get_nodes_in_group("rocking_boats"):
		var ph: float = b.get_meta("bob")
		(b as Node3D).position.y = SEA_Y + 0.72 + sin(_t * 0.9 + ph) * 0.12
		(b as Node3D).rotation_degrees.z = sin(_t * 0.7 + ph) * 3.0
	if marker_light:
		marker_light.emission_energy_multiplier = 6.0 if fmod(_t, 4.0) < 0.6 else 0.0
	_broken_t -= delta
	if _broken_t <= 0.0 and broken_lamp and street_lights[0].visible:
		_broken_t = randf_range(0.05, 0.9)
		broken_lamp.visible = randf() < 0.6
		(broken_lamp.get_meta("glow") as StandardMaterial3D).emission_energy_multiplier = 4.0 if broken_lamp.visible else 0.3


## Rain on Daniel (follow the player node the world gives us).
func set_rain(on: bool, player: Node3D) -> void:
	raining = on
	if on and rain_fx == null and player:
		rain_fx = Sea.rain(player)
	if rain_fx:
		rain_fx.emitting = on
		rain_fx.visible = on


func set_daylight(d: float) -> void:
	var night := d < 0.35
	for l in street_lights:
		l.visible = night
		if l.has_meta("fill"):
			(l.get_meta("fill") as Light3D).visible = night
		if l.has_meta("glow"):
			(l.get_meta("glow") as StandardMaterial3D).emission_energy_multiplier = 4.0 if night else 0.0
	for m in lit_windows:
		m.emission_energy_multiplier = float(m.get_meta("energy")) * (1.0 - d)
	moon.visible = d < 0.5
