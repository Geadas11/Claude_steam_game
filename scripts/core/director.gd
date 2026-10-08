extends Node
## Narrative engine. Runs the beats of the current chapter (see StoryParser).
##
## Each beat is a small program. Running beats store their program counter in
## GameState.data.running so a save taken mid-beat resumes at the same op.

signal beat_finished(beat_id: String)

const TICK := 0.25

var chapter: Dictionary = {}
var fast_mode := false          # tests: no waiting at all
var auto_chooser: Callable      # tests: func(thread, op) -> int
var auto_answer: Callable       # tests: func(call_op) -> bool
var active := false
var in_call := false
var current_call: Dictionary = {}

var _gen := 0
var _tick_acc := 0.0
var _expr_cache := {}
var _call_answer := -1          # -1 pending, 0 declined, 1 answered
var _hangup := false
var _beats_by_id := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	Events.call_response.connect(func(a: bool): _call_answer = 1 if a else 0)
	Events.call_hangup_requested.connect(func(): _hangup = true)


# =================================================================== control
func stop() -> void:
	_gen += 1
	active = false
	in_call = false
	current_call = {}
	Clock.running = false
	Audio.stop_ring()


func new_game() -> void:
	stop()
	GameState.reset()
	GameState.in_game = true
	_seed_initial_state()
	# replay memory: the voice remembers previous iterations
	var prev := 0
	for e in ["A", "B", "C", "D", "E"]:
		if Achievements.ending_seen(e):
			GameState.set_var("prev_end_" + e, true)
			prev += 1
	GameState.set_var("prev_endings", prev)
	start_chapter(Content.chapter_order[0])


func start_chapter(ch_id: String) -> void:
	_gen += 1
	var ch := Content.chapter(ch_id)
	if ch.is_empty():
		push_error("unknown chapter " + ch_id)
		return
	chapter = ch
	_index_beats()
	GameState.data.chapter = ch_id
	GameState.data.beats_done = {}
	GameState.data.running = {}
	GameState.data.choices = {}
	GameState.data.chapter_opened = {}
	GameState.data.chapter_complete = false
	GameState.clear_notifications()   # a new day: yesterday's banners are gone
	if ch.start != "":
		Clock.set_time(Clock.parse_datetime(ch.start))
	GameState.data.chapter_start = Clock.now()
	Clock.frozen_display = ""
	Clock.rate = 1.0
	active = true
	Clock.running = true
	Events.chapter_started.emit(ch_id)
	Saves.autosave()
	_evaluate()


## Called after a save is loaded: rebuild runtime structures and resume beats.
func resume_from_state() -> void:
	_gen += 1
	in_call = false
	current_call = {}
	chapter = Content.chapter(GameState.data.chapter)
	_index_beats()
	GameState.in_game = true
	active = true
	Clock.running = true
	Clock.rate = 1.0
	Clock.frozen_display = ""
	var g := _gen
	var running: Dictionary = GameState.data.running.duplicate()
	for beat_id in running:
		var b: Dictionary = _beats_by_id.get(beat_id, {})
		if b.is_empty():
			GameState.data.running.erase(beat_id)
			continue
		_run_beat(b, int(running[beat_id]), g)
	Events.state_loaded.emit()
	# a save taken between "endchapter" and the next chapter must not softlock
	if GameState.data.get("chapter_complete", false):
		_end_chapter.call_deferred()


func _index_beats() -> void:
	_beats_by_id.clear()
	for b in chapter.get("beats", []):
		_beats_by_id[b.id] = b
	for b in Content.global_script.get("beats", []):
		if not _beats_by_id.has(b.id):
			_beats_by_id[b.id] = b


