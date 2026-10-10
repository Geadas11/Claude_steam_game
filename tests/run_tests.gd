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
	if _only == "" or _only == "world":
		await _test_world()
	if _only == "" or _only == "presence":
		await _test_presence()
	if _only == "ui":
		await _playthrough("A")
		await _ui_smoke("A")
	if _only == "" or _only == "play":
		var policies := ["A", "B", "C", "D", "E", "F"] if _only == "" else [_policy]
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
			ok(op.thread == "aqui" or Content.has_item("characters", op.thread), "%s: choice thread %s" % [where, op.thread])
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
	ok(GameState.data.chapter == Content.chapter_order[0], "chapter restored")
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
	var dup := ended_chapters.filter(func(c): return ended_chapters.count(c) > 1)
	ok(dup.is_empty(), "policy %s: no chapter ends twice %s" % [policy, dup])
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
	var page := await _http_get("/?k=x")
	ok(page.contains("200 OK") and page.contains("Ainda estás acordado?"), "page served over HTTP")
	ok(page.contains(":%d/" % Companion.ws_port) and not page.contains("__WS_PORT__"), "page knows the websocket port")
	ok((await _http_get("/manifest.webmanifest")).contains("fullscreen"), "page can be added to the home screen (manifest)")
	# a stand-in for the in-game phone, rendered off-screen and streamed
	var vp := SubViewport.new()
	vp.size = Vector2i(300, 400)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var root := Control.new()
	root.size = Vector2(300, 400)
	vp.add_child(root)
	var clicked := [0]
	var b := Button.new()
	b.text = "ok"
	b.position = Vector2(20, 20)
	b.size = Vector2(120, 60)
	b.pressed.connect(func(): clicked[0] += 1)
	root.add_child(b)
	var le := LineEdit.new()
	le.position = Vector2(20, 120)
	le.size = Vector2(200, 40)
	root.add_child(le)
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 200)
	sc.size = Vector2(300, 200)
	root.add_child(sc)
	var tall := VBoxContainer.new()
	tall.custom_minimum_size = Vector2(280, 1200)
	sc.add_child(tall)
	Companion.stream_vp = vp
	Companion.stream_changed()
	# a phone with the right code gets the screen and frames
	var ws := WebSocketPeer.new()
	ws.connect_to_url("ws://127.0.0.1:%d/" % Companion.ws_port)
	var got := {"screen": false, "frame": false, "kbd": false}
	var said_hello := false
	for i in 400:
		await _frames(1)
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			if not said_hello:
				ws.send_text(JSON.stringify({"t": "hello", "k": Companion.token}))
				said_hello = true
			while ws.get_available_packet_count() > 0:
				var pk := ws.get_packet()
				if ws.was_string_packet():
					var e = JSON.parse_string(pk.get_string_from_utf8())
					if typeof(e) == TYPE_DICTIONARY and e.get("t", "") == "screen" and e.get("on", false) and int(e.w) == 300:
						got.screen = true
				elif pk.size() > 2 and pk[0] == 0xFF and pk[1] == 0xD8:
					got.frame = true
		if got.screen and (got.frame or (DisplayServer.get_name() == "headless" and i > 60)):
			break
	ok(got.screen, "phone learns the size of the streamed screen")
	# (the headless test runner has no renderer, so it cannot capture frames)
	ok(got.frame or DisplayServer.get_name() == "headless", "phone receives the phone screen as JPEG frames")
	ok(Companion.client_count() == 1, "one phone connected")
	# a tap on the real phone presses the button of the in-game phone
	var send := func(o: Dictionary): ws.send_text(JSON.stringify(o))
	send.call({"t": "touch", "a": "down", "x": 80.0 / 300, "y": 50.0 / 400})
	send.call({"t": "touch", "a": "up", "x": 80.0 / 300, "y": 50.0 / 400})
	for i in 30:
		await _frames(1)
		ws.poll()
	ok(clicked[0] == 1, "a tap on the phone presses the button under the finger (%d)" % clicked[0])
	# a drag inside a long list scrolls it and clicks nothing
	send.call({"t": "touch", "a": "down", "x": 0.5, "y": 380.0 / 400})
	for k in 6:
		send.call({"t": "touch", "a": "move", "x": 0.5, "y": (380.0 - k * 30.0) / 400})
	send.call({"t": "touch", "a": "up", "x": 0.5, "y": 230.0 / 400})
	for i in 30:
		await _frames(1)
		ws.poll()
	ok(sc.scroll_vertical > 100, "dragging a list scrolls it (%d)" % sc.scroll_vertical)
	# typing: focusing a text field opens the phone's keyboard; text comes back
	le.grab_focus()
	for i in 60:
		await _frames(1)
		ws.poll()
		while ws.get_available_packet_count() > 0:
			var pk2 := ws.get_packet()
			if ws.was_string_packet():
				var e2 = JSON.parse_string(pk2.get_string_from_utf8())
				if typeof(e2) == TYPE_DICTIONARY and e2.get("t", "") == "kbd" and e2.get("on", false):
					got.kbd = true
		if got.kbd:
			break
	ok(got.kbd, "a focused text field opens the keyboard on the phone")
	send.call({"t": "text", "value": "olá"})
	for i in 20:
		await _frames(1)
		ws.poll()
	ok(le.text == "olá", "what is typed on the phone reaches the field (%s)" % le.text)
	# the back gesture
	var backs := [0]
	var old_back: Callable = Companion.on_back
	Companion.on_back = func(): backs[0] += 1
	send.call({"t": "back"})
	for i in 20:
		await _frames(1)
		ws.poll()
	ok(backs[0] == 1, "the phone's back gesture reaches the game")
	Companion.on_back = old_back
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
	Companion.stream_vp = null
	vp.queue_free()
	Companion.stop()
	Director.stop()


