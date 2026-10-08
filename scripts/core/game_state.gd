extends Node
## Central, serialisable game state. Everything that must survive save/load
## lives in `data`. Only plain Dictionaries/Arrays/strings/numbers/bools.

const VERSION := 3

var data: Dictionary = {}
var current_app := ""         # not saved: what the player is looking at right now
var in_game := false          # a session is active (not main menu)
var _msg_counter := 0


func _ready() -> void:
	reset()


func reset() -> void:
	data = {
		"version": VERSION,
		"chapter": "",
		"chapter_start": 0.0,
		"time": 0.0,
		"playtime": 0.0,
		"flags": {},
		"beats_done": {},
		"running": {},
		"choices": {},          # thread -> pending choice op + beat
		"choice_log": [],       # [{id, option, text}]
		"threads": {},
		"thread_order": [],
		"hidden_threads": {},
		"contacts": {},
		"calls": [],
		"voicemails": [],
		"photos": {},
		"photo_order": [],
		"emails": [],
		"files": [],
		"notes": [],
		"player_notes": [],
		"browser": {"history": [], "visited": {}, "searched": {}, "unlocked": {}, "bookmarks": []},
		"clues": {},
		"location": "casa",
		"location_log": [],
		"map_marks": {},
		"battery": 82,
		"opened": {},            # app -> total opens
		"chapter_opened": {},    # app -> opens this chapter
		"viewed": {},            # photo id -> view count
		"emails_read": {},
		"files_opened": {},
		"called": {},
		"phone": {"hidden_files": false, "dev_mode": false, "dnd": false, "eco_app": false, "pin": "1410", "pin_required": false, "wallpaper": "IMG_2207"},
		"camera": {"armed": "", "shots": 0},
		"alarms": [{"time": "07:30", "label": "Trabalho", "on": true}],
		"deduction": {},
		"notifications": [],
		"ending": "",
		"endings_seen": [],
		"msg_seq": 0,
	}
	_msg_counter = 0


# ------------------------------------------------------------------ flags
func flag(name: String) -> bool:
	var v = data.flags.get(name, false)
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return v != 0
	if typeof(v) == TYPE_STRING:
		return v != ""
	return v != null


func get_var(name: String, default = 0):
	return data.flags.get(name, default)


func set_var(name: String, value) -> void:
	data.flags[name] = value


func inc_var(name: String, n: float = 1.0) -> void:
	var cur = data.flags.get(name, 0)
	if typeof(cur) != TYPE_INT and typeof(cur) != TYPE_FLOAT:
		cur = 0
	var v = cur + n
	if is_equal_approx(v, round(v)):
		v = int(round(v))
	data.flags[name] = v


# ---------------------------------------------------------------- threads
func ensure_thread(thread_id: String) -> Dictionary:
	if not data.threads.has(thread_id):
		data.threads[thread_id] = {"messages": [], "unread": 0}
	return data.threads[thread_id]


func next_msg_id() -> String:
	data.msg_seq = int(data.msg_seq) + 1
	return "m%d" % data.msg_seq


func add_message(thread_id: String, msg: Dictionary, count_unread := true) -> Dictionary:
	var th := ensure_thread(thread_id)
	if not msg.has("id") or msg.id == "":
		msg.id = next_msg_id()
	else:
		# a message with an explicit id may only exist once (prevents duplicates on resume)
		for m in th.messages:
			if m.id == msg.id:
				return m
	if not msg.has("t"):
		msg.t = data.time
	th.messages.append(msg)
	# keep chronological order for backdated inserts
	if th.messages.size() > 1 and float(msg.t) < float(th.messages[-2].t):
		th.messages.sort_custom(func(a, b): return float(a.t) < float(b.t))
	if count_unread and msg.get("from", "") != "me":
		th.unread = int(th.unread) + 1
	data.thread_order.erase(thread_id)
	data.thread_order.push_front(thread_id)
	data.hidden_threads.erase(thread_id)
	return msg


