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
## "game": the phone is on the PC screen. "own": the player's own phone is the
## phone of the game (the phone here is rendered off-screen and streamed).
var phone_mode := "game"
var phone_vp: SubViewport
var own_hud: Control
var _own_clock: Label
var _reconnect: PhoneChoicePanel
const STREAM_SCALE := 1.5
## The 3D house (created the first time a game starts).
var world: GameWorld
var world_ui: Control         # HUD + fade, between the house and the phone
var fade: ColorRect
var phone_raised := true      # phone of the game: in Daniel's hand (Tab)
var _phone_tw: Tween
var _pos_save_t := 0.0
var _last_hour := -1.0
var _shown_loc := ""
var _away: Control            # story location with no 3D place: phone only
var _dying := false
var _phone_off := false       # story: the game's phone isn't in this scene (the prologue)
var _say_box: Control         # in-person choices ("aqui")


func _ready() -> void:
	theme = UI.build_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# the root covers the whole window: it must not catch the mouse itself
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	room = Room.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(room)
	world_ui = Control.new()
	world_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_ui)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	phone_holder = Control.new()
	phone_holder.set_anchors_preset(Control.PRESET_CENTER)
	phone_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(phone_holder)
	phone = Phone.new()
	phone_holder.add_child(phone)
	phone.position = -phone.custom_minimum_size / 2.0
	_build_own_hud()
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
	Coop.start_requested.connect(_on_coop_start)
	Coop.ended.connect(func(reason):
		if mode != Mode.TITLE:
			show_title()
		if reason != "":
			_notice(reason))
	Events.achievement_unlocked.connect(_on_achievement)
	Events.state_loaded.connect(_on_state_loaded)
	Events.deduction_requested.connect(func(): phone.open_app("notes", {"deduction": true, "forced": true}))
	Companion.clients_changed.connect(_on_phone_clients)
	Companion.on_back = func(): phone.back()
	Events.notification_posted.connect(func(n: Dictionary): _pocket_ping(str(n.get("title", "Notificação"))))
	Events.message_added.connect(func(th: String, m: Dictionary):
		if str(m.get("from", "")) != "me" and not m.get("silent", false):
			_pocket_ping("Mensagem · %s" % GameState.contact_name(str(m.get("from", th))) if str(m.get("from", "")) not in ["", "system"] else "Nova mensagem"))
	Events.call_incoming.connect(func(c: Dictionary): _pocket_ping("A tocar · %s" % GameState.contact_name(str(c.get("who", ""))), true))
	Events.phone_state_changed.connect(_sync_location)
	# where a death sends him back to (R7): the start of this chapter
	Events.chapter_started.connect(func(_ch): Saves.save_to("chapter"))
	# things said in person: the options sit on the screen, not on the phone
	Events.choice_offered.connect(func(th: String): if th == "aqui": _show_say_choices())
	Events.choice_cleared.connect(func(th: String): if th == "aqui": _hide_say_choices())
	Events.world_cue.connect(_on_main_cue)
	Events.open_app_requested.connect(func(_a, params: Dictionary):
		if params.get("forced", false) and mode == Mode.GAME and _world_on():
			set_phone_raised(true))
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
			"snap":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(kv[1])
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
			"coophost":
				Coop.create_room()
				await get_tree().create_timer(1.0).timeout
				print("COOP_CODE ", Coop.code)
			"coopjoin": Coop.join_room(kv[1])
			"coopstart": Coop.start_game()
			"cooppanel": title_menu.add_child(CoopPanel.new())
			"coopsay":
				# send a line in the shared conversation as this player
				var th := Coop.link_thread()
				var msg := GameState.add_message(th, {"from": "me", "text": kv[1].replace("_", " "), "t": Clock.now()}, false)
				Events.message_added.emit(th, msg)
			"companion":
				Companion.start()
				print("COMPANION_URL ", Companion.url())
			"phonemode":
				set_phone_mode(kv[1])
			"dumpapp":
				print("APP ", GameState.current_app, " frames=", Companion.frames_sent, " locked=", phone.locked)
			"call": Director.player_call(kv[1])
			"clicktoast":
				var tpc: Control = phone.screen.get_node("Toast")
				var pos: Vector2 = get_tree().root.get_final_transform() * (tpc.get_global_transform_with_canvas() * (tpc.size / 2))
				for pressed in [true, false]:
					var mb := InputEventMouseButton.new()
					mb.button_index = MOUSE_BUTTON_LEFT
					mb.pressed = pressed
					mb.position = pos
					mb.global_position = pos
					Input.parse_input_event(mb)
				await get_tree().process_frame
			"click":
				# a real mouse click at a point of the phone screen (fractions 0..1)
				var p: Vector2 = get_tree().root.get_final_transform() * (phone.screen.get_global_transform_with_canvas() * (phone.screen.size * Vector2(float(kv[1]), float(kv[2]))))
				var mm := InputEventMouseMotion.new()
				mm.position = p
				mm.global_position = p
				Input.parse_input_event(mm)
				await get_tree().process_frame
				for down in [true, false]:
					var mc := InputEventMouseButton.new()
					mc.button_index = MOUSE_BUTTON_LEFT
					mc.pressed = down
					mc.position = p
					mc.global_position = p
					Input.parse_input_event(mc)
					await get_tree().create_timer(0.08).timeout
				print("CLICK ", kv[1], ",", kv[2], " -> app=", GameState.current_app)
			"wclick":
				# a real mouse click at a point of the window (fractions 0..1)
				var wp := Vector2(get_window().size) * Vector2(float(kv[1]), float(kv[2]))
				for down in [true, false]:
					var wc := InputEventMouseButton.new()
					wc.button_index = MOUSE_BUTTON_LEFT
					wc.pressed = down
					wc.position = wp
					wc.global_position = wp
					Input.parse_input_event(wc)
					await get_tree().create_timer(0.08).timeout
			"hit":
				var pt: Vector2 = phone.screen.get_global_rect().position + phone.screen.get_global_rect().size * Vector2(float(kv[1]), float(kv[2]))
				for c in phone.screen.find_children("*", "CanvasItem", true, false):
					if c is Control and c.is_visible_in_tree() and c.get_global_rect().has_point(pt) :
						print("HIT ", c.get_path(), " ", c.get_class(), " ", c.get_script().resource_path if c.get_script() else "", " ", c.get_global_rect().size)
			"dumptoast":
				var tp: Control = phone.screen.get_node("Toast")
				print("TOAST ", tp.modulate.a, " ", tp.get_global_rect(), " vis=", tp.is_visible_in_tree(), " text=", phone.toast_label.text, " screen=", phone.screen.get_global_rect())
			"dump": print("DUMP paused=", get_tree().paused, " ", Clock.fmt_time(Clock.now()), " choices=", GameState.data.choices.keys(), " running=", GameState.data.running.keys(), " app=", GameState.current_app, " clues=", GameState.clue_count(), " achievements=", Achievements.unlocked.size())
			"press":
				var ev := InputEventKey.new()
				ev.keycode = KEY_SPACE
				ev.pressed = true
				Input.parse_input_event(ev)
			"flip":
				if phone.current_app and phone.current_app.has_method("_flip"):
					phone.current_app._flip()
			# --- the 3D house
			"pocket":
				print("TAB before raised=", phone_raised, " mode=", phone_mode, " world=", _world_on())
				set_phone_raised(not phone_raised)
				print("TAB after raised=", phone_raised)
			"quit": get_tree().quit()
			"spawn": world.spawn(kv[1])
			"at":
				# at:x:z:yaw[:pitch] puts Daniel somewhere, looking somewhere
				world.player.global_position = Vector3(float(kv[1]), 0.02, float(kv[2]))
				world.player.set_view(float(kv[3]), float(kv[4]) if kv.size() > 4 else 0.0)
			"at3":
				# at3:x:y:z:yaw[:pitch]
				world.player.global_position = Vector3(float(kv[1]), float(kv[2]), float(kv[3]))
				world.player.set_view(float(kv[4]), float(kv[5]) if kv.size() > 5 else 0.0)
			"look": world.player.set_view(float(kv[1]), float(kv[2]) if kv.size() > 2 else 0.0)
			"use":
				await get_tree().physics_frame
				await get_tree().physics_frame
				print("USE ", world.player.target_prompt)
				world.player.use_target()
			"walk":
				# walk:action:secs holds a movement key
				Input.action_press(kv[1])
				await get_tree().create_timer(float(kv[2])).timeout
				Input.action_release(kv[1])
			"torch": world.player.toggle_flashlight()
			"light": world.house.set_room_light(kv[1], kv[2] == "on")
			"power": world.house.set_power(kv[1] == "on")
			"cue": Events.world_cue.emit(kv[1], Array(kv.slice(2)))
			"key":
				# key:Tab:0.1 a real key press (physical), held for secs
				var ke := InputEventKey.new()
				ke.physical_keycode = OS.find_keycode_from_string(kv[1])
				ke.keycode = ke.physical_keycode
				ke.pressed = true
				Input.parse_input_event(ke)
				await get_tree().create_timer(float(kv[2]) if kv.size() > 2 else 0.08).timeout
				var ku := ke.duplicate()
				ku.pressed = false
				Input.parse_input_event(ku)
				await get_tree().process_frame
			"mouse":
				world.player.force_look = true
				var mm2 := InputEventMouseMotion.new()
				mm2.relative = Vector2(float(kv[1]), float(kv[2]))
				Input.parse_input_event(mm2)
				await get_tree().process_frame
			"hudsize": print("HUD ", world.hud.size, " ui=", world_ui.size, " main=", size, " anchors=", world.hud.anchor_right, " ", world.hud.offset_right)
			"hour": world.set_hour(float(kv[1]))
			"figs":
				for f in world._figures:
					print("FIG ", f.global_position, " vis=", f.visible, " fade=", f.get_meta("mat").get_shader_parameter("fade"), " parent=", f.get_parent().name)
			"ps":
				var pz: Presence = world.presence
				print("PRESENCE t=%s form=%s state=%s att=%.1f screen=%s light=%.2f dist=%.1f" % [Clock.fmt_time(Clock.now()), pz.form, pz.state_name(), pz.attention, pz.screen_on, pz._player_light(), pz.pos.distance_to(world.player.global_position)])
			"ent":
				# ent:x:z:fade[:prints] the thing standing there (visual QA)
				world.presence.show_at(Vector3(float(kv[1]), 0.0, float(kv[2])), float(kv[3]), kv.size() > 4)
			"where":
				var wp := world.player.global_position
				print("WHERE %.2f %.2f %.2f yaw=%.1f target=%s raised=%s" % [wp.x, wp.y, wp.z, world.player.yaw_deg(), world.player.target_prompt, phone_raised])


