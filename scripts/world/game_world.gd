class_name GameWorld
extends Node3D
## The 3D side of the game: Daniel's flat at night, him in it, and the night
## outside. The phone (in his hand, or in the player's) tells the story; the
## house is where it happens.

signal peep_changed(peeping: bool)

## Places that exist in 3D. A story location without one here is played on
## the phone only (the house waits in the dark).
const LOCATIONS := {
	"casa": "res://scripts/world/house.gd",
	"livraria": "res://scripts/world/bookshop.gd",
	"rui": "res://scripts/world/rui_house.gd",
	"clinica": "res://scripts/world/clinic.gd",
	"caminho": "res://scripts/world/road.gd",
	"cais": "res://scripts/world/road.gd",
}

signal location_changed(id: String)
signal hidden_changed(spot: Dictionary)

var location: Location
var house: Location:
	get:
		return location
var hiding: Dictionary = {}
var _hide_cam: Camera3D
var _hide_mask: ColorRect
var _hour := 21.5
var _base_env := {"bg": Color(0.008, 0.01, 0.018), "amb": 0.045, "fog": 0.012}
var player: Player
var hud: WorldHud
var env: WorldEnvironment
var active := false
var peeping := false
var _peep_cam: Camera3D
var _peep_mask: Control
var _saved_cam: Camera3D
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var daylight := 0.0
var presence: Presence
var dying := false
var _zone_t := 0.0
var _figures: Array = []


func _ready() -> void:
	env = WorldEnvironment.new()
	env.environment = _night_environment()
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -150, 0)   # from the south-east, over the roofs
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	sun.light_volumetric_fog_energy = 0.4
	sun.visible = false
	add_child(sun)
	player = Player.new()
	add_child(player)
	hud = WorldHud.new()
	player.thought.connect(func(t): hud.show_thought(t))
	_build_peephole()
	_build_hiding()
	presence = Presence.new()
	add_child(presence)
	presence.setup(self)
	go_to("casa", "sofa")
	Events.world_cue.connect(_on_cue)
	# where he walked is remembered per chapter (the quay of the prologue is not tonight's)
	Events.chapter_started.connect(func(_ch):
		for k in GameState.data.flags.keys():
			if str(k).begins_with("w_zone_"):
				GameState.data.flags.erase(k))
	Events.settings_changed.connect(_apply_quality)
	_apply_quality()
	set_active(false)


func _night_environment() -> Environment:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.008, 0.01, 0.018)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.32, 0.36, 0.48)
	e.ambient_light_energy = 0.045
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 1.2
	e.ssao_intensity = 2.4
	e.ssao_power = 1.6
	e.ssil_enabled = true
	e.ssil_intensity = 0.9
	e.ssr_enabled = false
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.04
	e.glow_hdr_threshold = 1.1
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.012
	e.volumetric_fog_albedo = Color(0.85, 0.85, 0.9)
	e.volumetric_fog_emission = Color(0, 0, 0)
	e.volumetric_fog_gi_inject = 0.4
	e.volumetric_fog_length = 40.0
	e.volumetric_fog_detail_spread = 2.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.82
	e.adjustment_contrast = 1.06
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.52, 0.6, 0.7)
	sky_mat.sky_horizon_color = Color(0.78, 0.8, 0.82)
	sky_mat.ground_horizon_color = Color(0.6, 0.6, 0.6)
	sky_mat.ground_bottom_color = Color(0.3, 0.3, 0.3)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.sky = sky
	return e


## Light for the time of day (in-game hour, 0..24). Porto in October: sunrise
## about 07:40, sunset about 19:05, often overcast.
func set_hour(h: float) -> void:
	var d := 0.0
	if h >= 7.2 and h <= 19.4:
		d = clampf(minf(h - 7.2, 19.4 - h) / 1.2, 0.0, 1.0)
	daylight = d
	var e := env.environment
	if d > 0.02:
		e.background_mode = Environment.BG_SKY
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = lerpf(_base_env.amb, 0.9, d)
		e.background_energy_multiplier = lerpf(0.05, 1.0, d)
		e.tonemap_exposure = lerpf(1.05, 0.9, d)
		e.volumetric_fog_density = lerpf(_base_env.fog, 0.004, d)
	else:
		e.background_mode = Environment.BG_COLOR
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_energy = _base_env.amb
		e.tonemap_exposure = 1.05
		e.volumetric_fog_density = _base_env.fog
	sun.visible = d > 0.02
	sun.light_energy = lerpf(0.0, 1.6, d)
	# low warm sun near the edges of the day
	sun.light_color = Color(1.0, 0.95, 0.86).lerp(Color(1.0, 0.62, 0.38), 1.0 - d)
	sun.rotation_degrees.x = lerpf(-6.0, -34.0, d)
	_hour = h
	if location:
		location.set_daylight(d)


