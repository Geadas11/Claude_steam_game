extends Node
## Photographs every phone screen into a folder, for looking at the design.
##   xvfb-run -a godot --resolution 900x960 res://tools/phone_shots.tscn -- <out_dir> [only]
## The game runs chapter 1 in fast mode for a while first, so the apps have
## messages, photos and mail in them.

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