func _layout() -> void:
	var s := size
	var ph := phone.custom_minimum_size
	var k := clampf((s.y - 40.0) / ph.y, 0.5, 1.15)
	if _world_on():
		k = clampf((s.y - 60.0) / ph.y, 0.5, 1.0)
	phone_holder.scale = Vector2(k, k)
	phone_holder.position = _phone_pos(phone_raised)
	phone._base_pos = phone.position


## Where the phone holder goes: the middle of the desk (title), or Daniel's
## hand on the right of the view (raised) / out of sight (lowered).
func _phone_pos(raised: bool) -> Vector2:
	if not _world_on():
		return size / 2.0
	var w := phone.custom_minimum_size.x * phone_holder.scale.x
	var h := phone.custom_minimum_size.y * phone_holder.scale.y
	var x := size.x - w / 2.0 - maxf(40.0, size.x * 0.08)
	return Vector2(x, size.y / 2.0) if raised else Vector2(x, size.y + h / 2.0 + 40.0)


func _world_on() -> bool:
	return world != null and world.active


func _ensure_world() -> void:
	if world:
		return
	world = GameWorld.new()
	add_child(world)
	move_child(world, 0)
	world.attach_hud(world_ui)
	world_ui.add_child(fade)
	world.presence.caught.connect(_on_caught)