func _seed_initial_state() -> void:
	# initial contacts, photos, threads, emails... from data
	for id in Content.all("characters"):
		var c: Dictionary = Content.character(id)
		if c.get("start_saved", false):
			GameState.data.contacts[id] = {"saved": true}
	var seed: Dictionary = Content.all("chapters_meta").get("initial", {})
	for pid in seed.get("photos", []):
		GameState.add_photo(pid)
	GameState.data.photo_order.reverse()
	for pid in GameState.data.photos:
		GameState.data.photos[pid].new = false
	for eid in seed.get("emails", []):
		GameState.data.emails.append({"id": eid, "t": 0.0})
		GameState.data.emails_read[eid] = true
	for fid in seed.get("files", []):
		GameState.data.files.append(fid)
	for nid in seed.get("notes", []):
		GameState.data.notes.append(nid)
	for h in seed.get("history", []):
		GameState.data.browser.history.append({"q": h, "t": 0.0, "injected": false})
	for call in seed.get("calls", []):
		GameState.data.calls.append(call.duplicate())
	for lg in seed.get("location_log", []):
		GameState.data.location_log.append(lg.duplicate())
	# old message history
	var threads: Dictionary = seed.get("threads", {})
	for th_id in threads:
		for m in threads[th_id]:
			var msg: Dictionary = m.duplicate()
			msg.t = Clock.parse_datetime(m.t)
			if not msg.has("from"):
				msg.from = th_id
			GameState.add_message(th_id, msg, false)
	# order threads by most recent message
	var order: Array = threads.keys()
	order.sort_custom(func(a, b): return _last_t(a) > _last_t(b))
	GameState.data.thread_order = order


func _last_t(th_id: String) -> float:
	var msgs: Array = GameState.data.threads.get(th_id, {}).get("messages", [])
	return float(msgs[-1].t) if not msgs.is_empty() else 0.0


# =================================================================== loop
func _process(delta: float) -> void:
	if not active:
		return
	_tick_acc += delta
	if _tick_acc >= TICK:
		_tick_acc = 0.0
		_evaluate()


func _evaluate() -> void:
	if not active:
		return
	var g := _gen
	for b in chapter.get("beats", []) + Content.global_script.get("beats", []):
		if g != _gen:
			return
		if GameState.data.running.has(b.id):
			continue
		if GameState.data.beats_done.has(b.id) and not b.repeat:
			continue
		if not check(b.when):
			continue
		_run_beat(b, 0, g)


func waiting_on_clock() -> bool:
	if not active or in_call:
		return false
	if not GameState.data.choices.is_empty():
		return false
	for b in chapter.get("beats", []):
		if GameState.data.beats_done.has(b.id):
			continue
		if GameState.data.running.has(b.id):
			return false
	for b in chapter.get("beats", []):
		if not GameState.data.beats_done.has(b.id) and b.when.contains("at("):
			return true
	return false


func notify_player_action() -> void:
	## Called by apps after player actions so beats react immediately.
	_tick_acc = TICK


# =================================================================== conditions
func check(expr_text: String) -> bool:
	if expr_text == "" or expr_text == "true":
		return true
	var e: Expression = _expr_cache.get(expr_text)
	if e == null:
		e = Expression.new()
		var err := e.parse(expr_text)
		if err != OK:
			push_error("bad condition '%s': %s" % [expr_text, e.get_error_text()])
			_expr_cache[expr_text] = e
			return false
		_expr_cache[expr_text] = e
	var r = e.execute([], self, false)
	if e.has_execute_failed():
		return false
	return bool(r)


func validate_expression(expr_text: String) -> String:
	var e := Expression.new()
	if e.parse(expr_text) != OK:
		return e.get_error_text()
	e.execute([], self, false)
	if e.has_execute_failed():
		return "execute failed: " + e.get_error_text()
	return ""


# --- functions callable from story conditions -------------------------------
func flag(n: String) -> bool: return GameState.flag(n)
func v(n: String): return GameState.get_var(n, 0)
func vs(n: String) -> String: return str(GameState.get_var(n, ""))
func beat(id: String) -> bool: return GameState.data.beats_done.has(id)
func running(id: String) -> bool: return GameState.data.running.has(id)
func started(id: String) -> bool: return GameState.data.beats_done.has(id) or GameState.data.running.has(id)
func since(id: String, secs: float) -> bool:
	if not GameState.data.beats_done.has(id):
		return false
	if fast_mode:
		return true
	return float(GameState.data.playtime) - float(GameState.data.beats_done[id]) >= secs / _pace()
func at(hhmm: String) -> bool:
	return Clock.now() >= Clock.next_occurrence(hhmm, float(GameState.data.chapter_start))
func read(th: String) -> bool:
	return GameState.data.threads.has(th) and GameState.thread_unread(th) == 0
func unread(th: String) -> bool: return GameState.thread_unread(th) > 0
func clue(id: String) -> bool: return GameState.has_clue(id)
func clues() -> int: return GameState.clue_count()
func viewed(pid: String) -> bool: return GameState.data.viewed.has(pid)
func visited(page: String) -> bool: return GameState.data.browser.visited.has(page)
func searched(term: String) -> bool:
	var t := term.to_lower()
	for q in GameState.data.browser.searched:
		if q.contains(t):
			return true
	return false
