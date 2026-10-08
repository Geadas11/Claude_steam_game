class_name EndingScreen
extends Control
## Plays an ending: the phone goes dark, then lines of text, then a summary.

var main: Node
var _v: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func play(id: String) -> void:
	var e := Content.get_item("endings", id)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bg, "modulate:a", 1.0, 2.5)
	await tw.finished
	Audio.set_ambient("", 3.0)
	Audio.set_music(e.get("music", "memory"))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_v = UI.vbox(18)
	_v.custom_minimum_size = Vector2(760, 0)
	center.add_child(_v)
	for line in e.get("lines", []):
		var l := UI.label(str(line), 20, "text", true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		_v.add_child(l)
		var t2 := create_tween()
		t2.tween_property(l, "modulate:a", 1.0, 1.4)
		await get_tree().create_timer(1.6 + str(line).length() * 0.045).timeout
		# keep only the last few lines visible
		if _v.get_child_count() > 5:
			_v.get_child(0).queue_free()
	await get_tree().create_timer(2.5).timeout
	UI.clear(_v)
	var title := UI.label("FINAL %s — %s" % [id, str(e.get("name", "")).to_upper()], 30, "accent")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v.add_child(title)
	var summ := UI.label(str(e.get("summary", "")), 16, "dim", true)
	summ.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v.add_child(summ)
	_v.add_child(UI.spacer(20))
	var pt := int(GameState.data.playtime)
	var total_clues := Content.all("clues").size()
	var stats := "Tempo de jogo: %dh%02d   ·   Pistas: %d / %d   ·   Finais descobertos: %d / %d" % [pt / 3600, (pt / 60) % 60, GameState.clue_count(), total_clues, Achievements.endings.size(), Content.all("endings").size()]
	var sl := UI.label(stats, 14, "faint")
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_v.add_child(sl)
	if e.get("hint", "") != "":
		var h := UI.label(str(e.hint), 14, "faint", true)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_v.add_child(h)
	_v.add_child(UI.spacer(30))
	var b := UI.pill_button("Voltar ao menu", func():
		queue_free()
		main.show_title(), "surf2", "text", 16)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_v.add_child(b)
	b.grab_focus()
	_v.modulate.a = 0.0
	create_tween().tween_property(_v, "modulate:a", 1.0, 1.5)