## Into the house: hide the desk, the phone goes into Daniel's hand.
func enter_world(where := "") -> void:
	_ensure_world()
	room.visible = false
	world.set_active(true)
	if where == "":
		where = _spawn_for_chapter()
	var wp: Array = GameState.data.get("w_pos", [])
	if where == "saved" and wp.size() == 4:
		world.player.global_position = Vector3(wp[0], wp[1], wp[2])
		world.player.set_view(wp[3])
	else:
		world.spawn("sofa" if where == "saved" else where)
	_apply_chapter_lights()
	world.hud.show_phone_hint = phone_mode == "game" and not _phone_off
	world.hud.set_phone_idle()
	own_hud.visible = false
	phone_raised = phone_mode == "game" and not _phone_off
	phone_holder.visible = phone_mode == "game" and not _phone_off
	phone.input_active = true
	_layout()
	_shown_loc = ""
	_sync_location()
	if not Settings.get_value("seen_3d_hint", false):
		_controls_hint()


## The first time in the house: how to move (once, then it's in Definições).
func _controls_hint() -> void:
	Settings.set_value("seen_3d_hint", true)
	var k := func(a: String) -> String: return Settings.key_label(a, true)
	var lines := [
		"%s %s %s %s  andar   ·   %s  correr   ·   %s  agachar" % [k.call("move_forward"), k.call("move_left"), k.call("move_back"), k.call("move_right"), k.call("sprint"), k.call("crouch")],
		"%s  usar / examinar   ·   %s  lanterna   ·   %s  %s o telemóvel" % [k.call("interact"), k.call("flashlight"), k.call("phone_toggle"), "guardar / tirar" if phone_mode == "game" else "(está no teu telemóvel)"],
	]
	var p := UI.panel(Color(0.04, 0.05, 0.06, 0.85), 12, 22, 14, 22, 14)
	var v := UI.vbox(6)
	for line in lines:
		var l := UI.label(line, 15, "text")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	p.add_child(v)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_ui.add_child(p)
	await get_tree().process_frame
	p.position = Vector2((size.x - p.size.x) / 2.0, 40)
	var tw := p.create_tween()
	p.modulate.a = 0.0
	tw.tween_property(p, "modulate:a", 1.0, 0.6)
	tw.tween_interval(9.0)
	tw.tween_property(p, "modulate:a", 0.0, 1.2)
	tw.tween_callback(p.queue_free)


