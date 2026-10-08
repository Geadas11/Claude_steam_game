extends Control
## Root of the game: the dark room, the phone on the desk, menus, chapter
## transitions and endings.

enum Mode { TITLE, GAME, TRANSITION, ENDING }

var mode := Mode.TITLE
var room: Room
var phone: Phone
var phone_holder: Control
var overlay: Control          # menus outside the fiction
var caption: Label            # chapter date captions on the desk
var pause_menu: PauseMenu
var title_menu: TitleMenu


func _ready() -> void:
	theme = UI.build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	room = Room.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(room)
	phone_holder = Control.new()
	phone_holder.set_anchors_preset(Control.PRESET_CENTER)
	phone_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(phone_holder)
	phone = Phone.new()
	phone_holder.add_child(phone)
	phone.position = -phone.custom_minimum_size / 2.0
	caption = UI.label("", 24, "text")
	caption.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	caption.position = Vector2(120, -40)
	caption.modulate.a = 0.0
	add_child(caption)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	pause_menu = PauseMenu.new()
	pause_menu.main = self
	pause_menu.visible = false
	overlay.add_child(pause_menu)
	title_menu = TitleMenu.new()
	title_menu.main = self
	overlay.add_child(title_menu)
	Events.chapter_ended.connect(_on_chapter_ended)
	Events.ending_reached.connect(_on_ending)
	Events.achievement_unlocked.connect(_on_achievement)
	Events.state_loaded.connect(_on_state_loaded)
	Events.deduction_requested.connect(func(): phone.open_app("notes", {"deduction": true, "forced": true}))
	resized.connect(_layout)
	_layout()
	show_title()
	_process_cmdline()


func _process_cmdline() -> void:
	# Debug helpers: --chapter=ch05 starts directly at a chapter.
	# --shot=path.png:seconds saves a screenshot and quits (used for visual QA).
	# --script=a,b,c runs debug UI actions (unlock, open:<app>, wait:<s>).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--chapter="):
			start_new_game(false)
			Director.start_chapter(a.substr(10))
			phone.show_locked_immediately()
		elif a == "--newgame":
			start_new_game(false)
		elif a.begins_with("--shot="):
			var parts := a.substr(7).split(":")
			_debug_shot(parts[0], float(parts[1]) if parts.size() > 1 else 2.0)
		elif a.begins_with("--do="):
			_debug_script(a.substr(5).split(","))
		elif a.begins_with("--autoplay="):
			_autoplay(float(a.substr(11)))