## Graphics quality (Definições → Qualidade gráfica).
func _apply_quality() -> void:
	var q: String = Settings.get_value("graphics", "alta")
	var e := env.environment
	e.ssil_enabled = q == "alta"
	e.ssao_enabled = q != "baixa"
	e.volumetric_fog_enabled = q != "baixa"
	e.glow_enabled = q != "baixa"
	var vp := get_viewport()
	if vp:
		vp.positional_shadow_atlas_size = 4096 if q == "alta" else (2048 if q == "media" else 1024)
		vp.msaa_3d = Viewport.MSAA_2X if q == "alta" else Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q != "alta" else Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if q == "alta" else RenderingServer.SHADOW_QUALITY_HARD)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if q == "alta" else RenderingServer.SHADOW_QUALITY_HARD)
	# on low, only the lights that matter most keep their shadows
	if house:
		for l in house.find_children("*", "Light3D", true, false):
			if not l.has_meta("shadow"):
				l.set_meta("shadow", (l as Light3D).shadow_enabled)
			(l as Light3D).shadow_enabled = l.get_meta("shadow") and (q != "baixa" or l is SpotLight3D)


## Build (or keep) a place and put Daniel in it. Returns false when the
## place has no 3D version.
func go_to(id: String, where := "", fresh := false) -> bool:
	if not LOCATIONS.has(id):
		return false
	if where == "" and id != "" and location and location.spawns.has(id):
		where = id
	if location and not fresh and (location.loc_id == id or location.aliases.has(id)):
		if where == "" and location.spawns.has(id):
			where = id
		if where != "":
			spawn(where)
		return true
	if not hiding.is_empty():
		unhide()
	if peeping:
		peek(false)
	if location:
		remove_child(location)
		location.free()
	location = load(LOCATIONS[id]).new()
	add_child(location)
	if location.loc_id == "":
		location.loc_id = id
	location.peephole_requested.connect(func(): peek(true))
	location.hide_requested.connect(hide_in)
	player.floor_kind = location.floor_kind
	env.environment = _night_environment()
	if location.has_method("tweak_env"):
		location.tweak_env(env.environment)
	_base_env = {"bg": env.environment.background_color, "amb": env.environment.ambient_light_energy, "fog": env.environment.volumetric_fog_density}
	_apply_quality()
	set_hour(_hour)
	if where == "" and location.spawns.has(id):
		where = id
	spawn(where)
	if location.has_method("set_rain"):
		location.set_rain(daylight < 0.35, player)
	presence.bind(location)
	location_changed.emit(id)
	return true


## Where Daniel stands at the start of a scene (a spawn of the place).
func spawn(where: String) -> void:
	var sp: Array = location.spawns.get(where, [])
	if sp.is_empty() and not location.spawns.is_empty():
		sp = location.spawns.values()[0]
	if sp.is_empty():
		return
	player.global_position = sp[0]
	player.set_view(sp[1], sp[2] if sp.size() > 2 else -6.0)
	player.velocity = Vector3.ZERO


func set_active(on: bool) -> void:
	active = on
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	player.cam.current = on and not peeping
	if hud.get_parent():
		hud.visible = on
	Audio.spatial = _spatial_sound if on else Callable()
	if not on and peeping:
		peek(false)


## Controls the HUD lives in (a CanvasItem parent provided by Main).
func attach_hud(parent: Control) -> void:
	parent.add_child(hud)
	parent.add_child(_peep_mask)
	_hide_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(_hide_mask)
	hud.visible = active


# ------------------------------------------------------------ sounds in the room
const _AT := {
	"knock": "front_door", "knock_one": "front_door", "lock": "front_door",
	"door": "front_door", "footsteps": "landing", "creak": "corridor",
	"drop": "kitchen", "click_far": "street", "water": "wc",
}


func _spatial_sound(sound_name: String, volume_db: float, pitch: float) -> bool:
	if not active or not GameState.in_game:
		return false
	var pos: Vector3
	if sound_name in ["breath", "whisper"]:
		# right behind him
		pos = player.global_position + player.global_transform.basis.z * 0.7 + Vector3(0, 1.6, 0)
	elif _AT.has(sound_name) and location.spots.has(_AT[sound_name]):
		pos = location.spots[_AT[sound_name]]
	else:
		return false
	play_at(sound_name, pos, volume_db, pitch)
	if sound_name in ["knock", "knock_one"]:
		player.shake(0.4)
	if sound_name == "footsteps" and location.has_method("landing_on"):
		location.landing_on(25.0)
	return true