const PLACE_NAMES := {"farol": "Bar O Farol", "livraria": "Livraria Maré", "cais": "Cais Velho",
	"clinica": "Clínica Atlântico", "rui": "Casa do Rui", "casa_ines": "Casa do Rui", "caminho": "A caminho do cais", "casa": "Casa"}


## The story moved Daniel somewhere ("location ..."): go there in 3D, or —
## for a place with no 3D version — play it on the phone over a dark card.
func _sync_location() -> void:
	if world == null or mode == Mode.TITLE or Content.role != "daniel":
		return
	var loc := str(GameState.data.get("location", "casa"))
	if loc == _shown_loc:
		return
	var first := _shown_loc == ""
	_shown_loc = loc
	if GameWorld.LOCATIONS.has(loc):
		if not first:
			var tw := create_tween()
			tw.tween_property(fade, "modulate:a", 1.0, 0.5)
			await tw.finished
		if is_instance_valid(_away):
			_away.queue_free()
		world.set_active(true)
		world.go_to(loc)
		_apply_chapter_lights()
		_layout()
		if not first:
			create_tween().tween_property(fade, "modulate:a", 0.0, 0.8)
	else:
		_show_away(PLACE_NAMES.get(loc, loc.capitalize()))


func _show_away(place: String) -> void:
	if is_instance_valid(_away):
		_away.queue_free()
	world.set_active(false)
	_away = ColorRect.new()
	(_away as ColorRect).color = Color(0.02, 0.02, 0.025)
	_away.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_away.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(place, 28, "dim")
	l.position = Vector2(120, 120)
	_away.add_child(l)
	world_ui.add_child(_away)
	phone_holder.visible = true
	phone_raised = true
	phone.input_active = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_layout()


func leave_world() -> void:
	if world:
		world.set_active(false)
	_shown_loc = ""
	if is_instance_valid(_away):
		_away.queue_free()
	room.visible = true
	phone_raised = true
	phone.input_active = true
	fade.modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_layout()
	if phone_mode == "game":
		phone_holder.visible = true