func opened(app_id: String) -> bool: return GameState.data.chapter_opened.has(app_id)
func ever_opened(app_id: String) -> bool: return GameState.data.opened.has(app_id)
func app() -> String: return GameState.current_app
func email_read(id: String) -> bool: return GameState.data.emails_read.has(id)
func file_open(id: String) -> bool: return GameState.data.files_opened.has(id)
func called(who: String) -> int: return int(GameState.data.called.get(who, 0))
func loc(id: String) -> bool: return GameState.data.location == id
func tag(clue_id: String) -> String: return str(GameState.data.clues.get(clue_id, {}).get("tag", ""))
func ded(q: String) -> String: return str(GameState.data.deduction.get(q, ""))
func tagged() -> int:
	var n := 0
	for c in GameState.data.clues.values():
		if str(c.get("tag", "")) != "":
			n += 1
	return n
func answered(call_id: String) -> bool: return GameState.get_var("call_" + call_id, "") == "answered"
func missed(call_id: String) -> bool:
	var s = GameState.get_var("call_" + call_id, "")
	return s == "missed" or s == "declined"
func has_photo(pid: String) -> bool: return GameState.data.photos.has(pid)
func has_msg(th: String, mid: String) -> bool: return not GameState.find_message(th, mid).is_empty()
func photo_is(pid: String, variant: String) -> bool: return GameState.photo_variant(pid) == variant
func has_file(fid: String) -> bool: return GameState.data.files.has(fid)
func has_email(eid: String) -> bool:
	for e in GameState.data.emails:
		if e.id == eid:
			return true
	return false
func phone(key: String): return GameState.data.phone.get(key, false)
func hour() -> int: return Clock.hour()
func ending_seen(id: String) -> bool: return Achievements.ending_seen(id)


# =================================================================== beats
func _pace() -> float:
	return clampf(float(Settings.get_value("text_speed", 1.0)), 0.25, 4.0)


func _sleep(secs: float, g: int) -> bool:
	## Returns false if the game was reloaded/stopped while waiting.
	if fast_mode or secs <= 0.0:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(secs / _pace(), false).timeout
	return g == _gen


func _run_beat(b: Dictionary, start_pc: int, g: int) -> void:
	GameState.data.running[b.id] = start_pc
	var ops: Array = b.ops
	var pc := start_pc
	while pc < ops.size():
		if g != _gen:
			return
		GameState.data.running[b.id] = pc
		var op: Dictionary = ops[pc]
		var next := pc + 1
		match op.op:
			"jif":
				if not check(op.expr):
					next = op.to
			"jmp":
				next = op.to
			"wait":
				if not await _sleep(op.s, g):
					return
			"set":
				for k in op.vals:
					GameState.set_var(k, op.vals[k])
			"inc":
				GameState.inc_var(op.key, op.n)
			"msg":
				if not await _do_msg(op, g):
					return
			"choice":
				var ok = await _do_choice(op, b.id, pc, g)
				if not ok:
					return
			"call":
				if not await _do_call(op, g):
					return
			"line", "sfx":
				if not await _do_call_line(op, g):
					return
			"cmd":
				if not await _do_cmd(op, g):
					return
		if g != _gen:
			return
		pc = next
	GameState.data.running.erase(b.id)
	GameState.data.beats_done[b.id] = float(GameState.data.playtime)
	beat_finished.emit(b.id)
	notify_player_action()


# --- messages -----------------------------------------------------------------
## Replaces ${var} with the value of a story variable (e.g. ${last_reply}).
func interp(text: String) -> String:
	if not text.contains("${"):
		return text
	var out := text
	var guard := 0
	while out.contains("${") and guard < 10:
		guard += 1
		var a := out.find("${")
		var b := out.find("}", a)
		if b == -1:
			break
		var key := out.substr(a + 2, b - a - 2)
		out = out.substr(0, a) + str(GameState.get_var(key, "")) + out.substr(b + 1)
	return out


func typing_time(text: String) -> float:
	return clampf(0.7 + text.length() * 0.035, 0.9, 4.5)