func find_message(thread_id: String, msg_id: String) -> Dictionary:
	var th: Dictionary = data.threads.get(thread_id, {})
	for m in th.get("messages", []):
		if m.id == msg_id:
			return m
	return {}


func mark_read(thread_id: String) -> void:
	if data.threads.has(thread_id):
		data.threads[thread_id].unread = 0


func unread_total() -> int:
	var n := 0
	for t in data.threads.values():
		n += int(t.unread)
	return n


func thread_unread(thread_id: String) -> int:
	return int(data.threads.get(thread_id, {}).get("unread", 0))


# ---------------------------------------------------------------- contacts
func contact(id: String) -> Dictionary:
	## Merged view: static character data overridden by runtime state.
	var base := Content.character(id).duplicate()
	var over: Dictionary = data.contacts.get(id, {})
	for k in over:
		base[k] = over[k]
	base["id"] = id
	return base


func contact_name(id: String) -> String:
	if id == "me":
		return "Eu"
	var c := contact(id)
	if c.is_empty():
		return id
	if c.get("saved", false) or data.contacts.has(id) and data.contacts[id].get("saved", false):
		return c.get("name", id)
	return c.get("number", c.get("name", id))


func is_saved_contact(id: String) -> bool:
	return contact(id).get("saved", false)


# ---------------------------------------------------------------- photos
func add_photo(photo_id: String, album := "") -> void:
	if data.photos.has(photo_id):
		return
	var p := Content.get_item("photos", photo_id)
	data.photos[photo_id] = {"variant": "base", "added": data.time, "album": album if album != "" else p.get("album", "Câmara"), "new": true}
	data.photo_order.push_front(photo_id)


func photo_variant(photo_id: String) -> String:
	return data.photos.get(photo_id, {}).get("variant", "base")


# ---------------------------------------------------------------- clues
func has_clue(id: String) -> bool:
	return data.clues.has(id)


func add_clue(id: String) -> bool:
	if data.clues.has(id):
		return false
	data.clues[id] = {"t": data.time, "tag": "", "seen": false}
	return true


func clue_count() -> int:
	return data.clues.size()


# ---------------------------------------------------------------- notifications
func post_notification(app: String, title: String, body: String, extra := {}) -> Dictionary:
	var n := {"app": app, "title": title, "body": body, "t": data.time}
	for k in extra:
		n[k] = extra[k]
	data.notifications.push_front(n)
	if data.notifications.size() > 30:
		data.notifications.resize(30)
	return n


func clear_notifications(app := "") -> void:
	if app == "":
		data.notifications.clear()
	else:
		data.notifications = data.notifications.filter(func(n): return n.app != app)


# ---------------------------------------------------------------- serialisation
func to_save() -> Dictionary:
	return data.duplicate(true)


func from_save(d: Dictionary) -> bool:
	if typeof(d) != TYPE_DICTIONARY or not d.has("version"):
		return false
	reset()
	# merge so that saves from older versions get new keys with defaults
	for k in d:
		if data.has(k) and typeof(data[k]) == TYPE_DICTIONARY and typeof(d[k]) == TYPE_DICTIONARY:
			for kk in d[k]:
				data[k][kk] = d[k][kk]
		else:
			data[k] = d[k]
	_normalise_numbers()
	data.version = VERSION
	return true


## JSON turns every int into float; restore ints where it matters for display.
func _normalise_numbers() -> void:
	data.battery = int(data.battery)
	data.msg_seq = int(data.msg_seq)
	for t in data.threads.values():
		t.unread = int(t.unread)
	for k in data.flags.keys():
		var v = data.flags[k]
		if typeof(v) == TYPE_FLOAT and is_equal_approx(v, round(v)):
			data.flags[k] = int(round(v))
	for k in data.running.keys():
		data.running[k] = int(data.running[k])