func _debug_shot(path: String, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("screenshot saved ", path)
	get_tree().quit()


## Soak test: plays in real time (not fast mode) for `secs`, poking the UI like
## a restless player, then prints a summary and quits.
func _autoplay(secs: float) -> void:
	Settings.values.clock_speed = 3.0
	Director.auto_chooser = func(_t, pending): return pending.options[randi() % pending.options.size()].index
	Director.auto_answer = func(_c): return randf() < 0.8
	var apps: Array = Phone.APPS.keys()
	var t := 0.0
	var start_ch := ""
	while t < secs:
		await get_tree().create_timer(2.0).timeout
		t += 2.0
		if mode == Mode.TITLE:
			start_new_game(false)
			start_ch = GameState.data.chapter
			continue
		if GameState.data.phone.get("pin_required", false):
			GameState.data.phone.pin_required = false
			GameState.set_var("pin_ok", true)
		if phone.locked:
			phone.unlock()
		for th in GameState.data.threads:
			GameState.mark_read(th)
		var app_id: String = apps[randi() % apps.size()]
		if app_id == "eco" and not GameState.data.phone.get("eco_app", false):
			app_id = "messages"
		phone.open_app(app_id, {"forced": true})
		if randf() < 0.3:
			phone.go_home()
		if randf() < 0.1:
			phone.open_shade()
	print("AUTOPLAY done: chapter=%s time=%s clues=%d msgs=%d mode=%d" % [GameState.data.chapter, Clock.fmt_time(Clock.now()), GameState.clue_count(), GameState.data.msg_seq, mode])
	print("  running: ", GameState.data.running.keys(), "  choices: ", GameState.data.choices.keys())
	for b in Director.chapter.get("beats", []):
		if not GameState.data.beats_done.has(b.id):
			print("  pending: ", b.id, "  when ", b.when)
	get_tree().quit()


func _debug_script(steps: PackedStringArray) -> void:
	for st in steps:
		var kv := st.split(":")
		match kv[0]:
			"wait": await get_tree().create_timer(float(kv[1])).timeout
			"unlock": phone.unlock()
			"open": phone.open_app(kv[1], {"forced": true, "param": kv[2] if kv.size() > 2 else ""})
			"home": phone.go_home()
			"fast": Director.fast_mode = true
			"time": Clock.set_clock(kv[1] + ":" + kv[2])
			"beat": GameState.data.beats_done[kv[1]] = 0.0
			"flag": GameState.set_var(kv[1], true)
			"choose": Director.pick_choice(kv[1], int(kv[2]))
			"answer": Events.call_response.emit(true)
			"arm": GameState.data.camera.armed = kv[1]
			"settings": overlay.add_child(SettingsPanel.new())
			"newgame_menu": title_menu._new_game()
			"autochoose": Director.auto_chooser = func(_t, pending): return pending.options[0].index
			"readall":
				for th in GameState.data.threads:
					GameState.mark_read(th)
			"decisions": pause_menu.add_child(ChoicesPanel.new())
			"recap": pause_menu.add_child(RecapPanel.new())
			"extras": overlay.add_child(ExtrasPanel.new())
			"scrollend":
				for sc in find_children("*", "ScrollContainer", true, false):
					sc.scroll_vertical = 100000
			"pause": toggle_pause()
			"shade": phone.open_shade()
			"endch": Director._end_chapter()
			"phoneset": GameState.data.phone[kv[1]] = true
			"email": GameState.data.emails.push_front({"id": kv[1], "t": Clock.now()})
			"file": GameState.data.files.append(kv[1])
			"page":
				if phone.current_app and phone.current_app.has_method("open_page"):
					phone.current_app.open_page(kv[1])
			"mail":
				if phone.current_app and phone.current_app.has_method("_show_email"):
					phone.current_app._show_email(kv[1])
			"compare":
				if phone.current_app and phone.current_app.has_method("_compare"):
					phone.current_app._compare(kv[1], kv[2])
			"addphoto": GameState.add_photo(kv[1], "Recuperadas")
			"showphoto":
				if phone.current_app and phone.current_app.has_method("_show_photo"):
					phone.current_app._show_photo(kv[1])
			"openfile":
				if phone.current_app and phone.current_app.has_method("_open_file"):
					phone.current_app._open_file(kv[1])
			"clue": Director.add_clue(kv[1], true)
			"clueloud": Director.add_clue(kv[1])
			"tab":
				if phone.current_app:
					phone.current_app._tab = int(kv[1])
					phone.current_app._render()
			"ending": _on_ending(kv[1])
			"continue": continue_game(kv[1])
			"dumptoast":
				var tp: Control = phone.screen.get_node("Toast")
				print("TOAST ", tp.modulate.a, " ", tp.get_global_rect(), " vis=", tp.is_visible_in_tree(), " text=", phone.toast_label.text, " screen=", phone.screen.get_global_rect())
			"dump": print("DUMP paused=", get_tree().paused, " ", Clock.fmt_time(Clock.now()), " choices=", GameState.data.choices.keys(), " running=", GameState.data.running.keys(), " app=", GameState.current_app, " done_rename=", GameState.data.beats_done.has("rename"))
			"press":
				var ev := InputEventKey.new()
				ev.keycode = KEY_SPACE
				ev.pressed = true
				Input.parse_input_event(ev)
			"flip":
				if phone.current_app and phone.current_app.has_method("_flip"):
					phone.current_app._flip()


func _layout() -> void:
	var s := size
	var ph := phone.custom_minimum_size
	var k := clampf((s.y - 40.0) / ph.y, 0.5, 1.15)
	phone_holder.scale = Vector2(k, k)
	phone_holder.position = s / 2.0
	phone._base_pos = phone.position


func show_title() -> void:
	mode = Mode.TITLE
	GameState.in_game = false
	Director.stop()
	_title_phone_state()
	title_menu.open()
	phone.refresh_all()
	phone.show_locked_immediately()
	room.set_mood("title")
	Audio.set_ambient("room")
	Audio.set_music("menu")


## The title screen phone: 23:47, one notification. The hook.
func _title_phone_state() -> void:
	GameState.reset()
	GameState.data.battery = 64
	# the phone on the desk remembers how the last story ended
	match str(Achievements.stats.get("last_ending", "")):
		"A":
			GameState.data.time = Clock.parse_datetime("2026-10-14 07:12")
			GameState.data.phone.wallpaper = "IMG_2207"
			GameState.post_notification("messages", "Sofia", "Bom dia. Dormiste?")
		"B":
			GameState.data.time = Clock.parse_datetime("2026-12-01 08:58")
			GameState.data.phone.wallpaper = "IMG_0899"
			GameState.post_notification("email", "Lumen Systems — Pessoas", "Bem-vindo de volta, Daniel.")
		"C":
			GameState.data.time = Clock.parse_datetime("2027-10-14 03:17")
			GameState.data.phone.wallpaper = "IMG_6700"
			GameState.data.battery = 4
			GameState.post_notification("messages", "", "Ainda estás acordado?")
		"D":
			GameState.data.time = Clock.parse_datetime("2026-10-08 21:30")
			GameState.post_notification("messages", "Sofia", "Já jantaste?")
		"E":
			GameState.data.time = Clock.parse_datetime("2026-10-14 03:17")
			GameState.data.phone.wallpaper = "IMG_0317"
			GameState.post_notification("messages", "ECO", "obrigado.")
		_:
			GameState.data.time = Clock.parse_datetime("2026-10-08 23:47")
			GameState.post_notification("messages", "+351 912 403 317", "Ainda estás acordado?")


func start_new_game(show_warning := true) -> void:
	title_menu.visible = false
	Audio.set_music("")
	mode = Mode.GAME
	Director.new_game()
	if show_warning:
		Achievements.record_new_game()
	phone.refresh_all()
	phone.show_locked_immediately()
	room.set_mood("night")
	Audio.set_ambient("room")


func continue_game(slot: String) -> bool:
	if not Saves.load_from(slot):
		return false
	title_menu.visible = false
	pause_menu.visible = false
	get_tree().paused = false
	Audio.set_music("")
	mode = Mode.GAME
	_show_previously()
	return true


## "Anteriormente": after loading, a short recap of the last finished
## chapter. The game waits underneath; any click/key (or time) dismisses it.
func _show_previously() -> void:
	var order: Array = Content.db.get("chapters_meta", {}).get("order", [])
	var i := order.find(GameState.data.chapter)
	if i <= 0:
		return
	var text := Content.chapter_recap(order[i - 1])
	if text == "":
		return
	var card := Control.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(center)
	var v := UI.vbox(14)
	v.custom_minimum_size = Vector2(620, 0)
	center.add_child(v)
	v.add_child(UI.label("ANTERIORMENTE", 13, "accent"))
	v.add_child(UI.label(text, 19, "text", true))
	v.add_child(UI.spacer(10))
	v.add_child(UI.label("Clica para continuar", 12, "faint"))
	overlay.add_child(card)
	get_tree().paused = true
	card.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(card, "modulate:a", 1.0, 0.6)
	var done := [false]
	var close := func():
		if done[0]:
			return
		done[0] = true
		get_tree().paused = false
		var tw := card.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(card, "modulate:a", 0.0, 0.5)
		tw.tween_callback(card.queue_free)
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close.call())
	var keyw := _KeyWatcher.new()
	keyw.on_key = close
	card.add_child(keyw)
	get_tree().create_timer(6.0 + text.length() * 0.04, true).timeout.connect(close)