func _do_msg(op: Dictionary, g: int) -> bool:
	var opts: Dictionary = op.opts
	var thread: String = op.thread
	var from: String = op.from
	if thread == "":
		return true
	if from != "me" and not opts.get("instant", false) and not opts.has("time") and not opts.has("date"):
		var tt: float = float(opts.get("typing", typing_time(op.text)))
		Events.thread_typing.emit(thread, from, true)
		var ok := await _sleep(tt, g)
		Events.thread_typing.emit(thread, from, false)
		if not ok:
			return false
	elif from == "me" and opts.get("auto", false):
		Events.autotype_requested.emit(thread, op.text)
		if not await _sleep(typing_time(op.text) * 0.8, g):
			return false
	var msg := {"id": op.id, "from": from, "text": interp(op.text), "t": Clock.now()}
	if not op.att.is_empty():
		msg.att = op.att.duplicate()
	if opts.has("time"):
		msg.t = _backdate(str(opts.time))
	if opts.has("date"):
		msg.t = Clock.parse_datetime(str(opts.date))
	if opts.get("deleted", false):
		msg.del = true
	if opts.get("unknown", false):
		msg.unknown = true
	var silent: bool = opts.get("silent", false)
	var added := GameState.add_message(thread, msg, not silent)
	if not added.is_empty() and added.get("t", 0) != msg.t and op.id != "":
		pass # already existed (resume) — nothing to announce
	if from != "me" and not silent:
		if added.has("att") and added.att.type == "photo":
			GameState.add_photo(added.att.id, "Mensagens")
			Events.content_changed.emit("photos")
		_announce_message(thread, added)
	Events.message_added.emit(thread, added)
	return true


func _backdate(hhmm: String) -> float:
	## A time earlier today (or yesterday if that time hasn't happened yet).
	var t := Clock.next_occurrence(hhmm, Clock.now())
	if t > Clock.now():
		t -= 86400.0
	return t


func _announce_message(thread: String, msg: Dictionary) -> void:
	var title := GameState.contact_name(thread)
	if Content.character(thread).get("group", false):
		title = "%s · %s" % [GameState.contact_name(thread), GameState.contact_name(msg.from)]
	var body: String = msg.text
	if msg.has("att"):
		match msg.att.type:
			"photo": body = "Fotografia" if body == "" else "Fotografia · " + body
			"audio": body = "Mensagem de voz"
			"link": body = body if body != "" else "Ligação"
			"file": body = "Ficheiro"
	if msg.get("del", false):
		body = "Esta mensagem foi apagada"
	var n := GameState.post_notification("messages", title, body, {"thread": thread, "t": float(msg.t)})
	Events.notification_posted.emit(n)


# --- choices ------------------------------------------------------------------
func _do_choice(op: Dictionary, beat_id: String, pc: int, g: int) -> bool:
	var options: Array = []
	for i in op.options.size():
		var o: Dictionary = op.options[i]
		if o.cond == "" or check(o.cond):
			var oo := o.duplicate()
			oo.index = i
			options.append(oo)
	if options.is_empty():
		return true
	# one question at a time per conversation: wait for an earlier beat's
	# choice in this thread to be answered before offering ours
	while GameState.data.choices.has(op.thread):
		var other: Dictionary = GameState.data.choices[op.thread]
		if other.get("id", "") == op.id or not GameState.data.running.has(other.get("beat", "")):
			break
		await Events.choice_made
		if g != _gen:
			return false
	var pending := {"id": op.id, "beat": beat_id, "pc": pc, "options": options}
	GameState.data.choices[op.thread] = pending
	Events.choice_offered.emit(op.thread)
	var chosen := -1
	if auto_chooser.is_valid():
		await get_tree().process_frame
		if g != _gen:
			return false
		chosen = int(auto_chooser.call(op.thread, pending))
	else:
		while true:
			var res: Array = await Events.choice_made
			if g != _gen:
				return false
			if res[0] == op.thread and res[1] == op.id:
				chosen = res[2]
				break
	if g != _gen:
		return false
	var opt: Dictionary = {}
	for o in options:
		if o.index == chosen:
			opt = o
	if opt.is_empty():
		opt = options[0]
	GameState.data.choices.erase(op.thread)
	Events.choice_cleared.emit(op.thread)
	for k in opt.set:
		GameState.set_var(k, opt.set[k])
	for k in opt.get("inc", {}):
		GameState.inc_var(k, float(opt.inc[k]))
	GameState.set_var("choice_" + op.id, opt.index)
	if not (opt.text.begins_with("[") and opt.text.ends_with("]")):
		GameState.set_var("last_reply", opt.text)
	GameState.data.choice_log.append({"id": op.id, "option": opt.index, "text": opt.text, "chapter": GameState.data.chapter})
	var text: String = opt.text
	if not (text.begins_with("[") and text.ends_with("]")):
		Events.autotype_requested.emit(op.thread, text)
		if not await _sleep(minf(0.4 + text.length() * 0.03, 2.2), g):
			return false
		var msg := GameState.add_message(op.thread, {"from": "me", "text": text, "t": Clock.now()}, false)
		Audio.play("sent")
		Events.message_added.emit(op.thread, msg)
	Events.choice_made.emit(op.thread, "__resolved__", opt.index)
	notify_player_action()
	return true


