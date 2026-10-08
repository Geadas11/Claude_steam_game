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
var _with_ui := false


func _ready() -> void:
	Audio.muted_for_tests = true
	var suffix := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--policy=") or a.begins_with("--only="):
			suffix += "_" + a.split("=")[1]
	Saves.use_test_dir(suffix)
	Achievements.persist = false
	Achievements.unlocked.clear()
	Achievements.endings.clear()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			_only = a.substr(7)
		elif a.begins_with("--policy="):
			_policy = a.substr(9)
		elif a == "--verbose":
			_log_choices = true
		elif a == "--ui":
			_with_ui = true
	await get_tree().process_frame
	if _only == "" or _only == "validate":
		_validate()
	if _only == "" or _only == "save":
		await _test_save_load()
	if _only == "" or _only == "validate":
		_validate_role("sofia")
	if _only == "" or _only == "companion":
		await _test_companion()
	if _only == "" or _only == "coop":
		await _test_coop_net()
	if _only == "ui":
		await _playthrough("A")
		await _ui_smoke("A")
	if _only == "" or _only == "play":
		var policies := ["A", "B", "C", "D", "E"] if _only == "" else [_policy]
		for p in policies:
			await _playthrough(p)
			if _only == "" and (p == "A" or p == "E") or _with_ui:
				await _ui_smoke(p)
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
		for x in Content.get_item("endings", e).get("extra", []):
			_check_expr(str(x.get("when", "")), "ending %s extra" % e)
	for c in clue_refs:
		ok(Content.has_item("clues", c), "clue '%s' referenced by %s is not defined" % [c, clue_refs[c]])
	# clues awarded directly from app code
	var rx := RegEx.new()
	rx.compile("add_clue\\(\"(\\w+)\"")
	var d := DirAccess.open("res://scripts/phone/apps")
	for f in d.get_files():
		if f.ends_with(".gd"):
			for m in rx.search_all(FileAccess.get_file_as_string("res://scripts/phone/apps/" + f)):
				clue_refs[m.get_string(1)] = "code " + f
	for c in Content.all("clues"):
		var cd: Dictionary = Content.get_item("clues", c)
		for r in cd.get("related", []):
			ok(Content.has_item("clues", r), "clue %s related to unknown %s" % [c, r])
		ok(clue_refs.has(c), "clue '%s' is defined but can never be awarded" % c)
	ok(Content.all("achievements").size() >= 20, "at least 20 achievements")
	for i in range(Content.chapter_order.size() - 1):
		ok(Content.chapter_recap(Content.chapter_order[i]) != "", "chapter %s has a recap" % Content.chapter_order[i])
	_check_delivery(all_beats)
	print("   validated %d beats, %d clue references" % [all_beats.size(), clue_refs.size()])


## Every photo/email/file/note/voicemail must reach the player somehow.
func _check_delivery(all_beats: Array) -> void:
	var got := {"photos": {}, "emails": {}, "files": {}, "notes": {}, "voicemails": {}}
	var cmd_kind := {"photo": "photos", "variant": "photos", "email": "emails", "file": "files", "note": "notes", "voicemail": "voicemails"}
	var att_kind := {"photo": "photos", "file": "files", "audio": "voicemails"}
	for pair in all_beats:
		for op in pair[1].ops:
			if op.op == "msg" and not op.att.is_empty() and att_kind.has(op.att.type):
				got[att_kind[op.att.type]][op.att.id] = true
			elif op.op == "cmd" and cmd_kind.has(op.name):
				got[cmd_kind[op.name]][op.args[0]] = true
	var init: Dictionary = Content.all("chapters_meta").get("initial", {})
	for k in ["photos", "emails", "files", "notes"]:
		for id in init.get(k, []):
			got[k][id] = true
	for kind in ["emails", "pages"]:
		for id in Content.all(kind):
			var d: Dictionary = Content.get_item(kind, id)
			for att in d.get("attachments", []):
				if att_kind.has(att.type):
					got[att_kind[att.type]][att.id] = true
			for blk in d.get("blocks", []):
				if blk.has("img"):
					got.photos[blk.img] = true
				if blk.has("file"):
					got.files[blk.file] = true
	for fid in Content.all("files"):
		var f: Dictionary = Content.get_item("files", fid)
		for c in f.get("contains", []):
			got.files[c] = true
		if f.has("photo"):
			got.photos[f.photo] = true
	for kind in got:
		for id in Content.all(kind):
			if kind == "photos" and str(id).begins_with("CAM_"):
				continue
			ok(got[kind].has(id), "%s '%s' is never delivered to the player" % [kind, id])


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
				for k in o.set:
					ok(not (k in ["inc", "set"]) and not str(k).is_valid_float(), "%s: option sets suspicious key '%s'" % [where, k])
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
var _app_cycle := 0


