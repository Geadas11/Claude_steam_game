extends Node
## Player settings (outside the fiction). Stored in user://settings.cfg.

const PATH := "user://settings.cfg"

var values := {
	"master_volume": 0.9,
	"sfx_volume": 0.9,
	"ambient_volume": 0.8,
	"music_volume": 0.6,
	"voice_volume": 1.0,
	"text_scale": 1.0,          # 0.85 .. 1.5
	"text_speed": 1.0,          # message pacing multiplier (higher = faster)
	"subtitles": true,          # captions for calls / recordings / sound cues
	"sound_captions": false,    # [respiração], [estática] ...
	"high_contrast": false,
	"reduce_effects": false,    # glitches / flicker scaled down
	"reduce_motion": false,     # transitions, shake
	"fullscreen": false,
	"vsync": true,
	"resolution": "1600x900",
	"seen_warning": false,
	"seen_controls_hint": false,
	"language": "pt",
}

var _bus_ids := {}


func _ready() -> void:
	_setup_audio_buses()
	_setup_input()
	load_settings()
	apply()


func _setup_audio_buses() -> void:
	for bus_name in ["SFX", "Ambient", "Music", "Voice"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
		_bus_ids[bus_name] = AudioServer.get_bus_index(bus_name)


func _setup_input() -> void:
	_add_key_action("pause_menu", [KEY_ESCAPE], [JOY_BUTTON_START])
	_add_key_action("phone_back", [KEY_BACKSPACE], [JOY_BUTTON_B])
	_add_key_action("phone_home", [KEY_HOME, KEY_H], [JOY_BUTTON_BACK])
	_add_key_action("quick_save", [KEY_F5], [])
	_add_key_action("quick_load", [KEY_F9], [])
	_add_key_action("toggle_fullscreen", [KEY_F11], [])


func _add_key_action(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


func get_value(key: String, default = null):
	return values.get(key, default)


func set_value(key: String, v) -> void:
	values[key] = v
	apply()
	save_settings()
	Events.settings_changed.emit()


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k in values.keys():
		if cfg.has_section_key("settings", k):
			var v = cfg.get_value("settings", k)
			if typeof(v) == typeof(values[k]) or (typeof(values[k]) == TYPE_FLOAT and typeof(v) == TYPE_INT):
				values[k] = v


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in values.keys():
		cfg.set_value("settings", k, values[k])
	cfg.save(PATH)


func apply() -> void:
	_set_bus_volume("Master", values.master_volume)
	_set_bus_volume("SFX", values.sfx_volume)
	_set_bus_volume("Ambient", values.ambient_volume)
	_set_bus_volume("Music", values.music_volume)
	_set_bus_volume("Voice", values.voice_volume)
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	if values.fullscreen and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not values.fullscreen and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution()
	elif not values.fullscreen:
		_apply_resolution()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)


func _apply_resolution() -> void:
	var parts: PackedStringArray = str(values.resolution).split("x")
	if parts.size() != 2:
		return
	var size := Vector2i(int(parts[0]), int(parts[1]))
	if size.x < 640 or size.y < 360:
		return
	var screen := DisplayServer.screen_get_size()
	size.x = mini(size.x, screen.x)
	size.y = mini(size.y, screen.y)
	if DisplayServer.window_get_size() != size:
		DisplayServer.window_set_size(size)
		var pos := (screen - size) / 2
		DisplayServer.window_set_position(DisplayServer.screen_get_position() + pos)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


## Effects multiplier used by glitch / flicker code. Never fully 0 so horror
## beats still read, just gentler.
func effects_scale() -> float:
	return 0.3 if values.reduce_effects else 1.0


func text_size(base: int) -> int:
	return int(round(base * float(values.text_scale)))