## Late-night chapters start in bed with the lights off; evenings on the sofa.
func _spawn_for_chapter() -> String:
	var h := int(Clock.fmt_time(Clock.now()).split(":")[0])
	return "bed" if h >= 1 and h < 7 else "sofa"


func _hour_now() -> float:
	var hm := Clock.fmt_time(Clock.now()).split(":")
	return float(hm[0]) + float(hm[1]) / 60.0


func _apply_chapter_lights() -> void:
	var h := int(Clock.fmt_time(Clock.now()).split(":")[0])
	world.set_hour(_hour_now())
	var evening := h >= 19 or h == 0
	for id in world.house.rooms:
		world.house.set_room_light(id, false)
	world.house.set_power(true)
	world.house.set_room_light("sala", evening)
	if world.house.has_method("set_tv"):
		world.house.set_tv(evening)


## Tab: the phone of the game comes out of the pocket / goes back in.
func set_phone_raised(on: bool) -> void:
	if phone_mode != "game" or not _world_on():
		return
	if on and _phone_off:
		return
	if on == phone_raised:
		return
	phone_raised = on
	phone.input_active = on
	if not on:
		get_viewport().gui_release_focus()
	phone_holder.visible = true
	if _phone_tw:
		_phone_tw.kill()
	_phone_tw = create_tween()
	var target := _phone_pos(on)
	var calm: bool = Settings.get_value("reduce_motion", false)
	_phone_tw.tween_property(phone_holder, "position", target, 0.0 if calm else 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not on:
		_phone_tw.tween_callback(func(): if not phone_raised: phone_holder.visible = false)
	Audio.play("sent", -18.0, 0.7)
	if on:
		world.hud.set_phone_idle()


## The phone buzzed in the pocket.
func _pocket_ping(text: String, ringing := false) -> void:
	if mode == Mode.GAME and _world_on() and phone_mode == "game" and not phone_raised:
		world.hud.phone_ping(text, ringing)


func _menu_open() -> bool:
	for c in overlay.get_children():
		if not (c is Control) or not c.visible:
			continue
		if c == pause_menu or c == title_menu or c is MenuPanel or c is EndingScreen or (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			return true
	return false


func _typing() -> bool:
	var fo := get_viewport().gui_get_focus_owner()
	return fo is LineEdit or fo is TextEdit


func _process(delta: float) -> void:
	if not _world_on():
		return
	var playing := mode == Mode.GAME and not get_tree().paused and not _menu_open()
	var capture: bool = playing and (phone_mode == "own" or not phone_raised) and not world.peeping and not is_instance_valid(_say_box)
	var want := Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want and DisplayServer.get_name() != "headless":
		Input.mouse_mode = want
	world.player.look_enabled = capture and not world.dying
	world.player.move_enabled = playing and not world.peeping and not world.dying and world.hold_t <= 0.0 and not (phone_raised and _typing())
	# the lit screen in his hand is what it notices most (R4)
	world.presence.screen_on = playing and (phone_raised if phone_mode == "game" else GameState.current_app != "")
	world.hud.update_from(world.player)
	_pos_save_t -= delta
	if _pos_save_t <= 0.0 and mode == Mode.GAME:
		_pos_save_t = 1.0
		var p: Vector3 = world.player.global_position
		GameState.data["w_pos"] = [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01), snappedf(world.player.yaw_deg(), 0.1)]


func _input(event: InputEvent) -> void:
	if mode != Mode.GAME or not _world_on() or get_tree().paused:
		return
	if event.is_action_pressed("phone_toggle") and not event.is_echo():
		if phone_mode == "game":
			if not _typing():
				set_phone_raised(not phone_raised)
				get_viewport().set_input_as_handled()
		else:
			world.player.think("O telemóvel está contigo.")
			get_viewport().set_input_as_handled()


func show_title() -> void:
	mode = Mode.TITLE
	set_phone_mode("game")
	if Coop.active:
		Coop.leave()
	Content.set_role("daniel")
	Clock.external = false
	GameState.in_game = false
	Director.stop()
	leave_world()
	_title_phone_state()
	title_menu.open()
	phone.refresh_all()
	phone.show_locked_immediately()
	room.set_mood("title")
	Audio.set_ambient("room")
	# after the quiet endings, the title keeps their music box
	Audio.set_music("lullaby" if str(Achievements.stats.get("last_ending", "")) in ["C", "D"] else "menu")


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
	_phone_off = false
	if not Coop.active:
		Content.set_role("daniel")
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
	if Content.role == "daniel":
		enter_world()


func continue_game(slot: String) -> bool:
	if not Saves.load_from(slot):
		return false
	_phone_off = GameState.flag("w_phone_off")
	title_menu.visible = false
	pause_menu.visible = false
	get_tree().paused = false
	Audio.set_music("")
	mode = Mode.GAME
	if Content.role == "daniel":
		enter_world("saved")
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
		"ch01", "ch02", "ch04", "ch06", "ch09", "ch11", "ch12": return "room"
		_: return "night"


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_say_box) and event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.physical_keycode - KEY_1
		var pending: Dictionary = GameState.data.choices.get("aqui", {})
		if n >= 0 and not pending.is_empty() and n < pending.options.size():
			Director.pick_choice("aqui", int(pending.options[n].index))
			get_viewport().set_input_as_handled()
			return
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