func _playthrough(policy: String) -> void:
	print("-- playthrough policy=%s" % policy)
	_walk = JSON.parse_string(FileAccess.get_file_as_string("res://tests/walkthrough.json"))
	Director.fast_mode = true
	Director.auto_answer = func(_c): return true
	Director.auto_chooser = func(thread, pending): return _choose(policy, thread, pending)
	var ended_chapters: Array = []
	var ending_box := {"id": ""}   # lambdas capture locals by value; use a reference type
	var cb_end := func(ch): ended_chapters.append(ch)
	var cb_ending := func(e): ending_box.id = e
	Events.chapter_ended.connect(cb_end)
	Events.ending_reached.connect(cb_ending)
	Director.new_game()
	var safety := 0
	var last_chapter := ""
	var stuck_frames := 0
	while ending_box.id == "" and safety < 60000:
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
			print("     flags: final=%s left_home=%s evidence_sent=%s sent_rui=%s ded=%s found_card=%s" % [GameState.get_var("final", ""), GameState.flag("left_home"), GameState.flag("evidence_sent"), GameState.flag("sent_rui"), GameState.get_var("deduction_score", -1), GameState.flag("found_card")])
			break
	Events.chapter_ended.disconnect(cb_end)
	Events.ending_reached.disconnect(cb_ending)
	print("   chapters ended: %s" % str(ended_chapters))
	var ending_hit: String = ending_box.id
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
	# policy-specific steps run first so they can pre-empt generic ones
	var all_steps: Array = steps.get(policy, []) + steps.get("all", [])
	var apps: Array = all_steps.filter(func(st): return st[0] == "app")
	if not apps.is_empty():
		_app_cycle += 1
		GameState.current_app = str(apps[_app_cycle % apps.size()][1])
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
			"app":
				pass
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


# =================================================================== UI smoke
## Opens every app and every sub-view with the rich end-of-game state, so that
## runtime errors in app code show up as SCRIPT ERRORs in the log
## (tools/run_tests.sh fails the run if any appear).
func _ui_smoke(policy: String) -> void:
	print("-- ui smoke (%s)" % policy)
	Director.stop()
	GameState.in_game = true
	var phone := Phone.new()
	add_child(phone)
	await _frames(2)
	phone.refresh_all()
	phone.unlock(true)
	for panel in [RecapPanel.new(), ChoicesPanel.new()]:
		add_child(panel)
		await _frames(2)
		ok(panel.body.get_child_count() > 0, "%s has content" % panel.get_script().get_global_name())
		panel.queue_free()
	# toasts must land inside the phone screen
	phone.toast("teste")
	await _frames(2)
	var tp: Control = phone.screen.get_node("Toast")
	ok(phone.screen.get_global_rect().encloses(tp.get_global_rect()), "toast inside the screen (%s vs %s)" % [tp.get_global_rect(), phone.screen.get_global_rect()])
	# opening straight into a conversation must report it to the story (app())
	var th0: String = GameState.data.threads.keys()[0]
	phone.open_app("messages", {"forced": true, "param": th0})
	await _frames(2)
	ok(GameState.current_app == "messages:" + th0, "open_app with thread sets app() (got %s)" % GameState.current_app)
	phone.go_home()
	await _frames(1)
	var opened := 0
	for app_id in Phone.APPS:
		phone.open_app(app_id, {"forced": true})
		await _frames(2)
		var app = phone.current_app
		ok(app != null, "app %s opened" % app_id)
		if app == null:
			continue
		opened += 1
		match app_id:
			"messages":
				for th in GameState.data.threads:
					app._open_thread(th)
					await _frames(1)
				app._show_list()
			"gallery":
				for pid in GameState.data.photo_order:
					app._show_photo(pid)
					app._meta_sheet(pid)
					await _frames(1)
			"email":
				for i in 3:
					app._folder = ["Entrada", "Enviados", "Lixo"][i]
					app._show_list()
					await _frames(1)
				for e in GameState.data.emails:
					app._show_email(e.id)
					await _frames(1)
			"files":
				phone.current_app._render()
				for fid in Content.all("files"):
					app._open_file(fid)
					await _frames(1)
			"notes":
				for t in 3:
					app._tab = t
					app._render()
					await _frames(1)
				for n in app._all_notes():
					app._show_note(n)
					await _frames(1)
			"settings":
				for pg in ["wifi", "display", "sound", "battery", "storage", "accounts", "files", "about", "dev", "dev_proc", "dev_log", "dev_eco"]:
					app._page = pg
					app._render()
					await _frames(1)
			"browser":
				for pid in Content.all("pages"):
					GameState.set_var("unlocked_page_" + pid, true)
					app.open_page(pid)
					await _frames(1)
				for q in ["ines matos", "912 403 317", "lumen", "cais velho", "nada disto existe"]:
					app._search(q)
					await _frames(1)
				app._show_history()
				app._show_start()
			"maps":
				for loc in Content.all("map").get("locations", {}):
					app.show_location(loc)
					await _frames(1)
				app._tab = 1
				app._render()
				await _frames(1)
			"phone":
				for t in 4:
					app._tab = t
					app._render()
					await _frames(1)
			"contacts":
				for c in Content.all("characters"):
					app._show_contact(c)
					await _frames(1)
			"clock":
				for t in 3:
					app._tab = t
					app._render()
					await _frames(1)
		phone.go_home()
		await _frames(1)
	phone.lock()
	await _frames(2)
	phone.queue_free()
	await _frames(2)
	ok(opened == Phone.APPS.size(), "all apps opened in ui smoke")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# ---------------------------------------------------------------- telemóvel real
