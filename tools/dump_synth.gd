extends SceneTree
## Writes every synthesised sound to WAV (for measuring loudness when a
## recording replaces it): godot --headless -s tools/dump_synth.gd -- <dir>
func _init() -> void:
	var dir: String = OS.get_cmdline_user_args()[0]
	var synth := SoundSynth.new()
	var src := FileAccess.get_file_as_string("res://scripts/core/sound_synth.gd")
	var re := RegEx.create_from_string("\\n\\t\\t\"([a-z_0-9]+)\": buf =")
	for m in re.search_all(src):
		var n := m.get_string(1)
		var st := synth.make(n)
		st.loop_mode = AudioStreamWAV.LOOP_DISABLED
		st.save_to_wav(dir.path_join(n + ".wav"))
	quit()