func _http_get(path: String) -> String:
	var http := StreamPeerTCP.new()
	http.connect_to_host("127.0.0.1", Companion.http_port)
	var page := ""
	for i in 300:
		await _frames(1)
		http.poll()
		if http.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			if page == "":
				http.put_data(("GET %s HTTP/1.1\r\nHost: test\r\n\r\n" % path).to_utf8_buffer())
				page = " "
			var n := http.get_available_bytes()
			if n > 0:
				page += http.get_utf8_string(n)
		elif page.length() > 1:
			break
	return page


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
## The 3D house: it builds, Daniel walks and is stopped by walls, doors open,
## the front door stays locked, switches and the fusebox work, examining
## things tells the story (w_<id>), and story "world" commands reach it.
func _test_world() -> void:
	print("-- world")
	Director.new_game()
	GameState.in_game = true
	var w := GameWorld.new()
	add_child(w)
	var hud_parent := Control.new()
	add_child(hud_parent)
	w.attach_hud(hud_parent)
	w.set_active(true)
	await _physics(3)
	var h := w.house
	ok(h.rooms.size() >= 7, "house has its rooms' lights (%d)" % h.rooms.size())
	ok(h.doors.size() == 6, "six doors (%d)" % h.doors.size())
	ok(h.hotspots.keys().any(func(k): return str(k).begins_with("window_sala")), "hotspot window_sala")
	for id in ["bookshelf", "laptop", "fridge", "calendar", "pills", "alarm_clock", "fusebox", "peephole", "wardrobe"]:
		ok(h.hotspots.has(id), "hotspot " + id)
	ok(h.texts.has("window_sala") and h.texts.size() > 15, "house texts loaded")
	# walking: one second forward down the corridor (towards -x)
	var p := w.player
	p.global_position = Vector3(8.5, 0.02, 5.15)
	p.set_view(90.0)
	await _physics(2)
	var x0 := p.global_position.x
	Input.action_press("move_forward")
	await _physics(60)
	Input.action_release("move_forward")
	await _physics(10)
	ok(x0 - p.global_position.x > 0.8, "walks forward (%.2f m)" % (x0 - p.global_position.x))
	# the place he starts in is free to move
	w.spawn("sofa")
	await _physics(2)
	var s0 := p.global_position
	Input.action_press("move_back")
	await _physics(30)
	Input.action_release("move_back")
	ok(p.global_position.distance_to(s0) > 0.3, "not stuck where he starts")
	ok(absf(p.global_position.y) < 0.2, "stays on the floor (y=%.2f)" % p.global_position.y)
	# walls: walk north into the window wall for 4 s, must stop inside
	p.global_position = Vector3(4.8, 0.02, 1.0)
	p.set_view(0.0)
	Input.action_press("move_forward")
	await _physics(240)
	Input.action_release("move_forward")
	ok(p.global_position.z > 0.15, "the wall stops him (z=%.2f)" % p.global_position.z)
	# mouse look still works with a full-screen Control on top (the bug: the
	# root Control swallowed every mouse motion before it reached the camera)
	var cover := Control.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_parent.add_child(cover)
	p.force_look = true
	p.look_enabled = true
	var yaw0 := p.yaw_deg()
	var mm := InputEventMouseMotion.new()
	mm.relative = Vector2(-200, -60)
	mm.position = Vector2(400, 300)
	Input.parse_input_event(mm)
	await _frames(3)
	ok(absf(p.yaw_deg() - yaw0) > 10.0, "mouse turns the camera (yaw %.1f -> %.1f)" % [yaw0, p.yaw_deg()])
	ok(p.head.rotation.x > 0.1, "mouse tilts the camera up (%.2f)" % p.head.rotation.x)
	p.force_look = false
	cover.queue_free()
	p.set_view(-90.0)
	# running drains stamina, crouching lowers the head
	p.global_position = Vector3(1.0, 0.02, 5.15)
	p.set_view(-90.0)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _physics(90)
	Input.action_release("sprint")
	Input.action_release("move_forward")
	ok(p.stamina < 0.8, "running tires him (stamina %.2f)" % p.stamina)
	Input.action_press("crouch")
	await _physics(40)
	ok(p.head.position.y < 1.3, "crouching lowers the eyes (%.2f)" % p.head.position.y)
	Input.action_release("crouch")
	await _physics(40)
	ok(p.head.position.y > 1.5, "stands back up (%.2f)" % p.head.position.y)
	# aim at the bathroom door from the corridor and use it
	var wc: Door = h.doors.wc
	wc.set_open(false, true)
	p.global_position = Vector3(6.55, 0.02, 5.15)
	p.set_view(180.0, -10.0)
	await _physics(3)
	ok(p.target == wc, "aims at the bathroom door (prompt '%s')" % p.target_prompt)
	p.use_target()
	ok(wc.is_open, "the door opens")
	# the front door is locked and says so
	var said := [""]
	p.thought.connect(func(t): said[0] = t)
	h.doors.entrada.interact(p)
	ok(not h.doors.entrada.is_open and said[0] != "", "front door stays locked ('%s')" % said[0])
	# examining something marks it for the story
	said[0] = ""
	h.hotspots.calendar.interact(p)
	ok(GameState.flag("w_calendar") and said[0].contains("14"), "calendar: thought + w_calendar")
	GameState.set_var("dinner", "massa")
	h.hotspots.fridge.interact(p)
	ok(said[0].contains("atum"), "the fridge remembers dinner ('%s')" % said[0])
	# switches and the fusebox
	h.set_room_light("cozinha", false)
	ok(not h.rooms.cozinha.lights[0].visible, "kitchen light off")
	h.set_room_light("cozinha", true)
	ok(h.rooms.cozinha.lights[0].visible, "kitchen light on")
	h.set_power(false)
	ok(not h.rooms.cozinha.lights[0].visible and not h.tv_on, "fusebox kills every light and the TV")
	h.set_power(true)
	ok(h.rooms.cozinha.lights[0].visible, "power back, kitchen remembered its switch")
	# story commands reach the house
	GameState.set_var("_x", 0)
	var op := {"name": "world", "args": ["lights", "off", "cozinha"]}
	await Director._do_cmd(op, Director._gen)
	ok(not h.rooms.cozinha.on, "story: world lights off cozinha")
	await Director._do_cmd({"name": "world", "args": ["door", "wc", "close"]}, Director._gen)
	ok(not wc.is_open, "story: world door wc close")
	# knocks are heard at the front door, not in the ears
	Audio.muted_for_tests = false
	var before := w.get_child_count()
	Audio.play("knock")
	ok(w.get_child_count() == before + 1, "knock plays in the room")
	Audio.muted_for_tests = true
	# a door that shuts only when he isn't looking (R10), with a thought when he finds it
	var dq: Door = h.doors.quarto
	dq.set_open(true, true)
	p.global_position = Vector3(4.0, 0.02, 5.15)
	p.set_view(-90.0)   # looking down the corridor at the bedroom door
	await _physics(2)
	await Director._do_cmd({"name": "world", "args": ["door", "quarto", "shut_unseen", "Deixei-a", "aberta."]}, Director._gen)
	await _frames(10)
	ok(dq.is_open, "watched, the bedroom door stays open")
	p.set_view(90.0)
	await _frames(10)
	ok(not dq.is_open, "back turned, it shuts")
	said[0] = ""
	dq.interact(p)
	ok(said[0] == "Deixei-a aberta.", "finding it shut, he thinks it ('%s')" % said[0])
	var decals0 := h.find_children("*", "Decal", true, false).size()
	await Director._do_cmd({"name": "world", "args": ["printnear", "0.9"]}, Director._gen)
	ok(h.find_children("*", "Decal", true, false).size() >= decals0 + 2, "wet footprints behind him")
	# the peephole
	w.peek(true)
	ok(w.peeping and not p.move_enabled, "looking through the peephole")
	w.peek(false)
	ok(not w.peeping, "back from the peephole")
	# every place builds, every spawn stands, every hiding place works, and
	# the floor bakes into a navigation mesh (what the presence walks on)
	for id in ["livraria", "clinica", "caminho", "rui", "casa"]:
		ok(w.go_to(id), "go_to " + id)
		await _physics(3)
		var loc: Location = w.location
		ok(loc.loc_id == id and not loc.spawns.is_empty(), "%s: built with spawns (%d)" % [id, loc.spawns.size()])
		for sp in loc.spawns:
			w.spawn(sp)
			var y0: float = loc.spawns[sp][0].y
			await _physics(20)
			ok(absf(p.global_position.y - y0) < 0.3, "%s: stands at spawn %s (y %.2f -> %.2f)" % [id, sp, y0, p.global_position.y])
		var unread := loc.hotspots.keys().filter(func(k): return not loc.texts.has(k) and not (loc.hotspots[k] is Door) and not (loc.hotspots[k] is Hotspot and loc.hotspots[k].dynamic_prompt.is_valid()))
		ok(id == "casa" or unread.is_empty(), "%s: every hotspot has words %s" % [id, unread])
		for spot in loc.hides:
			w.hide_in(spot)
			var hid: bool = w.hiding == spot
			w.unhide()
			ok(hid and w.hiding.is_empty() and p.visible, "%s: hides in %s and gets out" % [id, spot.id])
		loc.bake_navigation()
		ok(loc.nav.navigation_mesh.get_polygon_count() > 20, "%s: navigation mesh (%d polygons)" % [id, loc.nav.navigation_mesh.get_polygon_count()])
	ok(w.go_to("cais") and w.location.loc_id == "caminho", "cais is the road's quay")
	w.go_to("casa", "sofa")
	w.set_active(false)
	ok(not Audio.spatial.is_valid(), "inactive house releases the sound hook")
	w.queue_free()
	hud_parent.queue_free()
	GameState.in_game = false


