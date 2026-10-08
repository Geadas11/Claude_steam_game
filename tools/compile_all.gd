extends Node
## Loads every script so parse errors are reported. Usage: godot --headless res://tools/compile_all.tscn

func _ready() -> void:
	var bad := 0
	var files := _scan("res://scripts")
	for f in files:
		var s = load(f)
		if s == null:
			bad += 1
			print("FAILED: ", f)
	print("OK: checked %d scripts, %d failed" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)


func _scan(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_scan(dir + "/" + sub))
	return out
