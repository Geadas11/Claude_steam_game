extends Node
## Headless test suite. Run: godot --headless res://tests/run_tests.tscn
## Optional user args: -- --only=validate|save|play  --policy=A|B|C|D|E|random --chapters=ch01,ch02
##
## 1. validate: every id referenced by story scripts and data exists; every
##    condition expression parses; no orphan chapters.
## 2. save: save/load round-trip preserves state and resumes running beats.
## 3. play: simulated playthroughs (fast mode) with a scripted "player" that
##    performs the walkthrough actions; checks each chapter ends and the
##    expected ending is reached for each policy.

var failures: Array[String] = []
var passes := 0
var _policy := "A"
var _only := ""
var _log_choices := false


func _ready() -> void:
	Audio.muted_for_tests = true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_only = a.substr(7)
		elif a.begins_with("--policy="):
			_policy = a.substr(9)
		elif a == "--verbose":
			_log_choices = true
	await get_tree().process_frame
	if _only == "" or _only == "validate":
		_validate()
	if _only == "" or _only == "save":
		await _test_save_load()
	if _only == "" or _only == "play":
		var policies := ["A", "B", "C", "D", "E"] if _only == "" else [_policy]
		for p in policies:
			await _playthrough(p)
	print("")
	print("==== %d passed, %d failed ====" % [passes, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	get_tree().quit(1 if failures.size() > 0 else 0)


func ok(cond: bool, msg: String) -> void:
	if cond:
		passes += 1
	else:
		failures.append(msg)


# =================================================================== validate
func _validate() -> void:
	print("-- validate")
	ok(Content.load_errors.is_empty(), "content load errors: %s" % str(Content.load_errors))
	var clue_refs := {}
	var all_beats: Array = []
	for ch_id in Content.chapter_order:
		var ch := Content.chapter(ch_id)
		ok(not ch.is_empty(), "chapter %s missing" % ch_id)
		ok(ch.get("id", "") == ch_id, "chapter %s has @chapter %s" % [ch_id, ch.get("id", "")])
		for b in ch.get("beats", []):
			all_beats.append([ch_id, b])
		for b in ch.get("calls", []):
			all_beats.append([ch_id, b])
	for b in Content.global_script.get("beats", []) + Content.global_script.get("calls", []):
		all_beats.append(["global", b])
	var seen_beats := {}
	for pair in all_beats:
		var where: String = pair[0]
		var b: Dictionary = pair[1]
		var key: String = where + ":" + b.id
		ok(not seen_beats.has(key), "duplicate beat " + key)
		seen_beats[key] = true
		_check_expr(b.when, key + " @when")
		for op in b.ops:
			_check_op(op, key, clue_refs)
	# data references
	for pid in Content.all("photos"):
		var p: Dictionary = Content.get_item("photos", pid)
		for h in p.get("hotspots", []):
			if h.get("clue", "") != "":
				clue_refs[h.clue] = "photo " + pid
		for c in p.get("meta_clues", []):
			clue_refs[c] = "photo meta " + pid
	for kind in ["pages", "emails", "files", "notes", "voicemails"]:
		for id in Content.all(kind):
			var d: Dictionary = Content.get_item(kind, id)
			for c in d.get("clues", []) + d.get("clues_end", []):
				clue_refs[c] = kind + " " + id
			for att in d.get("attachments", []):
				_check_ref(att.type, att.id, kind + " " + id)
			for blk in d.get("blocks", []):
				if blk.has("img"):
					_check_ref("photo", blk.img, "page " + id)
				if blk.has("link"):
					_check_ref("page", blk.link, "page " + id)
				if blk.has("clue"):
					clue_refs[blk.clue] = "page " + id
				if blk.has("when"):
					_check_expr(blk.when, "page %s block" % id)
				if blk.has("file"):
					_check_ref("file", blk.file, "page " + id)
			if d.has("requires"):
				_check_expr(d.requires, "%s %s requires" % [kind, id])
			for c2 in d.get("contains", []):
				_check_ref("file", c2, "archive " + id)
			if d.has("photo"):
				_check_ref("photo", d.photo, "file " + id)
	for loc_id in Content.all("map").get("locations", {}):
		var l: Dictionary = Content.all("map").locations[loc_id]
		for c in l.get("clues", []):
			clue_refs[c] = "map " + loc_id
		if l.has("requires"):
			_check_expr(l.requires, "map %s requires" % loc_id)
	for day in Content.all("map").get("timeline", {}):
		var e: Dictionary = Content.all("map").timeline[day]
		for c in e.get("clues", []):
			clue_refs[c] = "timeline " + day
		for s in e.get("stops", []):
			ok(Content.all("map").locations.has(s.loc), "timeline %s unknown loc %s" % [day, s.loc])
	for c in Content.all("characters"):
		for cl in Content.character(c).get("clues", []):
			clue_refs[cl] = "character " + c
	var ded: Dictionary = Content.all("chapters_meta").get("deduction", {})
	for q in ded.get("questions", []):
		var has_answer := false
		for o in q.options:
			if o.id == q.answer:
				has_answer = true
			if o.get("needs", "") != "":
				clue_refs[o.needs] = "deduction " + q.id
		ok(has_answer, "deduction %s answer not among options" % q.id)
	for l in Content.all("chapters_meta").get("system_log", []):
		if l.has("when"):
			_check_expr(l.when, "system_log")
	for e in Content.all("endings"):
		ok(Content.has_item("achievements", Content.get_item("endings", e).get("achievement", "")), "ending %s achievement" % e)
	for c in clue_refs:
		ok(Content.has_item("clues", c), "clue '%s' referenced by %s is not defined" % [c, clue_refs[c]])
	for c in Content.all("clues"):
		var cd: Dictionary = Content.get_item("clues", c)
		for r in cd.get("related", []):
			ok(Content.has_item("clues", r), "clue %s related to unknown %s" % [c, r])
		if not clue_refs.has(c):
			print("  note: clue '%s' defined but never awarded" % c)
	ok(Content.all("achievements").size() >= 20, "at least 20 achievements")
	print("   validated %d beats, %d clue references" % [all_beats.size(), clue_refs.size()])


func _check_expr(e: String, where: String) -> void:
	var expr := Expression.new()
	var err := expr.parse(e)
	ok(err == OK, "%s: bad expression '%s' (%s)" % [where, e, expr.get_error_text()])
	if err == OK:
		expr.execute([], Director, false)
		ok(not expr.has_execute_failed(), "%s: expression fails to execute '%s' (%s)" % [where, e, expr.get_error_text()])


func _check_ref(kind: String, id: String, where: String) -> void:
	var table := {"photo": "photos", "page": "pages", "file": "files", "email": "emails", "note": "notes", "voicemail": "voicemails", "audio": "voicemails", "link": "pages", "achieve": "achievements"}
	if not table.has(kind):
		failures.append("%s: unknown ref kind %s" % [where, kind])
		return
	ok(Content.has_item(table[kind], id), "%s: unknown %s '%s'" % [where, kind, id])


func _check_op(op: Dictionary, where: String, clue_refs: Dictionary) -> void:
	match op.op:
		"msg":
			ok(Content.has_item("characters", op.thread), "%s: unknown thread %s" % [where, op.thread])
			ok(op.from == "me" or Content.has_item("characters", op.from), "%s: unknown sender %s" % [where, op.from])
			if not op.att.is_empty():
				_check_ref(op.att.type, op.att.id, where)
		"jif":
			_check_expr(op.expr, where + " if")
			ok(op.to >= 0, where + " unresolved jump")
		"jmp":
			ok(op.to >= 0, where + " unresolved jump")
		"choice":
			ok(Content.has_item("characters", op.thread), "%s: choice thread %s" % [where, op.thread])
			for o in op.options:
				if o.cond != "":
					_check_expr(o.cond, where + " choice cond")
		"call":
			ok(Content.has_item("characters", op.who), "%s: call who %s" % [where, op.who])
			for l in op.lines:
				if l.op == "line" and l.who != "" and l.who != "me":
					ok(Content.has_item("characters", l.who), "%s: call line who %s" % [where, l.who])
		"cmd":
			var a: Array = op.args
			match op.name:
				"photo", "variant":
					_check_ref("photo", a[0], where)
				"email":
					_check_ref("email", a[0], where)
				"file":
					_check_ref("file", a[0], where)
				"note":
					_check_ref("note", a[0], where)
				"voicemail":
					_check_ref("voicemail", a[0], where)
				"unlock":
					_check_ref("page", a[0], where)
				"achieve":
					_check_ref("achieve", a[0], where)
				"clue":
					clue_refs[a[0]] = where
				"contact", "rename", "contactset":
					ok(Content.has_item("characters", a[0]), "%s: contact %s" % [where, a[0]])
				"location", "mapmark":
					ok(Content.all("map").get("locations", {}).has(a[0]), "%s: location %s" % [where, a[0]])
				"open":
					ok(Phone.APPS.has(a[0]), "%s: app %s" % [where, a[0]])
				"edit", "delete", "unsend", "retime", "typing", "autotype", "read", "hidethread", "showthread", "clearchoice":
					ok(Content.has_item("characters", a[0]), "%s: thread %s" % [where, a[0]])
				"camera":
					var ok_ev := false
					for sid in ["CAM_VIEW", "CAM_FRONT"]:
						if Content.get_item("photos", sid).get("events", {}).has(a[0]):
							ok_ev = true
					ok(ok_ev, "%s: camera event %s" % [where, a[0]])
				"ending":
					ok(Content.has_item("endings", a[0]), "%s: ending %s" % [where, a[0]])
				"calllog":
					ok(Content.has_item("characters", a[0]), "%s: calllog who %s" % [where, a[0]])
				"notify":
					ok(Phone.APPS.has(a[0]), "%s: notify app %s" % [where, a[0]])


# =================================================================== save/load
func _test_save_load() -> void:
	print("-- save/load")
	Director.fast_mode = true
	Director.auto_chooser = func(_t, pending): return pending.options[0].index
	Director.auto_answer = func(_c): return true
	Director.new_game()
	for i in 30:
		GameState.mark_read("sofia")
		await get_tree().process_frame
	ok(GameState.data.threads.has("sofia"), "sofia thread exists")
	var before := JSON.stringify(GameState.to_save())
	ok(Saves.save_to("test"), "save_to test")
	var running_before: Dictionary = GameState.data.running.duplicate()
	GameState.reset()
	ok(Saves.load_from("test"), "load_from test")
	var after := JSON.stringify(GameState.to_save())
	ok(GameState.data.chapter == "ch01", "chapter restored")
	ok(GameState.data.threads.sofia.messages.size() == JSON.parse_string(before).threads.sofia.messages.size(), "messages restored")
	ok(GameState.data.running.keys().size() == running_before.keys().size(), "running beats restored")
	# corrupt the main file: loader must fall back to .bak
	ok(Saves.save_to("test"), "second save")
	var f := FileAccess.open("user://saves/slot_test.json", FileAccess.WRITE)
	f.store_string("{ corrupt")
	f.close()
	ok(not Saves.read_slot("test").is_empty(), "falls back to .bak when main save is corrupt")
	Saves.delete_slot("test")
	Director.stop()
	Director.auto_chooser = Callable()
	Director.auto_answer = Callable()


# =================================================================== playthrough
var _walk: Dictionary = {}


func _playthrough(policy: String) -> void:
	print("-- playthrough policy=%s" % policy)
	_walk = JSON.parse_string(FileAccess.get_file_as_string("res://tests/walkthrough.json"))
	Director.fast_mode = true
	Director.auto_answer = func(_c): return true
	Director.auto_chooser = func(thread, pending): return _choose(policy, thread, pending)
	var ending_hit := ""
	var ended_chapters: Array = []
	var cb_end := func(ch): ended_chapters.append(ch)
	var cb_ending := func(e): ending_hit = e
	Events.chapter_ended.connect(cb_end)
	Events.ending_reached.connect(cb_ending)
	Director.new_game()
	var safety := 0
	var last_chapter := ""
	var stuck_frames := 0
	while ending_hit == "" and safety < 60000:
		safety += 1
		var ch: String = GameState.data.chapter
		if ch != last_chapter:
			last_chapter = ch
			stuck_frames = 0
		stuck_frames += 1
		_auto_player(ch, policy)
		Clock.advance_minutes(1.5)
		await get_tree().process_frame
		if ended_chapters.has(ch) and Director.active == false:
			if Content.next_chapter(ch) == "":
				break
			Director.advance_chapter()
		if stuck_frames > 5000:
			failures.append("policy %s stuck in %s; running=%s pending=%s" % [policy, ch, str(GameState.data.running.keys()), str(GameState.data.choices.keys())])
			_dump_pending(ch)
			break
	Events.chapter_ended.disconnect(cb_end)
	Events.ending_reached.disconnect(cb_ending)
	print("   chapters ended: %s" % str(ended_chapters))
	print("   ending: %s   clues: %d   playtime frames: %d" % [ending_hit, GameState.clue_count(), safety])
	var expect: String = _walk.get("expected_endings", {}).get(policy, "")
	if expect != "":
		ok(ending_hit == expect, "policy %s expected ending %s, got '%s'" % [policy, expect, ending_hit])
	Director.stop()


func _dump_pending(ch: String) -> void:
	for b in Content.chapter(ch).get("beats", []):
		if not GameState.data.beats_done.has(b.id) and not GameState.data.running.has(b.id):
			print("     pending beat %s when %s" % [b.id, b.when])


func _choose(policy: String, thread: String, pending: Dictionary) -> int:
	var prefs: Dictionary = _walk.get("choices", {}).get(policy, {})
	var want = prefs.get(pending.id, null)
	if want == null:
		want = _walk.get("choices", {}).get("default", {}).get(pending.id, null)
	var idx: int = pending.options[0].index
	if want != null:
		for o in pending.options:
			if o.index == int(want):
				idx = o.index
	if _log_choices:
		print("     choice %s -> %d" % [pending.id, idx])
	return idx


func _auto_player(ch: String, policy: String) -> void:
	# read every thread, open every app once, view photos
	for th in GameState.data.threads:
		GameState.mark_read(th)
	for app_id in Phone.APPS:
		GameState.data.chapter_opened[app_id] = 1
		GameState.data.opened[app_id] = 1
	var steps: Dictionary = _walk.get("chapters", {}).get(ch, {})
	var all_steps: Array = steps.get("all", []) + steps.get(policy, [])
	for st in all_steps:
		var kind: String = st[0]
		var arg: String = str(st[1])
		match kind:
			"view":
				if GameState.data.photos.has(arg) and not GameState.data.viewed.has(arg):
					GameState.data.viewed[arg] = 1
			"meta":
				if GameState.data.photos.has(arg):
					GameState.set_var("meta_" + arg, true)
					for c in Content.get_item("photos", arg).get("meta_clues", []):
						Director.add_clue(c, true)
			"hotspot":
				var parts := arg.split(":")
				if GameState.data.photos.has(parts[0]):
					Director.add_clue(parts[1], true)
			"search":
				var nq := Browserish.normalize(arg)
				if not GameState.data.browser.searched.has(nq):
					GameState.data.browser.searched[nq] = true
			"visit":
				if BrowserCheck.available(arg) and not GameState.data.browser.visited.has(arg):
					GameState.data.browser.visited[arg] = 1
					var pg := Content.get_item("pages", arg)
					if pg.get("password", "") != "":
						GameState.set_var("unlocked_page_" + arg, true)
					for c in pg.get("clues", []):
						Director.add_clue(c, true)
			"file":
				if GameState.data.files.has(arg) and not GameState.data.files_opened.has(arg):
					GameState.data.files_opened[arg] = 1
					var fd := Content.get_item("files", arg)
					if fd.get("type", "") == "archive":
						GameState.set_var("extracted_" + arg, true)
						for c in fd.get("contains", []):
							if not GameState.data.files.has(c):
								GameState.data.files.append(c)
					for c in fd.get("clues", []) + fd.get("clues_end", []):
						Director.add_clue(c, true)
					GameState.set_var("heard_" + arg, true)
			"email":
				if Director.has_email(arg) and not GameState.data.emails_read.has(arg):
					GameState.data.emails_read[arg] = true
					for c in Content.get_item("emails", arg).get("clues", []):
						Director.add_clue(c, true)
			"note":
				if GameState.data.notes.has(arg):
					GameState.set_var("read_note_" + arg, true)
					for c in Content.get_item("notes", arg).get("clues", []):
						Director.add_clue(c, true)
			"flag":
				GameState.set_var(arg, true)
			"phone":
				GameState.data.phone[arg] = true
			"call":
				if not GameState.flag("_called_" + ch + "_" + arg) and not Director.in_call:
					GameState.set_var("_called_" + ch + "_" + arg, true)
					Director.player_call(arg)
			"loc":
				GameState.set_var("viewed_loc_" + arg, true)
				for c in Content.all("map").get("locations", {}).get(arg, {}).get("clues", []):
					Director.add_clue(c, true)
			"clue":
				Director.add_clue(arg, true)
			"camera":
				GameState.set_var("cam_" + arg + "_seen", true)
				GameState.set_var("cam_" + arg + "_done", true)
				GameState.data.camera.armed = ""
			"deduce":
				if not GameState.flag("deduction_done"):
					for kv in arg.split(","):
						var p := kv.split("=")
						GameState.data.deduction[p[0]] = p[1]
					var score := 0
					for q in Content.all("chapters_meta").deduction.questions:
						if str(GameState.data.deduction.get(q.id, "")) == str(q.answer):
							score += 1
					GameState.set_var("deduction_score", score)
					GameState.set_var("deduction_done", true)
			"pin":
				GameState.data.phone.pin_required = false
				GameState.set_var("pin_ok", true)
			"tag":
				var tp := arg.split("=")
				if GameState.data.clues.has(tp[0]):
					GameState.data.clues[tp[0]].tag = tp[1]


class Browserish:
	static func normalize(s: String) -> String:
		var b = load("res://scripts/phone/apps/browser_app.gd")
		return b.normalize(s)


class BrowserCheck:
	static func available(pid: String) -> bool:
		var b = load("res://scripts/phone/apps/browser_app.gd")
		return b.page_available(pid)