## Used by the Messages UI.
func pick_choice(thread: String, option_index: int) -> void:
	var pending: Dictionary = GameState.data.choices.get(thread, {})
	if pending.is_empty():
		return
	Events.choice_made.emit(thread, pending.id, option_index)


# --- calls --------------------------------------------------------------------
func _do_call(op: Dictionary, g: int) -> bool:
	while in_call:
		if not await _sleep(0.5, g):
			return false
	var outgoing: bool = op.get("outgoing", false)
	var call := {"id": op.id, "who": op.who, "dir": "out" if outgoing else "in", "unknown": op.unknown, "number": op.number, "t": Clock.now()}
	in_call = true
	current_call = call
	_call_answer = -1
	_hangup = false
	if outgoing:
		_call_answer = 1
		Events.call_started.emit(call)
		Audio.start_dialtone()
		if not await _sleep(2.5, g):
			Audio.stop_ring()
			in_call = false
			return false
	else:
		Events.call_incoming.emit(call)
		Audio.start_ring(op.unknown or op.who == "ines" or op.who == "eco" or op.who == "unknown")
	var waited := 0.0
	if op.autoanswer:
		_call_answer = 1
	if auto_answer.is_valid():
		_call_answer = 1 if auto_answer.call(op) else 0
	while _call_answer == -1 and waited < op.ring:
		if not await _sleep(0.1, g):
			Audio.stop_ring()
			in_call = false
			return false
		if not fast_mode:
			waited += 0.1 / _pace()
		else:
			waited += 1.0
		if not op.missable:
			waited = 0.0
	Audio.stop_ring()
	if _call_answer != 1:
		var status := "declined" if _call_answer == 0 else "missed"
		GameState.set_var("call_" + op.id, status)
		_log_call(call, "missed", 0)
		call.result = status
		in_call = false
		current_call = {}
		Events.call_ended.emit(call)
		var n := GameState.post_notification("phone", "Chamada perdida", _caller_label(call))
		Events.notification_posted.emit(n)
		return true
	GameState.set_var("call_" + op.id, "answered")
	if not outgoing:
		Events.call_started.emit(call)
	Audio.play("call_connect")
	Audio.start_line_noise()
	var start_t := Clock.now()
	for line in op.lines:
		if _hangup:
			GameState.set_var("hungup_" + op.id, true)
			break
		if line.op == "wait":
			if not await _sleep(line.s, g):
				in_call = false
				return false
		elif not await _do_call_line(line, g):
			in_call = false
			return false
	_log_call(call, call.dir, int(max(Clock.now() - start_t, 4.0)))
	Audio.stop_ring()
	Audio.play("call_end")
	in_call = false
	current_call = {}
	Events.call_ended.emit(call)
	return true


func _caller_label(call: Dictionary) -> String:
	if call.get("unknown", false):
		return "Número privado"
	if call.get("number", "") != "":
		return call.number
	return GameState.contact_name(call.who)


func _log_call(call: Dictionary, dir: String, duration: int) -> void:
	GameState.data.calls.push_front({"who": call.who, "dir": dir, "t": call.t, "dur": duration, "unknown": call.get("unknown", false), "number": call.get("number", "")})
	Events.content_changed.emit("calls")


func _do_call_line(op: Dictionary, g: int) -> bool:
	if op.op == "sfx":
		Audio.play(op.name)
		Events.call_line.emit("", "[%s]" % Audio.caption(op.name))
		return true
	var line_text := interp(op.text)
	Events.call_line.emit(op.who, line_text)
	if op.who in ["ines", "unknown", "eco"]:
		Audio.play("whisper", -16.0, randf_range(0.85, 1.05))
	var dur: float = op.dur if op.dur > 0.0 else clampf(1.2 + line_text.length() * 0.055, 1.5, 7.0)
	var waited := 0.0
	while waited < dur:
		if _hangup and in_call:
			return true
		if not await _sleep(0.1, g):
			return false
		waited += 0.1 if not fast_mode else dur
	return true


