class_name LockScreen
extends Control
## Lock screen: clock, date, notifications, swipe/click to unlock, PIN pad.

var phone: Phone
var _clock: Label
var _date: Label
var _notifs: VBoxContainer
var _hint: Label
var _pin_box: Control
var _pin_dots: HBoxContainer
var _pin_msg: Label
var _pin := ""
var _pin_fails := 0
var _content: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var grad := ColorRect.new()
	grad.color = Color(0, 0, 0, 0.35)
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)
	_content = UI.vbox(4)
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 70
	_content.offset_bottom = -30
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	var lockg := UI.glyph("lock", 22, "dim")
	lockg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.add_child(lockg)
	_clock = UI.label("", 76)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_clock)
	_date = UI.label("", 16, "dim")
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_date)
	_content.add_child(UI.spacer(26))
	var sc := UI.scroll()
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	var m := UI.margin(12, 0, 12, 0)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notifs = UI.vbox(8)
	_notifs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(_notifs)
	sc.add_child(m)
	_content.add_child(sc)
	_hint = UI.label("Clica para desbloquear", 13, "faint")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_hint)
	_build_pin()
	update_clock()
	refresh_notifications()


func _build_pin() -> void:
	_pin_box = UI.vbox(14)
	_pin_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pin_box.offset_top = 150
	_pin_box.offset_bottom = -40
	_pin_box.visible = false
	add_child(_pin_box)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin_box.add_child(bg)
	var t := UI.label("Introduz o PIN", 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_box.add_child(t)
	var sub := UI.label("É necessário o PIN após reiniciar", 13, "dim")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_box.add_child(sub)
	_pin_dots = UI.hbox(14)
	_pin_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 4:
		_pin_dots.add_child(UI.glyph("dot", 26, "dim"))
	_pin_box.add_child(_pin_dots)
	_pin_msg = UI.label("", 13, "danger", true)
	_pin_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_msg.custom_minimum_size = Vector2(0, 40)
	_pin_box.add_child(_pin_msg)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "?", "0", "<"]:
		var b: Button
		if k == "?":
			b = UI.button("Dica", _show_hint, 13, "dim")
		elif k == "<":
			b = UI.button("Apagar", func():
				_pin = _pin.substr(0, maxi(0, _pin.length() - 1))
				_update_dots(), 13, "dim")
		else:
			b = UI.button(k, func(): _pin_digit(k), 26)
			var sb := UI.box(Color(1, 1, 1, 0.08), 34)
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.14), 34))
		b.custom_minimum_size = Vector2(68, 68)
		grid.add_child(b)
	_pin_box.add_child(grid)


func update_clock() -> void:
	if _clock == null:
		return
	_clock.text = Clock.display_time()
	_date.text = Clock.fmt_date_long(Clock.now())


func refresh_notifications() -> void:
	if _notifs == null:
		return
	UI.clear(_notifs)
	var shown := 0
	var grouped := {}
	for n in GameState.data.notifications:
		var key: String = n.app + "|" + str(n.title)
		if grouped.has(key):
			grouped[key].count += 1
			continue
		grouped[key] = {"n": n, "count": 1}
	for key in grouped:
		if shown >= 6:
			break
		var g: Dictionary = grouped[key]
		_notifs.add_child(_card(g.n, g.count))
		shown += 1


func _card(n: Dictionary, count: int) -> Control:
	var info: Dictionary = Phone.APPS.get(n.app, {"glyph": "dot", "color": "#444"})
	var h := UI.hbox(12)
	var ic := Phone.AppIcon.new()
	ic.glyph = info.glyph
	ic.bg = Color(info.color)
	ic.custom_minimum_size = Vector2(34, 34)
	h.add_child(ic)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UI.hbox(6)
	var t := UI.label(str(n.title) + ("  (%d)" % count if count > 1 else ""), 14)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(t)
	top.add_child(UI.label(Clock.fmt_relative(float(n.t)), 12, "faint"))
	v.add_child(top)
	var b := UI.label(str(n.body), 13, "dim")
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(b)
	h.add_child(v)
	var row := UI.row(h, func():
		if GameState.data.phone.get("pin_required", false):
			return
		phone.unlock()
		phone.open_app(n.app, n), 64)
	row.add_theme_stylebox_override("normal", UI.box(Color(0.12, 0.13, 0.15, 0.85), 16))
	row.add_theme_stylebox_override("hover", UI.box(Color(0.16, 0.17, 0.19, 0.9), 16))
	return row


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_unlock()


func try_unlock() -> void:
	if not visible:
		return
	if GameState.data.phone.get("pin_required", false):
		_show_pin()
		return
	phone.unlock()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not _pin_box.visible:
		return
	if event is InputEventKey and event.pressed:
		var ch := char(event.unicode) if event.unicode > 0 else ""
		if ch >= "0" and ch <= "9" and ch.length() == 1:
			_pin_digit(ch)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			_pin = _pin.substr(0, maxi(0, _pin.length() - 1))
			_update_dots()
			get_viewport().set_input_as_handled()


func _show_pin() -> void:
	_pin_box.visible = true
	_content.visible = false
	_pin = ""
	_update_dots()


func _pin_digit(d: String) -> void:
	if _pin.length() >= 4:
		return
	_pin += d
	Audio.play("tap", -6.0)
	_update_dots()
	if _pin.length() == 4:
		_check_pin()


func _update_dots() -> void:
	for i in 4:
		var g: Glyph = _pin_dots.get_child(i)
		g.color = UI.c("text") if i < _pin.length() else Color(1, 1, 1, 0.18)


func _check_pin() -> void:
	if _pin == str(GameState.data.phone.get("pin", "1410")):
		GameState.data.phone.pin_required = false
		GameState.set_var("pin_ok", true)
		_pin_msg.text = ""
		_pin_box.visible = false
		_content.visible = true
		phone.unlock()
		return
	_pin_fails += 1
	GameState.inc_var("pin_fails")
	Audio.play("error")
	_pin = ""
	_update_dots()
	_pin_msg.add_theme_color_override("font_color", UI.c("danger"))
	_pin_msg.text = "PIN incorreto."
	if _pin_fails >= 3:
		_show_hint()
	if _pin_fails >= 8:
		_pin_msg.text = "Dica: dia e mês. Ela sabia."


func _show_hint() -> void:
	_pin_msg.add_theme_color_override("font_color", UI.c("dim"))
	_pin_msg.text = "Dica definida por ti: \"o dia em que deixei de dormir\""


func show_lock(instant := false) -> void:
	visible = true
	_content.visible = true
	_pin_box.visible = false
	refresh_notifications()
	update_clock()
	if instant or Settings.get_value("reduce_motion", false):
		position.y = 0
		modulate.a = 1.0
		return
	modulate.a = 0.0
	position.y = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func hide_lock() -> void:
	GameState.clear_notifications()
	if Settings.get_value("reduce_motion", false):
		visible = false
		return
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", -UI.SCREEN.y * 0.4, 0.28)
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(func():
		visible = false
		position.y = 0)