## "Prólogo", or "IV · Investigação".
static func chapter_label(ch: String) -> String:
	var roman := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV"]
	var n := int(ch.substr(2)) if ch.begins_with("ch") else -1
	if n == 0:
		return "Prólogo · %s" % Content.chapter_title(ch)
	return "%s · %s" % [roman[n - 1] if n >= 1 and n <= roman.size() else "", Content.chapter_title(ch)]


# ---------------------------------------------------------------- the story, in person
func _on_main_cue(cmd: String, args: Array) -> void:
	match cmd:
		"phone":
			# phone off|on — the game's phone is not in this memory; down — into the pocket
			if args.size() > 0 and args[0] == "down":
				set_phone_raised(false)
				return
			_phone_off = args.size() > 0 and args[0] == "off"
			GameState.set_var("w_phone_off", _phone_off)
			if _phone_off:
				set_phone_raised(false)
				phone_holder.visible = false
			if _world_on():
				world.hud.show_phone_hint = phone_mode == "game" and not _phone_off
		"fade":
			var t := create_tween()
			t.tween_property(fade, "modulate:a", 1.0 if args.size() == 0 or args[0] == "out" else 0.0, float(args[1]) if args.size() > 1 else 1.5)
		"title":
			# title É isto que tu lembras. — white on black, then gone
			var l := UI.label(" ".join(PackedStringArray(args)), 26, "text", true)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			l.custom_minimum_size = Vector2(800, 0)
			l.position = Vector2(size.x / 2.0 - 400, size.y / 2.0 - 20)
			l.modulate.a = 0.0
			overlay.add_child(l)
			var t2 := l.create_tween()
			t2.tween_property(l, "modulate:a", 1.0, 1.4)
			t2.tween_interval(3.2)
			t2.tween_property(l, "modulate:a", 0.0, 1.4)
			t2.tween_callback(l.queue_free)


func _show_say_choices() -> void:
	_hide_say_choices()
	var pending: Dictionary = GameState.data.choices.get("aqui", {})
	if pending.is_empty():
		return
	var box := UI.panel(Color(0.03, 0.035, 0.045, 0.82), 12, 18, 12, 18, 12)
	var v := UI.vbox(8)
	box.add_child(v)
	var k := 0
	for o in pending.options:
		k += 1
		var idx: int = o.index
		var b := UI.pill_button("%d   %s" % [k, str(o.text)], func(): Director.pick_choice("aqui", idx), "surf2", "text", 17)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	overlay.add_child(box)
	_say_box = box
	await get_tree().process_frame
	if is_instance_valid(box):
		box.position = Vector2((size.x - box.size.x) / 2.0, size.y - 250 - box.size.y)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_say_choices() -> void:
	if is_instance_valid(_say_box):
		_say_box.queue_free()
	_say_box = null