## Player-initiated call from the Phone app.
func player_call(who: String, number := "") -> void:
	if in_call:
		return
	var g := _gen
	GameState.data.called[who] = called(who) + 1
	Events.player_called.emit(who)
	var handler := _find_call_handler(who)
	var call := {"id": "out_" + who, "who": who, "dir": "out", "number": number, "t": Clock.now()}
	in_call = true
	current_call = call
	_hangup = false
	Events.call_started.emit(call)
	Audio.start_dialtone()
	if not await _sleep(2.2 if handler.is_empty() else randf_range(2.0, 4.5), g):
		Audio.stop_ring()
		return
	Audio.stop_ring()
	if _hangup:
		_finish_out(call, g)
		return
	if handler.is_empty():
		var c := GameState.contact(who)
		var line: String = c.get("voicemail_greeting", "")
		if line == "":
			line = "O número que marcou não está disponível de momento."
			Events.call_line.emit("", line)
		else:
			Audio.play("call_connect")
			Events.call_line.emit(who, line)
		await _sleep(3.0, g)
		_finish_out(call, g)
		return
	Audio.play("call_connect")
	Audio.start_line_noise()
	GameState.data.beats_done[handler.id] = float(GameState.data.playtime)
	var start_t := Clock.now()
	for op in handler.ops:
		if g != _gen:
			return
		if _hangup:
			break
		match op.op:
			"line", "sfx":
				if not await _do_call_line(op, g):
					return
			"wait":
				if not await _sleep(op.s, g):
					return
			"set":
				for k in op.vals:
					GameState.set_var(k, op.vals[k])
			"inc":
				GameState.inc_var(op.key, op.n)
			"cmd":
				if not await _do_cmd(op, g):
					return
	call.dur = int(Clock.now() - start_t)
	_finish_out(call, g)


func _finish_out(call: Dictionary, g: int) -> void:
	if g != _gen:
		return
	_log_call(call, "out", int(call.get("dur", 0)))
	Audio.stop_ring()
	Audio.play("call_end")
	in_call = false
	current_call = {}
	Events.call_ended.emit(call)
	notify_player_action()


func _find_call_handler(who: String) -> Dictionary:
	for src in [chapter.get("calls", []), Content.global_script.get("calls", [])]:
		for h in src:
			if h.who != who:
				continue
			if GameState.data.beats_done.has(h.id) and not h.repeat:
				continue
			if check(h.when):
				return h
	return {}


func hangup() -> void:
	_hangup = true
	Events.call_hangup_requested.emit()