## The thing (rules R2–R11): what draws it, what keeps it off, that it opens
## doors, leaves wet prints, changes things out of sight with a sound, never
## kills by day, searches a hiding place and gives up, and that being caught
## starts the chapter again with a mark (Main).
func _test_presence() -> void:
	print("-- presence")
	Saves.use_test_dir("_presence_%d" % OS.get_process_id())
	Director.new_game()
	GameState.in_game = true
	var w := GameWorld.new()
	add_child(w)
	var hud_parent := Control.new()
	add_child(hud_parent)
	w.attach_hud(hud_parent)
	w.set_active(true)
	w.set_hour(2.0)
	await _physics(3)
	var pr := w.presence
	var h := w.location
	ok(h.nav != null and h.nav.navigation_mesh.get_polygon_count() > 20, "the house has a floor for it")
	for id in h.rooms:
		h.set_room_light(id, false)
	pr._change_t = 1e9   # random changes (lights, doors) would make these checks a lottery
	pr.configure("ch05")
	ok(pr.form == "substituido" and pr.can_kill() and pr.walks(), "ch05 at night: walks, can kill")
	var p := w.player
	var caught := [false]
	pr.caught.connect(func(_a): caught[0] = true)
	# what draws it: the lit phone in the dark
	w.spawn("sofa")
	pr.screen_on = true
	await _physics(90)
	var a1 := pr.attention
	ok(a1 > 2.0, "the phone in the dark draws it (%.1f)" % a1)
	# what keeps it off: light, the phone away
	pr.screen_on = false
	h.set_room_light("sala", true)
	await _physics(60)
	ok(pr.attention < a1, "light and the phone away calm it (%.1f -> %.1f)" % [a1, pr.attention])
	# no deaths by day (R6), not even when it is close
	w.set_hour(13.0)
	ok(not pr.can_kill() and not pr.walks(), "by day it does not walk or kill")
	pr.attention = 95.0
	await _physics(30)
	ok(not pr.body.visible and not caught[0], "by day: nothing to see")
	w.set_hour(2.0)
	for id in h.rooms:
		h.set_room_light(id, false)
	# hunting in the dark: it comes through the flat and reaches him
	Engine.time_scale = 3.0
	p.global_position = Vector3(1.2, 0.02, 1.2)
	p.set_view(0.0)
	pr.attention = 0.0
	pr._set_state(Presence.State.AWAY)
	pr.story_cmd(["hunt", "60"])
	await _physics(4)
	ok(pr.state == Presence.State.HUNT, "story can send it (state %s)" % pr.state_name())
	ok(pr.pos.y > -40.0 and pr.pos.distance_to(p.global_position) > 4.0, "it starts out of sight (%.1f m)" % pr.pos.distance_to(p.global_position))
	var t := 0
	while not caught[0] and t < 900:
		await _physics(1)
		t += 1
	ok(caught[0], "in the dark it reaches him (%d frames)" % t)
	ok(int(GameState.get_var("w_caught", 0)) == 1, "w_caught counted")
	# light keeps it off (R5): under the lamp, with it hunting, nothing happens
	pr.held = false
	caught[0] = false
	h.set_room_light("sala", true)
	p.global_position = Vector3(2.7, 0.02, 2.2)
	pr._park()
	pr.story_cmd(["hunt", "60"])
	t = 0
	while not caught[0] and t < 500:
		await _physics(1)
		t += 1
	ok(not caught[0], "under the light it never reaches him (dist %.1f, state %s)" % [pr.pos.distance_to(p.global_position), pr.state_name()])
	# a chapter where it doesn't kill: it is there, then gone
	h.set_room_light("sala", false)
	pr.configure("ch01")
	ok(not pr.can_kill() and pr.walks(), "ch01: walks, does not kill")
	pr.story_cmd(["hunt", "60"])
	t = 0
	var w0 := int(GameState.get_var("w_glimpses", 0))
	while int(GameState.get_var("w_glimpses", 0)) == w0 and t < 900:
		await _physics(1)
		t += 1
	ok(not caught[0] and int(GameState.get_var("w_glimpses", 0)) > w0, "ch01: it comes and vanishes (%d frames, %s at %s, %.1f m)" % [t, pr.state_name(), pr.pos, pr.pos.distance_to(p.global_position)])
	ok(GameState.flag("w_footprints"), "ch01 (pegada): wet footprints on the floor")
	ok(h.find_children("*", "Decal", true, false).size() > 0, "footprint decals in the flat")
	# closed doors on its way open, and are heard
	pr.configure("ch05")
	for id in h.rooms:
		h.set_room_light(id, false)
	for d in h.doors.values():
		if not d.locked:
			d.set_open(false, true)
	p.global_position = Vector3(7.7, 0.02, 2.0)   # in the bedroom, door closed
	pr.pos = pr._on_nav(Vector3(1.5, 0.0, 6.5))  # in the kitchen
	pr.story_cmd(["stalk", "40"])
	pr._change_t = 9999.0   # no "change out of sight" opening these doors for it
	t = 0
	var opened0 := int(GameState.get_var("w_doors_opened", 0))
	while int(GameState.get_var("w_doors_opened", 0)) == opened0 and t < 900:
		await _physics(1)
		t += 1
	ok(int(GameState.get_var("w_doors_opened", 0)) > opened0, "it opens the doors in its way (%d frames, %s at %s, path %d/%d, pause %.1f, wait %.1f)" % [t, pr.state_name(), pr.pos, pr._path_i, pr._path.size(), pr._pause, pr._wait])
	# hiding: it searches, then gives up
	var spot: Dictionary = h.hides[0]
	pr.story_cmd(["calm"])
	pr.attention = 70.0
	pr._set_state(Presence.State.STALK)
	w.hide_in(spot)
	await _physics(3)
	ok(pr.state == Presence.State.SEARCH, "he hides: it searches (%s)" % pr.state_name())
	t = 0
	while pr.state == Presence.State.SEARCH and t < 1500:
		await _physics(1)
		t += 1
	ok(pr.state != Presence.State.SEARCH and not caught[0], "silent in the wardrobe, it gives up (%s, %d frames)" % [pr.state_name(), t])
	w.unhide()
	# every place: in the dark it finds its way to him (stairs, corridors, the quay)
	pr.configure("ch05")
	for id in ["livraria", "clinica", "rui", "caminho"]:
		w.go_to(id)
		w.set_hour(2.0)
		var loc: Location = w.location
		for r in loc.rooms:
			loc.set_room_light(r, false)
		for l in loc.lamps:
			l.visible = false
		await _physics(3)
		pr.held = false
		caught[0] = false
		pr._park()
		pr.attention = 0.0
		pr.story_cmd(["hunt", "60"])
		t = 0
		while not caught[0] and t < 1200:
			await _physics(1)
			t += 1
		ok(caught[0], "%s: in the dark it reaches him (%d frames, %s m)" % [id, t, snappedf(pr.pos.distance_to(p.global_position), 0.1)])
	pr.held = false
	pr.story_cmd(["calm"])
	w.go_to("casa", "sofa")
	await _physics(3)
	Engine.time_scale = 1.0
	# the place changes out of sight, with a sound where it happens (R10/R11)
	p.global_position = Vector3(1.5, 0.02, 2.0)
	p.set_view(0.0)
	var before := w.get_child_count()
	var n0 := int(GameState.get_var("w_changes", 0))
	Audio.muted_for_tests = false
	var changed := pr.change_one()
	Audio.muted_for_tests = true
	ok(changed and int(GameState.get_var("w_changes", 0)) == n0 + 1, "one thing changes out of sight")
	ok(w.get_child_count() > before, "the change is heard where it happens")
	w.set_active(false)
	w.queue_free()
	hud_parent.queue_free()
	await _frames(2)
	# caught: black, the chapter again, a mark, nobody says it (R7–R9)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main.start_new_game(false)
	await _frames(10)
	var ch := str(GameState.data.chapter)
	var t_start: float = GameState.data.chapter_start
	ok(not Saves.read_slot("chapter").is_empty(), "the chapter's start is kept")
	Clock.set_time(t_start + 3600.0)
	GameState.set_var("probe_after_start", true)
	await main._on_caught(main.world.player.global_position + Vector3(0, 0, -1))
	ok(str(GameState.data.chapter) == ch and absf(Clock.now() - t_start) < 120.0, "back at the start of %s" % ch)
	ok(not GameState.flag("probe_after_start"), "what happened after the start is gone")
	ok(int(GameState.get_var("deaths_" + ch, 0)) == 1 and GameState.flag("ja_falamos"), "the restart is remembered (deaths_%s, ja_falamos)" % ch)
	ok(main.world.active and not main.world.dying, "he can move again")
	main.queue_free()
	await _frames(2)
	GameState.in_game = false


func _physics(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


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