func _test_companion() -> void:
	print("-- companion")
	Companion.persist_token = false
	Director.new_game()
	await _frames(5)
	ok(Companion.start(), "companion server starts")
	if not Companion.running:
		return
	ok(Companion.url().contains("?k=" + Companion.token), "pairing url carries the code")
	ok(QR.encode(Companion.url()).size() >= 21, "pairing url fits in a QR code")
	# the page over HTTP
	var http := StreamPeerTCP.new()
	http.connect_to_host("127.0.0.1", Companion.http_port)
	var page := ""
	for i in 300:
		await _frames(1)
		http.poll()
		if http.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if page == "":
				http.put_data("GET /?k=x HTTP/1.1\r\nHost: test\r\n\r\n".to_utf8_buffer())
				page = " "
			var n := http.get_available_bytes()
			if n > 0:
				page += http.get_utf8_string(n)
		elif page.length() > 1:
			break
	ok(page.contains("200 OK") and page.contains("Ainda estás acordado?"), "page served over HTTP")
	ok(page.contains(":%d/" % Companion.ws_port) and not page.contains("__WS_PORT__"), "page knows the websocket port")
	# a phone with the right code gets the state; actions reach the game
	var opened := {"app": ""}
	var on_open := func(app_id: String, p: Dictionary): opened.app = app_id + ":" + str(p.get("param", ""))
	Events.open_app_requested.connect(on_open)
	var ws := WebSocketPeer.new()
	ws.connect_to_url("ws://127.0.0.1:%d/" % Companion.ws_port)
	var state = null
	var said_hello := false
	for i in 300:
		await _frames(1)
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			if not said_hello:
				ws.send_text(JSON.stringify({"t": "hello", "k": Companion.token}))
				said_hello = true
			if ws.get_available_packet_count() > 0:
				state = JSON.parse_string(ws.get_packet().get_string_from_utf8())
				break
	ok(typeof(state) == TYPE_DICTIONARY and state.get("t", "") == "state", "phone receives the state")
	if typeof(state) == TYPE_DICTIONARY:
		ok(state.get("threads", []).size() > 0, "state lists conversations")
		ok(state.get("contacts", []).size() > 0, "state lists contacts")
		ok(state.get("home", {}).has("badges") and state.get("home", {}).has("wallpaper"), "state carries the home screen")
		ok(state.has("photos") and state.has("notes") and state.has("emails") and state.has("calls"), "state carries gallery, notes, email and calls")
	# the real photos are served as JPEG (and only with the pairing code)
	ok(Companion._photo_jpeg("IMG_2207", "base", 320).slice(0, 2) == PackedByteArray([0xFF, 0xD8]), "photos are served as JPEG")
	ok(Companion._photo_jpeg("NOPE", "base", 320).is_empty(), "unknown photos are not served")
	ok(Companion.client_count() == 1, "one phone connected")
	var th: String = GameState.data.thread_order[0]
	ws.send_text(JSON.stringify({"t": "open", "thread": th}))
	var got_msg := false
	for i in 120:
		await _frames(1)
		ws.poll()
		while ws.get_available_packet_count() > 0:
			var e = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if typeof(e) == TYPE_DICTIONARY and e.get("t", "") == "msg":
				got_msg = true
		if opened.app != "" and got_msg:
			break
	ok(opened.app == "messages:" + th, "opening a conversation on the phone opens it on the PC (%s)" % opened.app)
	opened.app = ""
	ws.send_text(JSON.stringify({"t": "open", "app": "gallery"}))
	for i in 60:
		await _frames(1)
		ws.poll()
		while ws.get_available_packet_count() > 0:
			ws.get_packet()
		if opened.app != "":
			break
	ok(opened.app.begins_with("gallery"), "opening an app on the phone opens it on the PC (%s)" % opened.app)
	GameState.add_message(th, {"from": th, "text": "teste"})
	Events.message_added.emit(th, GameState.data.threads[th].messages[-1])
	for i in 60:
		await _frames(1)
		ws.poll()
		while ws.get_available_packet_count() > 0:
			var e = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if typeof(e) == TYPE_DICTIONARY and e.get("t", "") == "msg" and e.msg.text == "teste":
				got_msg = true
	ok(got_msg, "new messages reach the phone")
	Events.open_app_requested.disconnect(on_open)
	# a wrong code is refused
	var bad := WebSocketPeer.new()
	bad.connect_to_url("ws://127.0.0.1:%d/" % Companion.ws_port)
	var sent := false
	for i in 300:
		await _frames(1)
		bad.poll()
		if bad.get_ready_state() == WebSocketPeer.STATE_OPEN and not sent:
			bad.send_text(JSON.stringify({"t": "hello", "k": "errado"}))
			sent = true
		if bad.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			break
	ok(bad.get_ready_state() == WebSocketPeer.STATE_CLOSED and Companion.client_count() == 1, "wrong code refused")
	ws.close()
	Companion.stop()
	Director.stop()