func play_at(sound_name: String, pos: Vector3, volume_db := 0.0, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = Audio.stream(sound_name)
	p.bus = "Voice" if sound_name in ["breath", "whisper", "voice", "voice_low"] else "SFX"
	if Audio.is_sudden(sound_name) and Settings.get_value("soften_sudden", false):
		volume_db -= 14.0
	p.volume_db = volume_db + 4.0
	p.pitch_scale = pitch
	p.unit_size = 4.0
	p.max_distance = 30.0
	p.attenuation_filter_cutoff_hz = 6000.0
	p.position = pos
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


# ------------------------------------------------------------ story cues
## "world <cmd> [args]" in the .story files.
func _on_cue(cmd: String, args: Array) -> void:
	match cmd:
		"lights":
			var on: bool = args.size() > 0 and args[0] == "on"
			var ids: Array = [args[1]] if args.size() > 1 else house.rooms.keys()
			for id in ids:
				house.set_room_light(id, on)
		"flicker":
			var ids2: Array = [args[0]] if args.size() > 0 and args[0] != "all" else house.rooms.keys()
			for id in ids2:
				house.flicker(id, float(args[1]) if args.size() > 1 else 1.5)
		"power":
			house.set_power(args.size() > 0 and args[0] == "on")
		"tv":
			if house.has_method("set_tv"):
				house.set_tv(args.size() > 0 and args[0] == "on")
		"door":
			# door <id> open|close|lock|unlock
			var d: Door = house.doors.get(args[0])
			if d:
				match args[1] if args.size() > 1 else "open":
					"open": d.set_open(true)
					"close": d.set_open(false)
					"slam": d.set_open(false, false, 3.0)
					"lock": d.locked = true
					"unlock": d.locked = false
		"landing":
			if house.has_method("landing_on"):
				house.landing_on(float(args[0]) if args.size() > 0 else 30.0)
		"spawn":
			spawn(args[0])
		"goto":
			go_to(args[0], args[1] if args.size() > 1 else "")
		"rain":
			if location.has_method("set_rain"):
				location.set_rain(args.size() == 0 or args[0] == "on", player)
		"think":
			player.think(" ".join(PackedStringArray(args)))
		"say":
			# say Dra. Helena «Sente-se.» — someone in the room speaks (subtitle)
			var all := " ".join(PackedStringArray(args))
			var cut := all.find("«")
			var who := all.substr(0, cut).strip_edges() if cut > 0 else ""
			hud.show_speech(who, all.substr(cut) if cut >= 0 else all)
		"shake":
			player.shake(float(args[0]) if args.size() > 0 else 0.5)
		"presence":
			presence.story_cmd(args)
		"figure":
			# figure x z [red|dark] — someone standing far off, gone when he gets close
			_figures.append(presence.figure(Vector3(float(args[0]), 0.0, float(args[1])), args[2] if args.size() > 2 else "dark"))
		"prints":
			# prints x z yaw n — wet footprints walking off towards yaw
			presence.trail(Vector3(float(args[0]), 0.0, float(args[1])), deg_to_rad(float(args[2])), int(args[3]) if args.size() > 3 else 6)


func _process(delta: float) -> void:
	if not active or location == null:
		return
	_zone_t -= delta
	if _zone_t <= 0.0 and not location.zones.is_empty():
		_zone_t = 0.4
		var pp := player.global_position
		for id in location.zones:
			if (location.zones[id] as AABB).has_point(pp) and not GameState.flag("w_zone_" + id):
				GameState.set_var("w_zone_" + id, true)
				Director.notify_player_action()
	for f in _figures.duplicate():
		if not is_instance_valid(f):
			_figures.erase(f)
		elif presence.figure_check(f, delta):
			_figures.erase(f)


# ------------------------------------------------------------ caught
## It reached him: he turns, it is there (still not clear), then nothing.
## Main fades to black and starts the chapter again.
func death_glimpse(at: Vector3) -> void:
	dying = true
	if not hiding.is_empty():
		unhide()
	if peeping:
		peek(false)
	player.move_enabled = false
	player.look_enabled = false
	var to := at - player.global_position
	var yaw := rad_to_deg(atan2(-to.x, -to.z))
	var tw := create_tween()
	tw.tween_method(func(t: float): player.set_view(lerp_angle(deg_to_rad(player.yaw_deg()), deg_to_rad(yaw), t) * 180.0 / PI, lerpf(player.head.rotation_degrees.x, 4.0, t)), 0.0, 1.0, 0.22)
	await tw.finished
	presence.glimpse(player.global_position, -player.global_transform.basis.z)
	Audio.play("sub", 0.0, 0.6)
	Audio.play("glitch", -4.0)
	player.shake(1.2)
	await get_tree().create_timer(0.5).timeout


func revive() -> void:
	dying = false
	presence.held = false
	presence.attention = 0.0
	player.look_enabled = true
	player.move_enabled = true


# ------------------------------------------------------------ the peephole
func _build_peephole() -> void:
	_peep_cam = Camera3D.new()
	_peep_cam.fov = 130.0
	_peep_cam.near = 0.02
	add_child(_peep_cam)
	var mask := ColorRect.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 aspect = vec2(1.777, 1.0);
void fragment() {
	vec2 p = (UV - 0.5) * aspect;
	float d = length(p);
	float a = smoothstep(0.33, 0.37, d);
	float ring = smoothstep(0.24, 0.36, d) * 0.6;
	COLOR = vec4(0.0, 0.0, 0.0, max(a, ring));
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	mask.material = sm
	mask.resized.connect(func(): sm.set_shader_parameter("aspect", Vector2(mask.size.x / maxf(1.0, mask.size.y), 1.0)))
	_peep_mask = mask
	_peep_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_peep_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_peep_mask.visible = false


func peek(on: bool) -> void:
	if on == peeping:
		return
	peeping = on
	if on:
		_peep_cam.global_position = location.peep[0]
		_peep_cam.rotation_degrees = Vector3(0, location.peep[1], 0)
		_peep_cam.current = true
		player.look_enabled = false
		player.move_enabled = false
		var lines: Array = house.texts.get("peephole", {}).get("text", [])
		if not lines.is_empty():
			hud.show_thought(str(lines[mini(int(GameState.get_var("w_peephole_n", 0)), lines.size() - 1)]))
		GameState.inc_var("w_peephole_n")
		GameState.set_var("w_peephole", true)
		Director.notify_player_action()
	else:
		player.cam.current = active
	_peep_mask.visible = on
	hud.dot.visible = not on
	peep_changed.emit(on)


# ------------------------------------------------------------ hiding
func _build_hiding() -> void:
	_hide_cam = Camera3D.new()
	_hide_cam.fov = 62.0
	_hide_cam.near = 0.02
	add_child(_hide_cam)
	_hide_mask = ColorRect.new()
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float slats = 1.0;
void fragment() {
	vec2 uv = UV;
	float v = smoothstep(0.25, 0.85, length((uv - 0.5) * vec2(1.6, 1.0)));
	float s = slats * step(0.42, fract(uv.y * 14.0)) * (1.0 - smoothstep(0.2, 0.5, abs(uv.x - 0.5)) * 0.15);
	COLOR = vec4(0.0, 0.0, 0.0, clamp(max(v * 0.95, s * 0.92), 0.0, 1.0));
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_hide_mask.material = sm
	_hide_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_mask.visible = false


## Get into a hiding place: the view from inside, only the eyes move.
func hide_in(spot: Dictionary) -> void:
	if not hiding.is_empty():
		return
	hiding = spot
	_hide_cam.global_position = spot.cam_pos
	_hide_cam.rotation_degrees = Vector3(spot.cam_pitch, spot.cam_yaw, 0)
	_hide_cam.current = true
	(_hide_mask.material as ShaderMaterial).set_shader_parameter("slats", 1.0 if spot.id == "roupeiro" else 0.0)
	_hide_mask.visible = true
	player.look_enabled = false
	player.move_enabled = false
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = spot.cam_pos - Vector3(0, 1.5, 0)
	hud.dot.visible = false
	Audio.play("door_close", -16.0, 1.4)
	hud.show_thought("%s  sair" % Settings.key_label("interact", true))
	hidden_changed.emit(spot)


func unhide() -> void:
	if hiding.is_empty():
		return
	var spot := hiding
	hiding = {}
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.visible = true
	player.global_position = spot.exit_pos
	player.set_view(spot.exit_yaw, 0.0)
	player.cam.current = active
	_hide_mask.visible = false
	hud.dot.visible = true
	Audio.play("door_open", -16.0, 1.4)
	hidden_changed.emit({})


func _unhandled_input(event: InputEvent) -> void:
	if not hiding.is_empty() and (event.is_action_pressed("interact") or event.is_action_pressed("move_back")):
		unhide()
		get_viewport().set_input_as_handled()
		return
	if not hiding.is_empty() and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# a little head room while hidden
		var r := _hide_cam.rotation_degrees
		r.y = clampf(r.y - event.relative.x * 0.08, hiding.cam_yaw - 25.0, hiding.cam_yaw + 25.0)
		r.x = clampf(r.x - event.relative.y * 0.08, hiding.cam_pitch - 15.0, hiding.cam_pitch + 15.0)
		_hide_cam.rotation_degrees = r
		return
	if peeping and (event.is_action_pressed("interact") or event.is_action_pressed("move_back") or event.is_action_pressed("phone_back")):
		peek(false)
		get_viewport().set_input_as_handled()
