class_name Location
extends Node3D
## A place Daniel (or Sofia) can be in: built in code, with rooms whose lights
## the story and the player switch, doors, things to examine (texts from
## data/world/<id>.json), named spots for sounds, places to spawn and to
## hide, and a navigation mesh for whatever walks there that isn't him.

signal peephole_requested
signal hide_requested(spot: Dictionary)

const WARM := Color(1.0, 0.78, 0.55)

var loc_id := ""
var rooms := {}              # id -> {lights, glow, on, energy}
var room_bounds := {}        # id -> AABB (which room a point is in)
var power := true
var doors := {}
var hotspots := {}
var spots := {}              # named places for sounds
var spawns := {}             # name -> [Vector3, yaw_deg]
var hides: Array = []        # HideSpot nodes
var changeables: Array = []  # Callables(): changes one thing, returns its position or null
var texts := {}
var peep: Array = []         # [cam position, yaw] when the place has a peephole
var outdoor := false
var aliases: Array = []      # other story ids that are this same place ("cais" → the road)
var nav_cell := 0.08         # navigation mesh resolution (outdoors can be coarser)
var nav: NavigationRegion3D
var lamps: Array = []        # lights outside any room (street lamps) that count as light
var zones := {}              # id -> AABB: walking into one sets w_zone_<id> for the story
var _uses := {}
var _probes: Array[ReflectionProbe] = []

var m_wall: Material
var m_ceiling: Material
var m_paint: Material
var m_skirt: Material


func load_texts(id: String) -> void:
	loc_id = id
	var path := "res://data/world/%s.json" % id
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		texts = parsed if parsed is Dictionary else {}


## Called by GameWorld after the place is built.
func bake_navigation() -> void:
	nav = NavigationRegion3D.new()
	add_child(nav)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.16   # it is thin: 0.7 m doors with frames must stay open
	nm.agent_height = 1.7
	nm.agent_max_climb = 0.2
	nm.cell_size = nav_cell
	nm.cell_height = 0.05
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	# doors are not walls: what walks here opens them (with a sound).
	# Locked ones are (the front door at night).
	var leaves := {}
	for d in doors.values():
		if d is Door and not d.locked:
			leaves[d.leaf] = d.leaf.collision_layer
			d.leaf.collision_layer = 1 << (Hotspot.LAYER - 1)
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, self)
	for leaf in leaves:
		leaf.collision_layer = leaves[leaf]
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, nm.cell_size)
	NavigationServer3D.map_set_cell_height(map, nm.cell_height)
	nav.navigation_mesh = nm


## Which room a point is in ("" outside every room).
func room_at(p: Vector3) -> String:
	for id in room_bounds:
		if (room_bounds[id] as AABB).has_point(p):
			return id
	return ""


## Is this point lit (a light on nearby, or daylight inside)? 0..1
func light_at(p: Vector3, daylight := 0.0) -> float:
	var best := daylight * (1.0 if outdoor else 0.6)
	for id in rooms:
		var r: Dictionary = rooms[id]
		if not (r.on and power):
			continue
		for l in r.lights:
			var lt := l as Light3D
			var rng: float = lt.omni_range if lt is OmniLight3D else (lt as SpotLight3D).spot_range
			var d := lt.global_position.distance_to(p)
			if d < rng * 0.75:
				best = maxf(best, 1.0 - d / (rng * 0.75))
	for l in lamps:
		var lt := l as Light3D
		if not lt.visible:
			continue
		var rng2: float = lt.omni_range if lt is OmniLight3D else (lt as SpotLight3D).spot_range
		var d2 := lt.global_position.distance_to(p)
		if d2 < rng2 * 0.6:
			best = maxf(best, 1.0 - d2 / (rng2 * 0.6))
	return best


## Turn the lights of the room around a point off (the thing does this).
func kill_light_at(p: Vector3) -> String:
	var id := room_at(p)
	if id != "" and rooms.has(id) and rooms[id].on:
		flicker(id, 1.2)
		await get_tree().create_timer(1.25).timeout
		set_room_light(id, false)
		return id
	return ""


## A place to hide: aim at it and press E. The view from inside is `cam`
## (position, yaw, pitch); leaving puts Daniel back at `exit`.
func add_hide(id: String, center: Vector3, size: Vector3, prompt: String, cam: Array, exit: Array) -> Hotspot:
	var spot := {"id": id, "cam_pos": cam[0], "cam_yaw": cam[1], "cam_pitch": cam[2] if cam.size() > 2 else 0.0,
		"exit_pos": exit[0], "exit_yaw": exit[1], "center": center}
	var h := Hotspot.add(self, center, size, prompt, func(_p): hide_requested.emit(spot))
	spot.hotspot = h
	hides.append(spot)
	return h


## Something that can change by itself when nobody is looking (R10). `apply`
## makes the change; the sound plays where it happened (R11).
func add_change(id: String, pos: Vector3, apply: Callable, sound := "door", volume := -20.0) -> void:
	changeables.append({"id": id, "pos": pos, "apply": apply, "sound": sound, "volume": volume})


func floor_kind(_p: Vector3) -> String:
	return "wood"


func set_daylight(_d: float) -> void:
	pass


# =================================================================== lights
func _room(id: String, lights: Array, glow: Array) -> void:
	if not rooms.has(id):
		rooms[id] = {"lights": [], "glow": [], "on": false, "energy": []}
	for l in lights:
		rooms[id].lights.append(l)
		rooms[id].energy.append(l.light_energy)
		l.visible = false
	for g in glow:
		rooms[id].glow.append(g)
		g.emission_energy_multiplier = 0.0