## The second player's story (co-op): same checks on its chapters.
func _validate_role(role: String) -> void:
	print("-- validate role ", role)
	Content.set_role(role)
	ok(Content.load_errors.is_empty(), "%s content loads: %s" % [role, str(Content.load_errors)])
	ok(Content.all("chapters_meta").get("initial", {}).has("contacts"), role + " has its own address book")
	for th in Content.all("chapters_meta").get("initial", {}).get("threads", {}):
		ok(not Content.character(th).is_empty(), "%s thread %s has a character" % [role, th])
	var n := 0
	for ch_id in Content.chapters:
		var ch: Dictionary = Content.chapters[ch_id]
		for b in ch.get("beats", []) + ch.get("calls", []):
			n += 1
			var key := "%s/%s:%s" % [role, ch_id, b.id]
			_check_expr(b.when, key + " @when")
			for op in b.ops:
				_check_op(op, key, {})
	ok(n > 0, role + " has beats")
	Content.set_role("daniel")


# ---------------------------------------------------------------- co-op network
func _test_coop_net() -> void:
	print("-- coop network")
	# room codes survive a round trip
	var code := RoomCode.from_address("192.168.1.42", 8517)
	var back := RoomCode.to_address(code)
	ok(back.ip == "192.168.1.42" and back.port == 8517, "room code round trip (%s)" % code)
	ok(RoomCode.to_address(code.to_lower().replace("-", " ")).ip == "192.168.1.42", "room code is forgiving (case, spaces)")
	ok(RoomCode.to_lobby(RoomCode.from_lobby(109775241234567890)) == 109775241234567890, "steam lobby code round trip")
	ok(RoomCode.to_address("ZZZ").is_empty(), "bad code rejected")
	ok(not SteamTransport.available(), "no Steam in tests: direct connection is used")
	# a host and a guest in the same process
	var host := DirectTransport.new()
	var guest := DirectTransport.new()
	var got := {"joined": false, "connected": false, "at_host": {}, "at_guest": {}, "code": ""}
	host.hosted.connect(func(c): got.code = c)
	host.partner_joined.connect(func(): got.joined = true)
	host.received.connect(func(m): got.at_host = m)
	guest.connected.connect(func(): got.connected = true)
	guest.received.connect(func(m): got.at_guest = m)
	host.host()
	ok(got.code != "", "host gets a room code")
	var port := int(RoomCode.to_address(got.code).port)
	guest.join("127.0.0.1:%d" % port)
	for i in 300:
		host.poll()
		guest.poll()
		await _frames(1)
		if got.joined and got.connected:
			break
	ok(got.joined and got.connected, "guest reaches the host")
	guest.send({"t": "hello", "x": "olá"})
	host.send({"t": "welcome", "y": 3})
	for i in 300:
		host.poll()
		guest.poll()
		await _frames(1)
		if not got.at_host.is_empty() and not got.at_guest.is_empty():
			break
	ok(got.at_host.get("x", "") == "olá", "guest → host message")
	ok(int(got.at_guest.get("y", 0)) == 3, "host → guest message")
	guest.close()
	host.close()
	# Sofia's role loads her own phone
	Content.set_role("sofia")
	Director.new_game()
	await _frames(3)
	ok(GameState.data.threads.has("daniel") and not GameState.data.threads.has("sofia"), "Sofia's phone has a conversation with Daniel")
	ok(GameState.data.contacts.has("patricia") and not GameState.data.contacts.has("vasco"), "Sofia has her own contacts")
	ok(not Saves.save_to("quick"), "the guest never writes saves")
	Director.stop()
	Content.set_role("daniel")
