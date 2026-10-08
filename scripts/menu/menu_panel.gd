class_name MenuPanel
extends Control
## Base for out-of-fiction menus: a dim backdrop and a centred column.

signal closed

var body: VBoxContainer
var _title: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func make(title: String, width := 560.0, compact := false) -> void:
	UI.clear(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UI.panel(Color("0e1013"), 14, 34, 28, 34, 28)
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	_title = UI.label(title, 26)
	v.add_child(_title)
	v.add_child(UI.separator())
	body = UI.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if compact:
		# short dialogs: no scroll area, the panel hugs its content
		v.add_child(body)
	else:
		var sc := UI.scroll()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.add_child(body)
		v.add_child(sc)
		sc.custom_minimum_size.y = minf(620.0, get_viewport_rect().size.y - 260.0) if is_inside_tree() else 560.0
	var back := UI.pill_button("Voltar", close, "surf2")
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(back)


func close() -> void:
	queue_free()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


static func menu_button(text: String, cb: Callable, size := 22) -> Button:
	var b := UI.button(text, cb, size)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(320, 48)
	b.add_theme_color_override("font_hover_color", UI.c("accent"))
	b.add_theme_color_override("font_focus_color", UI.c("accent"))
	return b