# ---------------------------------------------------------------- caught (R7–R9)
## It reached him. A glimpse, black, silence — and the chapter starts again,
## with something not quite as it was. Nobody ever says he died.
func _on_caught(at: Vector3) -> void:
	if _dying or mode != Mode.GAME:
		return
	_dying = true
	var ch := str(GameState.data.chapter)
	var deaths := int(GameState.get_var("deaths_" + ch, 0)) + 1
	var total := int(GameState.get_var("deaths_total", 0)) + 1
	var run := str(GameState.get_var("run_id", ""))
	var death_at := world.player.global_position
	var death_hm := Clock.fmt_time(Clock.now())
	var death_loc := world.location.loc_id
	await world.death_glimpse(at)
	fade.modulate.a = 1.0
	Audio.cut_all()
	await get_tree().create_timer(2.6).timeout
	var snap := Saves.read_slot("chapter")
	var same: bool = not snap.is_empty() and str(snap.meta.get("chapter", "")) == ch \
		and str(snap.state.get("flags", {}).get("run_id", "")) == run
	if not (same and Saves.load_from("chapter")):
		Director.start_chapter(ch)
	GameState.set_var("deaths_" + ch, deaths)
	GameState.set_var("deaths_total", total)
	GameState.set_var("ja_falamos", true)
	GameState.set_var("last_death_pos", [death_at.x, death_at.y, death_at.z])
	GameState.set_var("last_death_loc", death_loc)
	GameState.set_var("last_death_hm", death_hm)
	world.revive()
	# the place as it was when the chapter began (then one thing moved, below)
	var loc := str(GameState.data.get("location", "casa"))
	if GameWorld.LOCATIONS.has(loc):
		world.go_to(loc, "", true)
	_shown_loc = ""
	enter_world("")
	Audio.set_ambient(_chapter_ambient(ch))
	world.presence.leave_marks(deaths)
	_dying = false
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(fade, "modulate:a", 0.0, 2.2)


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
	if _world_on():
		tw.parallel().tween_property(fade, "modulate:a", 1.0, 1.6)
	await tw.finished
	Audio.set_ambient("", 2.5)
	caption.text = "%s\n%s\n\n[ %s ]" % [Clock.fmt_date_long(start_unix), Clock.fmt_time(start_unix), chapter_label(nxt)]
	# an epigraph on the other side of the phone (public-domain Pessoa)
	var ep: Array = Content.db.get("chapters_meta", {}).get("epigraphs", {}).get(nxt, [])
	var epl: Label = null
	if ep.size() == 2:
		epl = UI.label("%s\n\n— %s" % [ep[0], ep[1]], 17, "dim", true)
		var left := size.x / 2 + phone.custom_minimum_size.x * phone_holder.scale.x / 2 + 50
		if _world_on():
			left = size.x / 2 + 60
		epl.custom_minimum_size = Vector2(clampf(size.x - left - 40, 160, 360), 0)
		epl.position = Vector2(left, size.y / 2 - 40)
		epl.modulate.a = 0.0
		add_child(epl)
	var tw2 := create_tween()
	tw2.tween_property(caption, "modulate:a", 1.0, 1.4)
	if epl:
		tw2.parallel().tween_property(epl, "modulate:a", 1.0, 2.4)
	tw2.tween_interval(3.6 if epl else 2.8)
	tw2.tween_property(caption, "modulate:a", 0.0, 1.2)
	if epl:
		tw2.parallel().tween_property(epl, "modulate:a", 0.0, 1.2)
	await tw2.finished
	if epl:
		epl.queue_free()
	Director.advance_chapter()
	phone.show_locked_immediately()
	Audio.set_ambient(_chapter_ambient(nxt))
	if _world_on():
		world.spawn(_spawn_for_chapter())
		_apply_chapter_lights()
	var tw3 := create_tween()
	tw3.tween_property(phone_holder, "modulate", Color.WHITE, 1.2)
	if _world_on():
		tw3.parallel().tween_property(fade, "modulate:a", 0.0, 2.0)
	mode = Mode.GAME


# ---------------------------------------------------------------- endings
func _on_ending(id: String) -> void:
	mode = Mode.ENDING
	Director.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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


# ---------------------------------------------------------------- which phone
## Asks which phone this session uses, then runs `then` (start or continue).
func choose_phone_then(then: Callable) -> void:
	var p := PhoneChoicePanel.new()
	p.chosen.connect(func(m: String):
		set_phone_mode(m)
		then.call())
	overlay.add_child(p)


