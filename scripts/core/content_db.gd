extends Node
## Read-only narrative content loaded from res://data.
## All story text lives in data files; code only interprets it.

const DATA_DIR := "res://data/"
const KINDS := ["characters", "photos", "pages", "emails", "files", "notes", "map", "clues", "achievements", "endings", "voicemails", "chapters_meta"]

var db := {}
var chapters := {}      # id -> parsed chapter Dictionary
var chapter_order: Array = []
var global_script := {} # parsed global.story
var load_errors: Array[String] = []


func _ready() -> void:
	reload()


func reload() -> void:
	db.clear()
	chapters.clear()
	load_errors.clear()
	for kind in KINDS:
		db[kind] = _load_json(DATA_DIR + kind + ".json")
	var meta: Dictionary = db.get("chapters_meta", {})
	chapter_order = meta.get("order", [])
	for ch_id in chapter_order:
		var path: String = DATA_DIR + "chapters/" + ch_id + ".story"
		var parsed := StoryParser.parse_file(path)
		if parsed.has("errors") and not parsed.errors.is_empty():
			for e in parsed.errors:
				load_errors.append("%s: %s" % [ch_id, e])
		chapters[ch_id] = parsed
	var gpath := DATA_DIR + "chapters/global.story"
	if FileAccess.file_exists(gpath):
		global_script = StoryParser.parse_file(gpath)
		for e in global_script.get("errors", []):
			load_errors.append("global: %s" % e)
	for e in load_errors:
		push_error(e)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		load_errors.append("missing data file " + path)
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		load_errors.append("%s:%d %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		load_errors.append(path + " is not an object")
		return {}
	return json.data


func get_item(kind: String, id: String) -> Dictionary:
	var d: Dictionary = db.get(kind, {})
	var v = d.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}


func has_item(kind: String, id: String) -> bool:
	return db.get(kind, {}).has(id)


func all(kind: String) -> Dictionary:
	return db.get(kind, {})


func character(id: String) -> Dictionary:
	return get_item("characters", id)


func char_name(id: String) -> String:
	if id == "me":
		return "Eu"
	var c := character(id)
	return c.get("name", id)


func chapter(id: String) -> Dictionary:
	return chapters.get(id, {})


func chapter_title(id: String) -> String:
	var meta: Dictionary = db.get("chapters_meta", {}).get("titles", {})
	return meta.get(id, id)


func next_chapter(id: String) -> String:
	var i := chapter_order.find(id)
	if i == -1 or i + 1 >= chapter_order.size():
		return ""
	return chapter_order[i + 1]
