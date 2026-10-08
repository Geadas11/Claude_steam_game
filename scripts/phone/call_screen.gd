class_name CallScreen
extends Control
## Incoming / active call overlay. Dialogue arrives as Events.call_line and is
## shown as live subtitles.

var phone: Phone
var _call: Dictionary = {}
var _name: Label
var _status: Label
var _avatar: Avatar
var _lines: VBoxContainer
var _scroll: ScrollContainer
var _incoming_box: Control
var _active_box: Control
var _connected := false
var _elapsed := 0.0
var _line_player: AudioStreamPlayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("0a0c0f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(0.2, 0.35, 0.3, 0.16))
	gr.set_color(1, Color(0.2, 0.35, 0.3, 0.0))
	gt.gradient = gr
	glow.texture = gt
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.position = Vector2.ZERO
	glow.size = Vector2(UI.SCREEN.x, 420)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var v := UI.vbox(10)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 80
	v.offset_bottom = -50
	add_child(v)
	_avatar = UI.avatar("", 96)
	_avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_avatar)
	_name = UI.label("", 26)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_name)
	_status = UI.label("", 15, "dim")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status)
	v.add_child(UI.spacer(10))
	_scroll = UI.scroll()
	var m := UI.margin(24, 0, 24, 0)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lines = UI.vbox(10)
	_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(_lines)
	_scroll.add_child(m)
	v.add_child(_scroll)
	# incoming buttons
	_incoming_box = UI.hbox(0)
	_incoming_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_incoming_box.add_theme_constant_override("separation", 110)
	_incoming_box.add_child(_round_button("hangup", UI.c("danger"), "Recusar", func(): Events.call_response.emit(false)))
	_incoming_box.add_child(_round_button("call", UI.c("ok"), "Atender", func(): Events.call_response.emit(true)))
	v.add_child(_incoming_box)
	_active_box = UI.vbox(16)
	var tools := UI.hbox(0)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 46)
	for g in ["mic", "keypad", "speaker"]:
		var b := UI.icon_button(g, func(): pass, 50, "dim")
		b.add_theme_stylebox_override("normal", UI.box(Color(1, 1, 1, 0.07), 25))
		tools.add_child(b)
	_active_box.add_child(tools)
	var hb := UI.hbox(0)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(_round_button("hangup", UI.c("danger"), "Desligar", func(): Director.hangup()))
	_active_box.add_child(hb)
	v.add_child(_active_box)
	Events.call_line.connect(_on_line)
	Events.call_ended.connect(_on_ended)


func _round_button(glyph: String, col: Color, label_text: String, cb: Callable) -> Control:
	var v := UI.vbox(6)
	var b := UI.icon_button(glyph, cb, 70, "text")
	b.add_theme_stylebox_override("normal", UI.box(col.darkened(0.15), 35))
	b.add_theme_stylebox_override("hover", UI.box(col, 35))
	b.add_theme_stylebox_override("pressed", UI.box(col.lightened(0.1), 35))
	b.tooltip_text = label_text
	v.add_child(b)
	var l := UI.label(label_text, 13, "dim")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


func _caller_name(call: Dictionary) -> String:
	if call.get("unknown", false):
		return "Número privado"
	if str(call.get("number", "")) != "":
		return call.number
	return GameState.contact_name(call.get("who", ""))


func show_incoming(call: Dictionary) -> void:
	_call = call
	_connected = false
	UI.clear(_lines)
	_avatar.contact_id = "" if call.get("unknown", false) else call.who
	_name.text = _caller_name(call)
	_status.text = "Chamada recebida"
	_incoming_box.visible = true
	_active_box.visible = false
	visible = true
	modulate.a = 1.0
	_pulse()


func _pulse() -> void:
	if not visible or _connected:
		return
	var tw := create_tween()
	tw.tween_property(_avatar, "modulate:a", 0.55, 0.6)
	tw.tween_property(_avatar, "modulate:a", 1.0, 0.6)
	tw.tween_callback(_pulse)


func show_connected(call: Dictionary) -> void:
	_call = call
	_connected = call.dir != "out"
	_elapsed = 0.0
	if call.dir == "out":
		UI.clear(_lines)
		_avatar.contact_id = call.who
		_name.text = _caller_name(call)
		_status.text = "A ligar…"
	else:
		_status.text = "00:00"
	_avatar.modulate.a = 1.0
	_incoming_box.visible = false
	_active_box.visible = true
	visible = true
	modulate.a = 1.0


func _process(delta: float) -> void:
	if visible and _connected:
		_elapsed += delta
		_status.text = "%02d:%02d" % [int(_elapsed) / 60, int(_elapsed) % 60]


func _on_line(who: String, text: String) -> void:
	if not visible:
		return
	if not _connected:
		_connected = true
		_elapsed = 0.0
	var is_caption := who == "" and text.begins_with("[")
	if is_caption and not (Settings.get_value("sound_captions", false) or Settings.get_value("subtitles", true)):
		return
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", UI.fs(16))
	l.add_theme_font_size_override("italics_font_size", UI.fs(15))
	l.add_theme_font_size_override("bold_font_size", UI.fs(14))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if who == "":
		l.text = "[center][i][color=#%s]%s[/color][/i][/center]" % [UI.c("faint").to_html(false), _esc(text)]
	elif who == "me":
		l.text = "[b][color=#%s]Tu[/color][/b]\n%s" % [UI.c("dim").to_html(false), _esc(text)]
	else:
		var nm := _caller_name(_call) if who == _call.get("who", "") else GameState.contact_name(who)
		l.text = "[b][color=#%s]%s[/color][/b]\n%s" % [UI.c("accent").to_html(false), _esc(nm), _esc(text)]
	_lines.add_child(l)
	l.modulate.a = 0.0
	create_tween().tween_property(l, "modulate:a", 1.0, 0.25)
	# dim older lines so the newest reads as "now"
	var n := _lines.get_child_count()
	for i in n - 1:
		_lines.get_child(i).modulate.a = clampf(0.35 + 0.65 * float(i) / n, 0.35, 0.8)
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


static func _esc(t: String) -> String:
	return t.replace("[", "[lb]")


func _on_ended(call: Dictionary) -> void:
	if not visible:
		return
	_incoming_box.visible = false
	_active_box.visible = false
	_status.text = "Chamada perdida" if call.get("result", "") in ["missed", "declined"] else "Chamada terminada"
	_connected = false
	var tw := create_tween()
	tw.tween_interval(1.3)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		visible = false
		modulate.a = 1.0)