func set_phone_mode(m: String) -> void:
	if m == phone_mode:
		return
	phone_mode = m
	if m == "own":
		if phone_vp == null:
			phone_vp = SubViewport.new()
			phone_vp.size = Vector2i(UI.SCREEN * STREAM_SCALE)
			phone_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			phone_vp.transparent_bg = false
			add_child(phone_vp)
		phone.reparent(phone_vp, false)
		phone.theme = theme
		phone.scale = Vector2.ONE * STREAM_SCALE
		phone.position = -Vector2(Phone.BEZEL, Phone.BEZEL) * STREAM_SCALE
		phone._base_pos = phone.position
		phone_holder.visible = false
		Companion.stream_vp = phone_vp
		_own_clock.text = Clock.fmt_time(Clock.now()) if GameState.in_game else ""
	else:
		phone.reparent(phone_holder, false)
		phone.theme = null
		phone.scale = Vector2.ONE
		phone.position = -phone.custom_minimum_size / 2.0
		phone_holder.visible = true
		Companion.stream_vp = null
		_layout()
	Companion.stream_changed()
	own_hud.visible = m == "own" and not _world_on()
	if _world_on():
		world.hud.show_phone_hint = m == "game"
		world.hud.set_phone_idle()
		phone_raised = m == "game"
		_layout()


## What the PC shows while the phone is in the player's hand.
func _build_own_hud() -> void:
	own_hud = Control.new()
	own_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	own_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	own_hud.visible = false
	add_child(own_hud)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	own_hud.add_child(c)
	var v := UI.vbox(8)
	c.add_child(v)
	_own_clock = UI.label("", 64, "text")
	_own_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_own_clock.modulate.a = 0.85
	v.add_child(_own_clock)
	var l := UI.label("O telemóvel está contigo.", 18, "dim")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var k := UI.label("Esc · pausa", 13, "faint")
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(k)
	Events.time_changed.connect(func(t): if own_hud.visible: _own_clock.text = Clock.fmt_time(t))
	# the light outside follows the game clock
	Events.time_changed.connect(func(_t):
		if _world_on():
			var hr := _hour_now()
			if absf(hr - _last_hour) > 0.08:
				_last_hour = hr
				world.set_hour(hr))


## The own phone dropped out mid-session: wait a moment, then pause and show
## the QR code again (or let the player switch to the phone on the PC).
func _on_phone_clients(n: int) -> void:
	if n > 0:
		if is_instance_valid(_reconnect):
			_reconnect.queue_free()
			_reconnect = null
			get_tree().paused = false
		return
	if phone_mode != "own" or mode != Mode.GAME:
		return
	await get_tree().create_timer(4.0, true).timeout
	if Companion.client_count() > 0 or phone_mode != "own" or mode != Mode.GAME or is_instance_valid(_reconnect):
		return
	get_tree().paused = true
	_reconnect = PhoneChoicePanel.new()
	_reconnect.mode = "reconnect"
	_reconnect.chosen.connect(func(m: String):
		_reconnect = null
		set_phone_mode(m)
		get_tree().paused = false)
	overlay.add_child(_reconnect)


# ---------------------------------------------------------------- co-op
func _on_coop_start(as_host: bool) -> void:
	for c in overlay.get_children() + title_menu.get_children() + pause_menu.get_children():
		if c is CoopPanel:
			c.queue_free()
	pause_menu.visible = false
	get_tree().paused = false
	Content.set_role("daniel" if as_host else "sofia")
	choose_phone_then(func(): _coop_begin(as_host))


func _coop_begin(as_host: bool) -> void:
	start_new_game(false)
	Events.toast_requested.emit("És o Daniel. A Sofia está do outro lado." if as_host else "És a Sofia. O Daniel está do outro lado.")


## A short message on screen outside the phone (e.g. why co-op ended).
func _notice(text: String) -> void:
	var p := MenuPanel.new()
	overlay.add_child(p)
	p.make("Jogo online", 520, true)
	p.body.add_child(UI.label(text, 16, "text", true))
