extends Node
## Photographs the "which phone?" and QR screens (design QA).
##   xvfb-run -a godot --resolution 1280x720 res://tools/qr_shots.tscn -- <out_dir>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	Audio.muted_for_tests = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.build_theme()
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color("15171b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var p := PhoneChoicePanel.new()
	root.add_child(p)
	await _wait(1.0)
	await _snap(out.path_join("choice.png"))
	p._show_qr(false)
	await _wait(1.6)
	await _snap(out.path_join("qr.png"))
	p._update(1)
	await _wait(0.5)
	await _snap(out.path_join("qr_ok.png"))
	get_tree().quit()


func _snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
