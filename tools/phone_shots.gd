extends Node
## Photographs every phone screen into a folder, for looking at the design.
##   xvfb-run -a godot --resolution 900x960 res://tools/phone_shots.tscn -- <out_dir> [only]
## The game runs chapter 1 in fast mode for a while first, so the apps have
## messages, photos and mail in them.
## "demo" plays a short tour with sound, to record as a video:
##   godot --write-movie demo.avi --fixed-fps 30 res://tools/phone_shots.tscn -- <dir> demo

var phone: Phone
var out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://phone_shots"
	var only: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	Audio.muted_for_tests = true
	var bg := ColorRect.new()
	bg.color = Color("2a2c30")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Director.fast_mode = true
	Director.auto_chooser = func(_t, pending): return pending.options[0].index
	Director.auto_answer = func(_c): return true
	Director.new_game()
	GameState.in_game = true
	Director.start_chapter("ch01")
	for i in 400:
		await get_tree().process_frame
	Director.stop()
	phone = Phone.new()
	phone.position = Vector2(20, 20)
	add_child(phone)
	await _frames(3)
	phone.refresh_all()
	var shots := [
		["lock", func(): phone.show_locked_immediately()],
		["home", func(): phone.unlock(true)],
		["banner", func():
			Events.notification_posted.emit({"app": "messages", "title": "Sofia", "body": "Já chegaste? Liga-me quando puderes.", "t": Clock.now()})],
		["shade", func(): phone.open_shade()],
		["call", func():
			phone.close_shade()
			phone._on_call({"id": "x", "who": "sofia", "dir": "in", "unknown": false, "number": "", "t": Clock.now()})],
	]
	for id in Phone.APPS:
		shots.append(["app_" + id, func():
			phone._call_ui.visible = false
			phone.open_app(id, {"forced": true})])
	shots.append(["thread", func():
		phone.open_app("messages", {"forced": true, "param": GameState.data.threads.keys()[0]})])
	if only == "demo":
		await _demo()
		get_tree().quit()
		return
	if only == "anim":
		# an app growing out of its icon, then shrinking back into it
		phone.unlock(true)
		await get_tree().create_timer(0.5).timeout
		var icon: Control = phone.home.find_children("Icon", "", true, false)[1]
		phone._launch_from = icon.get_global_rect()
		phone.open_app("gallery")
		for k in 5:
			await _snap("anim_open_%d" % k)
			await get_tree().create_timer(0.06).timeout
		await get_tree().create_timer(0.6).timeout
		phone.go_home()
		for k in 5:
			await _snap("anim_close_%d" % k)
			await get_tree().create_timer(0.06).timeout
		get_tree().quit()
		return
	for s in shots:
		s[1].call()
		await _frames(2)
		await get_tree().create_timer(0.7).timeout
		if only == "" or (s[0] as String).begins_with(only):
			await _snap(s[0])
	get_tree().quit()


func _snap(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	# the window may be stretched: crop where the phone really is in the image
	var gr := get_viewport().get_final_transform() * phone.get_global_rect()
	var r := Rect2i(gr.grow(10))
	img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))).save_png(out.path_join(shot_name + ".png"))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## A tour of the phone, with its sounds: a message on the lock screen,
## unlocking, a mail banner, apps opening from their icons, the shade, a call.
func _demo() -> void:
	Audio.muted_for_tests = false
	var gr := get_viewport().get_final_transform() * phone.get_global_rect()
	print("DEMO_START frame=%d crop=%d:%d:%d:%d" % [Engine.get_frames_drawn(), int(gr.size.x) + 20, int(gr.size.y) + 20, int(gr.position.x) - 10, int(gr.position.y) - 10])
	phone.show_locked_immediately()
	await _wait(1.5)
	var n := GameState.post_notification("messages", "Sofia", "Estás acordado?", {"thread": "sofia", "t": Clock.now()})
	Events.notification_posted.emit(n)
	await _wait(2.5)
	phone.unlock()
	await _wait(2.0)
	var m := GameState.post_notification("email", "Clínica Atlântico", "Lembrete: a sua consulta é amanhã", {"t": Clock.now()})
	Events.notification_posted.emit(m)
	await _wait(3.0)
	await _tap_icon("messages")
	await _wait(1.4)
	if phone.current_app and phone.current_app.has_method("_open_thread"):
		phone.current_app.slide()
		phone.current_app._open_thread("sofia")
	await _wait(2.5)
	phone.go_home()
	await _wait(1.2)
	await _tap_icon("gallery")
	await _wait(2.2)
	phone.go_home()
	await _wait(1.2)
	await _tap_icon("settings")
	await _wait(2.0)
	phone.go_home()
	await _wait(1.0)
	phone.open_shade()
	await _wait(2.2)
	phone.close_shade()
	await _wait(0.8)
	phone._on_call({"id": "demo", "who": "sofia", "dir": "in", "unknown": false, "number": "", "t": Clock.now()})
	Audio.start_ring(false)
	await _wait(6.5)
	Audio.stop_ring()
	phone._call_ui.visible = false
	await _wait(0.6)
	phone._on_call({"id": "demo2", "who": "unknown", "dir": "in", "unknown": true, "number": "", "t": Clock.now()})
	Audio.start_ring(true)
	await _wait(7.0)
	Audio.stop_ring()
	phone._call_ui.visible = false
	await _wait(1.0)


func _tap_icon(id: String) -> void:
	for b in phone.home.find_children("*", "Button", true, false):
		if b.tooltip_text == Phone.APPS[id].name:
			var icon: Control = b.get_node("Icon")
			phone._launch_from = icon.get_global_rect()
			b.button_down.emit()
			await _wait(0.12)
			b.button_up.emit()
			phone.open_app(id)
			return
	phone.open_app(id)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