# --- commands -----------------------------------------------------------------
func _do_cmd(op: Dictionary, g: int) -> bool:
	var a: Array = op.args
	match op.name:
		"notify":
			var n := GameState.post_notification(a[0], a[1], a[2])
			Events.notification_posted.emit(n)
		"sound":
			Audio.play(a[0])
			_caption(a[0])
		"ambient":
			Audio.set_ambient("" if a[0] == "off" else a[0])
			if Settings.get_value("sound_captions", false) and a[0] in ["dread", "tension"]:
				Events.toast_requested.emit("[um zumbido grave, quase inaudível]")
		"music":
			Audio.set_music("" if a[0] == "off" else a[0])
		"stopsounds":
			Audio.set_ambient("")
			Audio.set_music("")
			if Settings.get_value("sound_captions", false):
				Events.toast_requested.emit("[silêncio total — o som da casa desaparece]")
		"vibrate":
			Events.vibrate_requested.emit(int(a[0]) if a.size() > 0 else 1)
			Audio.play("vibrate")
			_caption("vibrate")
		"glitch":
			Events.glitch_requested.emit(float(a[0]), float(a[1]))
			Audio.play("glitch")
		"time":
			var t: String = a[0]
			if t.begins_with("+"):
				Clock.advance_minutes(float(t.substr(1)))
			elif t.begins_with("!"):
				Clock.frozen_display = t.substr(1) if t.length() > 1 else ""
			else:
				Clock.set_clock(t)
		"rate":
			Clock.rate = float(a[0])
		"photo":
			var had: bool = GameState.data.photos.has(a[0])
			GameState.add_photo(a[0], a[2] if a.size() > 2 else "")
			Events.content_changed.emit("photos")
			if not had and not (a.size() > 1 and a[1] == "silent"):
				var n2 := GameState.post_notification("gallery", "Fotografias", "1 nova fotografia")
				Events.notification_posted.emit(n2)
		"variant":
			if GameState.data.photos.has(a[0]):
				GameState.data.photos[a[0]].variant = a[1]
				Events.photo_changed.emit(a[0])
		"edit":
			var m := GameState.find_message(a[0], a[1])
			if not m.is_empty():
				m.text = a[2]
				Events.message_changed.emit(a[0], a[1])
		"delete":
			var m2 := GameState.find_message(a[0], a[1])
			if not m2.is_empty():
				m2.del = true
				Events.message_changed.emit(a[0], a[1])
		"unsend":
			# the message silently vanishes from the thread
			var th: Dictionary = GameState.data.threads.get(a[0], {})
			if th.has("messages"):
				th.messages = th.messages.filter(func(mm): return mm.id != a[1])
				Events.message_changed.emit(a[0], a[1])
		"contact":
			if not GameState.data.contacts.has(a[0]):
				GameState.data.contacts[a[0]] = {}
			GameState.data.contacts[a[0]].saved = true
			Events.content_changed.emit("contacts")
		"rename":
			if not GameState.data.contacts.has(a[0]):
				GameState.data.contacts[a[0]] = {}
			GameState.data.contacts[a[0]].name = a[1]
			GameState.data.contacts[a[0]].saved = true
			Events.content_changed.emit("contacts")
		"contactset":
			if not GameState.data.contacts.has(a[0]):
				GameState.data.contacts[a[0]] = {}
			GameState.data.contacts[a[0]][a[1]] = StoryParser._value(a[2])
			Events.content_changed.emit("contacts")
		"email":
			if not has_email(a[0]):
				var ed := Content.get_item("emails", a[0])
				GameState.data.emails.push_front({"id": a[0], "t": Clock.now()})
				Events.content_changed.emit("emails")
				if not (a.size() > 1 and a[1] == "silent"):
					var n3 := GameState.post_notification("email", ed.get("from_name", "Email"), ed.get("subject", ""))
					Events.notification_posted.emit(n3)
		"file":
			if not GameState.data.files.has(a[0]):
				GameState.data.files.append(a[0])
				Events.content_changed.emit("files")
				if not (a.size() > 1 and a[1] == "silent"):
					var fd := Content.get_item("files", a[0])
					var n4 := GameState.post_notification("files", "Transferências", fd.get("name", a[0]))
					Events.notification_posted.emit(n4)
		"note":
			if not GameState.data.notes.has(a[0]):
				GameState.data.notes.push_front(a[0])
				Events.content_changed.emit("notes")
		"voicemail":
			var exists := false
			for vm in GameState.data.voicemails:
				if vm.id == a[0]:
					exists = true
			if not exists:
				GameState.data.voicemails.push_front({"id": a[0], "t": Clock.now(), "heard": false})
				Events.content_changed.emit("calls")
				var n5 := GameState.post_notification("phone", "Correio de voz", "1 nova mensagem de voz")
				Events.notification_posted.emit(n5)
		"history":
			GameState.data.browser.history.push_front({"q": a[0], "t": _backdate(a[1]) if a.size() > 1 else Clock.now(), "injected": true})
			Events.content_changed.emit("browser")
		"unlock":
			GameState.data.browser.unlocked[a[0]] = true
			Events.content_changed.emit("browser")
		"clue":
			add_clue(a[0], a.size() > 1 and a[1] == "silent")
		"calllog":
			var who: String = a[0]
			GameState.data.calls.push_front({"who": who, "dir": a[1], "t": _backdate(a[2]), "dur": int(a[3]) if a.size() > 3 else 0, "unknown": false, "number": ""})
			Events.content_changed.emit("calls")
		"open":
			Events.open_app_requested.emit(a[0], {"param": a[1] if a.size() > 1 else "", "forced": true})
		"home":
			Events.open_app_requested.emit("home", {"forced": true})
		"lock":
			Events.lock_requested.emit()
		"screenoff":
			Events.screen_off_requested.emit(float(a[0]))
			if not await _sleep(float(a[0]), g):
				return false
		"restart":
			GameState.data.phone.pin_required = true
			Events.restart_requested.emit()
			if not await _sleep(4.0, g):
				return false
			# wait until the player gets past the PIN screen
			while GameState.data.phone.pin_required and not fast_mode:
				if not await _sleep(0.3, g):
					return false
			GameState.data.phone.pin_required = false
		"reflection":
			Events.reflection_requested.emit()
		"battery":
			GameState.data.battery = int(a[0])
			Events.phone_state_changed.emit()
		"location":
			GameState.data.location = a[0]
			GameState.data.location_log.push_front({"loc": a[0], "t": Clock.now()})
			Events.phone_state_changed.emit()
		"camera":
			GameState.data.camera.armed = a[0]
		"achieve":
			Achievements.unlock(a[0])
		"autotype":
			# the phone types by itself; with "send" it also sends it as you
			Events.autotype_requested.emit(a[0], a[1])
			if not await _sleep(typing_time(a[1]), g):
				return false
			if a.size() > 2 and a[2] == "send":
				var am := GameState.add_message(a[0], {"from": "me", "text": a[1], "t": Clock.now()}, false)
				Audio.play("sent")
				Events.message_added.emit(a[0], am)
		"checkpoint":
			Saves.autosave()
		"endchapter":
			_end_chapter()
		"ending":
			GameState.data.ending = a[0]
			Achievements.record_ending(a[0])
			Events.ending_reached.emit(a[0])
		"deduction":
			Events.deduction_requested.emit()
			while not GameState.flag("deduction_done") and not fast_mode:
				if not await _sleep(0.3, g):
					return false
		"typing":
			Events.thread_typing.emit(a[0], a[1], true)
			var ok := await _sleep(float(a[2]), g)
			Events.thread_typing.emit(a[0], a[1], false)
			if not ok:
				return false
		"toast":
			Events.toast_requested.emit(a[0])
		"hiddenapp":
			GameState.data.phone[a[0] + "_app"] = a[1] == "on"
			Events.phone_state_changed.emit()
		"setting":
			GameState.data.phone[a[0]] = StoryParser._value(a[1])
			Events.phone_state_changed.emit()
		"read":
			GameState.mark_read(a[0])
		"alarm":
			GameState.data.alarms.append({"time": a[0], "label": a[1], "on": true, "foreign": true})
			Events.content_changed.emit("alarms")
		"clearchoice":
			GameState.data.choices.erase(a[0])
			Events.choice_cleared.emit(a[0])
		"retime":
			# retime <thread> <msgid> <HH:MM or YYYY-MM-DD HH:MM>
			var mm := GameState.find_message(a[0], a[1])
			if not mm.is_empty():
				mm.t = Clock.parse_datetime(a[2]) if a[2].contains("-") else _backdate(a[2])
				Events.message_changed.emit(a[0], a[1])
		"hidethread":
			GameState.data.hidden_threads[a[0]] = true
			Events.content_changed.emit("threads")
		"showthread":
			GameState.data.hidden_threads.erase(a[0])
			Events.content_changed.emit("threads")
		"mapmark":
			GameState.data.map_marks[a[0]] = true
			Events.content_changed.emit("map")
	return true


