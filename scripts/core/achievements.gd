extends Node
## Achievements + endings record. Persisted per-profile (not per save slot) in
## user://profile.json, and mirrored to Steam when the GodotSteam singleton is
## present. Without Steam the game runs normally.

const PATH := "user://profile.json"

var unlocked := {}        # id -> unix real time
var endings := {}         # ending id -> count
var stats := {}
var steam: Object = null
var steam_ok := false
var persist := true      # tests turn this off so they never touch the real profile


func _ready() -> void:
	_load()
	_init_steam()


func _init_steam() -> void:
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var res = steam.call("steamInitEx") if steam.has_method("steamInitEx") else steam.call("steamInit")
		steam_ok = typeof(res) == TYPE_DICTIONARY and int(res.get("status", 1)) == 0
		if steam_ok:
			for id in unlocked:
				_steam_set(id)


func _process(_d: float) -> void:
	if steam_ok and steam.has_method("run_callbacks"):
		steam.call("run_callbacks")


func _steam_set(id: String) -> void:
	if not steam_ok or not persist:
		return
	steam.call("setAchievement", id)
	steam.call("storeStats")


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func unlock(id: String) -> void:
	if unlocked.has(id):
		return
	if not Content.has_item("achievements", id):
		push_warning("unknown achievement " + id)
		return
	unlocked[id] = Time.get_unix_time_from_system()
	_save()
	_steam_set(id)
	Events.achievement_unlocked.emit(id)
	if unlocked.size() >= Content.all("achievements").size() - 1:
		unlock("all_achievements")


func record_new_game() -> void:
	stats["games"] = int(stats.get("games", 0)) + 1
	_save()


func record_ending(id: String) -> void:
	endings[id] = int(endings.get(id, 0)) + 1
	stats["last_ending"] = id
	if not GameState.data.endings_seen.has(id):
		GameState.data.endings_seen.append(id)
	_save()
	var e := Content.get_item("endings", id)
	if e.has("achievement"):
		unlock(e.achievement)
	if endings.size() >= 3:
		unlock("three_endings")
	var mains := ["A", "B", "C", "D"]
	var all_main := true
	for m in mains:
		if not endings.has(m):
			all_main = false
	if all_main:
		unlock("all_endings")


func ending_seen(id: String) -> bool:
	return endings.has(id)


func on_chapter_end(ch: String) -> void:
	var map := {"ch01": "ch1_done", "ch03": "ch3_done", "ch05": "ch5_done", "ch08": "ch8_done"}
	if map.has(ch):
		unlock(map[ch])


func check_clues() -> void:
	# clues found across every playthrough (Extras → statistics)
	var ever: Dictionary = stats.get("clues_ever", {})
	var grew := false
	for c in GameState.data.clues:
		if not ever.has(c):
			ever[c] = 1
			grew = true
	if grew:
		stats["clues_ever"] = ever
		_save()
	var n := GameState.clue_count()
	if n >= 10:
		unlock("clues_10")
	if n >= 30:
		unlock("clues_30")
	if n >= Content.all("clues").size():
		unlock("clues_all")


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(d) == TYPE_DICTIONARY:
		unlocked = d.get("unlocked", {})
		endings = d.get("endings", {})
		stats = d.get("stats", {})


func _save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unlocked": unlocked, "endings": endings, "stats": stats}, "  "))


func reset_profile() -> void:
	unlocked.clear()
	endings.clear()
	stats.clear()
	_save()