func _bulb(id: String, ceiling: Vector3, drop: float, energy: float, rng: float) -> void:
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.004
	cm.bottom_radius = 0.004
	cm.height = drop
	cord.mesh = cm
	cord.material_override = WB.flat(Color(0.05, 0.05, 0.05), 0.6)
	cord.position = ceiling - Vector3(0, drop / 2, 0)
	cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cord)
	var socket := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.016
	sc.bottom_radius = 0.016
	sc.height = 0.05
	socket.mesh = sc
	socket.material_override = WB.flat(Color(0.08, 0.08, 0.08), 0.5)
	socket.position = ceiling - Vector3(0, drop + 0.02, 0)
	socket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(socket)
	var glow := WB.emissive(WARM, 0.0)
	glow.albedo_color = Color(0.9, 0.85, 0.75)
	var g := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.032
	sm.height = 0.075
	g.mesh = sm
	g.material_override = glow
	g.position = ceiling - Vector3(0, drop + 0.075, 0)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	var l := WB.omni(self, ceiling - Vector3(0, drop + 0.12, 0), WARM, energy, rng, true)
	_room(id, [l], [glow])


func _plafond(id: String, ceiling: Vector3, energy := 1.2) -> OmniLight3D:
	var glow := WB.emissive(Color(1.0, 0.92, 0.8), 0.0)
	glow.albedo_color = Color(0.85, 0.85, 0.82)
	var g := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.1
	g.mesh = sm
	g.material_override = glow
	g.position = ceiling - Vector3(0, 0.03, 0)
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(g)
	var l := WB.omni(self, ceiling - Vector3(0, 0.25, 0), Color(1.0, 0.86, 0.68), energy, 6.0, true)
	_room(id, [l], [glow])
	return l


func _switch(id: String, at: Vector3, rot: float, targets: Array, prompt := "") -> void:
	var plate := Node3D.new()
	plate.position = at
	plate.rotation_degrees.y = rot
	add_child(plate)
	WB.box(plate, Vector3(-0.04, -0.06, -0.008), Vector3(0.04, 0.06, 0.004), WB.flat(Color(0.92, 0.91, 0.88), 0.4), false)
	WB.box(plate, Vector3(-0.015, -0.025, 0.004), Vector3(0.015, 0.025, 0.012), WB.flat(Color(0.95, 0.95, 0.93), 0.35), false)
	var h := Hotspot.add(self, at, Vector3(0.12, 0.16, 0.12), "Interruptor", func(_p):
		Audio.play("switch", -6.0)
		var on: bool = not rooms.get(targets[0], {}).get("on", false)
		for t in targets:
			set_room_light(t, on)
		if on:
			# the story knows he put a light on here (from the street, it shows)
			GameState.set_var("w_lit_" + loc_id, true)
			Director.notify_player_action())
	h.dynamic_prompt = func():
		if prompt != "":
			return ("Desligar o candeeiro" if rooms.get(targets[0], {}).get("on", false) else prompt)
		return "Apagar a luz" if rooms.get(targets[0], {}).get("on", false) else "Acender a luz"


func set_room_light(id: String, on: bool) -> void:
	if not rooms.has(id):
		return
	var r: Dictionary = rooms[id]
	r.on = on
	_apply_room(id)


func _apply_room(id: String) -> void:
	_refresh_probes.call_deferred()
	var r: Dictionary = rooms[id]
	var lit: bool = r.on and power
	for i in r.lights.size():
		r.lights[i].visible = lit
		r.lights[i].light_energy = r.energy[i]
	for g in r.glow:
		g.emission_energy_multiplier = 6.0 if lit else 0.0


## Mirrors are baked once; light changes re-bake them.
func _refresh_probes() -> void:
	for p in _probes:
		p.max_distance = 0.0 if p.max_distance != 0.0 else 0.001


## Locations add what else dies with the power (a TV, a laptop screen).
func _on_power(_on: bool) -> void:
	pass


func set_power(on: bool) -> void:
	power = on
	Audio.play("switch", -2.0, 0.7)
	if not on:
		Audio.play("sub", -16.0)
	for id in rooms:
		_apply_room(id)
	_on_power(on)


## A room's lights stutter for `secs` (and may come back dimmer).
func flicker(id: String, secs := 1.5) -> void:
	if not rooms.has(id):
		return
	var r: Dictionary = rooms[id]
	var t := 0.0
	while t < secs:
		var dt := randf_range(0.04, 0.16)
		var on := randf() < 0.45
		for l in r.lights:
			l.visible = on and r.on and power
		for g in r.glow:
			g.emission_energy_multiplier = 3.0 if (on and r.on and power) else 0.0
		await get_tree().create_timer(dt).timeout
		t += dt
	_apply_room(id)


# =================================================================== texts
func _prompt(id: String) -> String:
	return str(texts.get(id, {}).get("prompt", "Examinar"))


func _first_text(id: String) -> String:
	var l: Array = texts.get(id, {}).get("text", [])
	return str(l[0]) if not l.is_empty() else ""


## Daniel says what he thinks of it; marks "w_<id>" for the story.
func _say(id: String, player: Node) -> void:
	var d: Dictionary = texts.get(id, {})
	var line := ""
	for w in d.get("when", []):
		if Director.check(str(w.get("if", "false"))):
			line = str(w.get("text", ""))
			if w.has("set"):
				GameState.set_var(str(w.set), true)
			break
	if line == "":
		var l: Array = d.get("text", [])
		if not l.is_empty():
			var n: int = _uses.get(id, 0)
			line = str(l[mini(n, l.size() - 1)])
			_uses[id] = n + 1
	GameState.set_var("w_" + id, true)
	Director.notify_player_action()
	if line != "" and player and player.has_method("think"):
		player.think(line)