## Accessibility: show story sound effects as captions when enabled.
func _caption(sound_name: String) -> void:
	if not Settings.get_value("sound_captions", false):
		return
	if Audio.CAPTIONS.has(sound_name):
		Events.toast_requested.emit("[%s]" % Audio.caption(sound_name))


func add_clue(id: String, silent := false) -> void:
	if not Content.has_item("clues", id):
		push_warning("unknown clue " + id)
	if GameState.add_clue(id):
		Events.clue_found.emit(id)
		Events.content_changed.emit("clues")
		if not silent:
			Audio.play("clue")
			var title := str(Content.get_item("clues", id).get("title", ""))
			if title != "":
				var hint := ""
				if not Achievements.stats.get("clue_hint_seen", false):
					Achievements.stats["clue_hint_seen"] = true
					hint = "\nGuardada em Notas → Pistas."
				Events.toast_requested.emit("Nova pista: %s%s" % [title, hint])
		Achievements.check_clues()
		notify_player_action()


func _end_chapter() -> void:
	var cur: String = GameState.data.chapter
	GameState.data.chapter_complete = true
	active = false
	Clock.running = false
	Events.chapter_ended.emit(cur)
	Achievements.on_chapter_end(cur)


## Main calls this after the chapter transition animation.
func advance_chapter() -> void:
	var nxt := Content.next_chapter(GameState.data.chapter)
	if nxt == "":
		return
	start_chapter(nxt)