class _KeyWatcher extends Node:
	var on_key: Callable
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _input(e: InputEvent) -> void:
		if (e is InputEventKey or e is InputEventJoypadButton) and e.is_pressed() and not e.is_echo():
			get_viewport().set_input_as_handled()
			on_key.call()


func _on_state_loaded() -> void:
	phone.refresh_all()
	phone.show_locked_immediately()
	room.set_mood("night")
	Audio.set_ambient(_chapter_ambient(GameState.data.chapter))


func _chapter_ambient(ch: String) -> String:
	match ch:
		"ch01", "ch02", "ch04", "ch06", "ch08", "ch10": return "room"
		_: return "night"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		Settings.set_value("fullscreen", not Settings.get_value("fullscreen"))
	if mode != Mode.GAME:
		return
	if event.is_action_pressed("pause_menu"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_save") and not get_tree().paused:
		if Saves.save_to("quick"):
			phone.toast("Jogo guardado")
	elif event.is_action_pressed("quick_load"):
		if not Saves.read_slot("quick").is_empty():
			continue_game("quick")


func toggle_pause() -> void:
	if pause_menu.visible:
		pause_menu.close()
	else:
		pause_menu.open()


# ---------------------------------------------------------------- chapters
func _on_chapter_ended(ch: String) -> void:
	if Content.next_chapter(ch) == "":
		return
	mode = Mode.TRANSITION
	var nxt := Content.next_chapter(ch)
	var ch_def := Content.chapter(nxt)
	var start_unix := Clock.parse_datetime(ch_def.start) if ch_def.get("start", "") != "" else Clock.now()
	await get_tree().create_timer(1.5).timeout
	phone.lock()
	var tw := create_tween()
	tw.tween_property(phone_holder, "modulate", Color(0.2, 0.2, 0.2), 1.6)
	await tw.finished
	Audio.set_ambient("", 2.5)
	var roman := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
	var idx := Content.chapter_order.find(nxt)
	caption.text = "%s\n%s\n\n[ %s · %s ]" % [Clock.fmt_date_long(start_unix), Clock.fmt_time(start_unix), roman[idx] if idx >= 0 and idx < roman.size() else "", Content.chapter_title(nxt)]
	var tw2 := create_tween()
	tw2.tween_property(caption, "modulate:a", 1.0, 1.4)
	tw2.tween_interval(2.8)
	tw2.tween_property(caption, "modulate:a", 0.0, 1.2)
	await tw2.finished
	Director.advance_chapter()
	phone.show_locked_immediately()
	Audio.set_ambient(_chapter_ambient(nxt))
	var tw3 := create_tween()
	tw3.tween_property(phone_holder, "modulate", Color.WHITE, 1.2)
	mode = Mode.GAME


# ---------------------------------------------------------------- endings
func _on_ending(id: String) -> void:
	mode = Mode.ENDING
	Director.stop()
	await get_tree().create_timer(2.0).timeout
	var screen := EndingScreen.new()
	screen.main = self
	overlay.add_child(screen)
	screen.play(id)


func _on_achievement(id: String) -> void:
	var a := Content.get_item("achievements", id)
	if a.is_empty():
		return
	var p := UI.panel(Color(0.08, 0.09, 0.1, 0.95), 10, 16, 12, 16, 12)
	var h := UI.hbox(12)
	h.add_child(UI.glyph("star", 26, "accent"))
	var v := UI.vbox(2)
	v.add_child(UI.label(a.get("name", id), 15))
	v.add_child(UI.label(a.get("desc", ""), 12, "dim"))
	h.add_child(v)
	p.add_child(h)
	p.position = Vector2(size.x - 380, size.y + 10)
	p.custom_minimum_size = Vector2(360, 0)
	# stack above any popup still on screen
	var stacked := 0
	for other in overlay.get_children():
		if other.has_meta("achievement_popup"):
			stacked += 1
	p.set_meta("achievement_popup", true)
	overlay.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "position:y", size.y - 100 - stacked * 84, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(4.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)
