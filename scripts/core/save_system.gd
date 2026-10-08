extends Node
## Save slots in user://saves. Writes are atomic (temp file + rename) and the
## previous file is kept as .bak so a crash mid-write never loses progress.
## Slot "auto" is written at chapter starts and story checkpoints.

var DIR := "user://saves/"
const MANUAL_SLOTS := 5

var last_error := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


## Tests write to a separate folder so they never touch a player's saves.
func use_test_dir(suffix := "") -> void:
	DIR = "user://test_saves%s/" % suffix
	DirAccess.make_dir_recursive_absolute(DIR)


func _path(slot: String) -> String:
	return DIR + "slot_" + slot + ".json"


func save_to(slot: String) -> bool:
	if not GameState.in_game or GameState.data.chapter == "":
		return false
	var payload := {
		"meta": {
			"chapter": GameState.data.chapter,
			"chapter_title": Content.chapter_title(GameState.data.chapter),
			"game_time": GameState.data.time,
			"playtime": GameState.data.playtime,
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"slot": slot,
		},
		"state": GameState.to_save(),
	}
	var text := JSON.stringify(payload)
	var path := _path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "cannot write " + tmp
		push_error(last_error)
		return false
	f.store_string(text)
	f.close()
	var dir := DirAccess.open(DIR)
	if dir == null:
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			dir.remove(path.get_file() + ".bak")
		dir.rename(path.get_file(), path.get_file() + ".bak")
	var err := dir.rename(tmp.get_file(), path.get_file())
	if err != OK:
		last_error = "rename failed %d" % err
		return false
	return true


func autosave() -> void:
	save_to("auto")


func read_slot(slot: String) -> Dictionary:
	for p in [_path(slot), _path(slot) + ".bak"]:
		if not FileAccess.file_exists(p):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string(p))
		if typeof(d) == TYPE_DICTIONARY and d.has("state") and d.has("meta"):
			return d
		push_warning("corrupt save " + p + ", trying backup")
	return {}


func slot_meta(slot: String) -> Dictionary:
	var d := read_slot(slot)
	return d.get("meta", {})


func has_any_save() -> bool:
	for s in all_slots():
		if not slot_meta(s).is_empty():
			return true
	return false


func all_slots() -> Array:
	var out := ["auto", "quick"]
	for i in MANUAL_SLOTS:
		out.append(str(i + 1))
	return out


func latest_slot() -> String:
	var best := ""
	var best_t := ""
	for s in all_slots():
		var m := slot_meta(s)
		if m.is_empty():
			continue
		if best == "" or str(m.saved_at) > best_t:
			best = s
			best_t = str(m.saved_at)
	return best


func load_from(slot: String) -> bool:
	var d := read_slot(slot)
	if d.is_empty():
		last_error = "empty slot"
		return false
	Director.stop()
	if not GameState.from_save(d.state):
		last_error = "invalid state"
		return false
	if Content.chapter(GameState.data.chapter).is_empty():
		last_error = "unknown chapter " + str(GameState.data.chapter)
		return false
	Director.resume_from_state()
	return true


func delete_slot(slot: String) -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		return
	for suffix in ["", ".bak"]:
		var f: String = _path(slot).get_file() + suffix
		if dir.file_exists(f):
			dir.remove(f)
