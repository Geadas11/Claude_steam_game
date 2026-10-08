class_name GameWorld
extends Node3D
## The 3D side of the game: Daniel's flat at night, him in it, and the night
## outside. The phone (in his hand, or in the player's) tells the story; the
## house is where it happens.

signal peep_changed(peeping: bool)

var house: House
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


func _ready() -> void:
	env = WorldEnvironment.new()
	env.environment = _night_environment()
	add_child(env)
	house = House.new()
	add_child(house)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, -150, 0)   # from the south-east, over the roofs
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	sun.light_volumetric_fog_energy = 0.4
	sun.visible = false
	add_child(sun)
	house.peephole_requested.connect(func(): peek(true))
	player = Player.new()
	add_child(player)
	player.floor_kind = house.floor_kind
	spawn("sofa")
	hud = WorldHud.new()
	player.thought.connect(func(t): hud.show_thought(t))
	_build_peephole()
	Events.world_cue.connect(_on_cue)
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
		e.ambient_light_energy = lerpf(0.05, 0.9, d)
		e.background_energy_multiplier = lerpf(0.05, 1.0, d)
		e.tonemap_exposure = lerpf(1.05, 0.9, d)
		e.volumetric_fog_density = lerpf(0.012, 0.004, d)
	else:
		e.background_mode = Environment.BG_COLOR
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_energy = 0.045
		e.tonemap_exposure = 1.05
		e.volumetric_fog_density = 0.012
	sun.visible = d > 0.02
	sun.light_energy = lerpf(0.0, 1.6, d)
	# low warm sun near the edges of the day
	sun.light_color = Color(1.0, 0.95, 0.86).lerp(Color(1.0, 0.62, 0.38), 1.0 - d)
	sun.rotation_degrees.x = lerpf(-6.0, -34.0, d)
	house.set_daylight(d)


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


## Where Daniel stands at the start of a scene.
func spawn(where: String) -> void:
	match where:
		"sofa":
			# beside the coffee table, the sofa and the street windows ahead
			player.global_position = Vector3(3.9, 0.02, 2.6)
			player.set_view(20.0, -8.0)
		"corridor":
			player.global_position = Vector3(8.5, 0.02, 5.15)
			player.set_view(90.0)
		"bed":
			player.global_position = Vector3(8.0, 0.02, 1.8)
			player.set_view(0.0)
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
	elif _AT.has(sound_name):
		pos = house.spots[_AT[sound_name]]
	else:
		return false
	play_at(sound_name, pos, volume_db, pitch)
	if sound_name in ["knock", "knock_one"]:
		player.shake(0.4)
	if sound_name == "footsteps":
		house.landing_on(25.0)
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
			house.landing_on(float(args[0]) if args.size() > 0 else 30.0)
		"spawn":
			spawn(args[0])
		"think":
			player.think(" ".join(PackedStringArray(args)))
		"shake":
			player.shake(float(args[0]) if args.size() > 0 else 0.5)


# ------------------------------------------------------------ the peephole
func _build_peephole() -> void:
	_peep_cam = Camera3D.new()
	_peep_cam.fov = 130.0
	_peep_cam.near = 0.02
	_peep_cam.position = Vector3(10.2, 1.55, 5.15)
	_peep_cam.rotation_degrees.y = -90.0
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


func _unhandled_input(event: InputEvent) -> void:
	if peeping and (event.is_action_pressed("interact") or event.is_action_pressed("move_back") or event.is_action_pressed("phone_back")):
		peek(false)
		get_viewport().set_input_as_handled()
