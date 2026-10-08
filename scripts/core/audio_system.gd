extends Node
## Plays synthesised sounds on the right buses. Sounds are generated on a
## worker thread at startup and cached.

const CAPTIONS := {
	"breath": "respiração", "knock": "três pancadas", "knock_one": "uma pancada",
	"footsteps": "passos", "static": "estática", "sea": "mar", "whisper": "sussurro",
	"voice": "voz distorcida", "voice_low": "voz grave, distorcida", "door": "porta a ranger",
	"sub": "ruído grave", "heartbeat": "batimento", "glitch": "interferência",
	"glitch_short": "interferência", "water": "água", "drop": "algo a cair", "beep": "sinal",
	"click_far": "clique", "rain": "chuva", "hum": "zumbido", "vibrate": "vibração",
	"call_connect": "ligação estabelecida", "call_end": "chamada terminada", "shutter": "obturador",
}

var _cache := {}
var _mutex := Mutex.new()
var _thread: Thread
var _synth := SoundSynth.new()
var _sfx: Array[AudioStreamPlayer] = []
var _amb_a: AudioStreamPlayer
var _amb_b: AudioStreamPlayer
var _music: AudioStreamPlayer
var _ring: AudioStreamPlayer
var _ambient_name := ""
var _music_name := ""
var _amb_tween: Tween
var _music_tween: Tween
var muted_for_tests := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx.append(p)
	_amb_a = _make_player("Ambient")
	_amb_b = _make_player("Ambient")
	_music = _make_player("Music")
	_ring = _make_player("SFX")
	if OS.get_thread_caller_id() == OS.get_main_thread_id() and DisplayServer.get_name() != "headless":
		_thread = Thread.new()
		_thread.start(_prewarm)


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _prewarm() -> void:
	var names := ["msg", "notif", "tap", "key", "sent", "unlock", "lock", "vibrate", "app_open", "room", "menu", "ring", "dialtone", "night", "tension", "static", "glitch", "breath", "sea", "dread", "memory", "ring_wrong", "call_connect", "call_end", "shutter", "mail", "clue", "boot"]
	for n in names:
		_get_stream(n)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func _get_stream(sound_name: String) -> AudioStreamWAV:
	_mutex.lock()
	var s: AudioStreamWAV = _cache.get(sound_name)
	_mutex.unlock()
	if s:
		return s
	# 'key' gets a few variants for a natural typing sound
	s = _synth.make(sound_name)
	_mutex.lock()
	_cache[sound_name] = s
	_mutex.unlock()
	return s


func play(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if muted_for_tests or sound_name == "":
		return
	var stream := _get_stream(sound_name)
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.bus = "Voice" if sound_name in ["voice", "voice_low", "whisper", "breath"] else "SFX"
			p.play()
			return
	_sfx[0].stop()
	_sfx[0].stream = stream
	_sfx[0].play()


func key_click() -> void:
	play("key", -6.0, randf_range(0.9, 1.15))


func set_ambient(sound_name: String, fade := 2.0) -> void:
	if muted_for_tests or sound_name == _ambient_name:
		return
	_ambient_name = sound_name
	if _amb_tween:
		_amb_tween.kill()
	var old := _amb_a if _amb_a.playing else _amb_b
	var new_p := _amb_b if old == _amb_a else _amb_a
	_amb_tween = create_tween().set_parallel(true)
	if old.playing:
		_amb_tween.tween_property(old, "volume_db", -60.0, fade)
		_amb_tween.chain().tween_callback(old.stop)
	if sound_name != "":
		new_p.stream = _get_stream(sound_name)
		new_p.volume_db = -60.0
		new_p.play()
		_amb_tween.tween_property(new_p, "volume_db", _ambient_level(sound_name), fade)


func _ambient_level(sound_name: String) -> float:
	match sound_name:
		"room": return -8.0
		"hum": return -14.0
		"night": return -6.0
		"tension": return -4.0
		"dread": return -3.0
		"rain": return -8.0
		"sea": return -6.0
		"static": return -10.0
	return -6.0


## Instant, total silence. Used as a horror beat: the room tone disappears.
func cut_all() -> void:
	_ambient_name = ""
	_amb_a.stop()
	_amb_b.stop()
	_music_name = ""
	_music.stop()


func current_ambient() -> String:
	return _ambient_name


func set_music(sound_name: String, fade := 3.0) -> void:
	if muted_for_tests or sound_name == _music_name:
		return
	_music_name = sound_name
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -60.0, fade * 0.5)
		_music_tween.tween_callback(_music.stop)
	if sound_name != "":
		_music_tween.tween_callback(func():
			_music.stream = _get_stream(sound_name)
			_music.volume_db = -40.0
			_music.play())
		_music_tween.tween_property(_music, "volume_db", -6.0, fade)


func start_ring(wrong := false) -> void:
	if muted_for_tests:
		return
	_ring.stream = _get_stream("ring_wrong" if wrong else "ring")
	_ring.volume_db = -3.0
	_ring.play()
	play("vibrate_long", -4.0)


func start_dialtone() -> void:
	if muted_for_tests:
		return
	_ring.stream = _get_stream("dialtone")
	_ring.volume_db = -6.0
	_ring.play()


func stop_ring() -> void:
	_ring.stop()


func caption(sound_name: String) -> String:
	return CAPTIONS.get(sound_name, sound_name)
