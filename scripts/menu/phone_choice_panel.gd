class_name PhoneChoicePanel
extends MenuPanel
## Asked once per session, before playing: which phone is the phone of the
## game? The player's own phone (paired with a QR code) or the one on the PC
## screen. The other one does not appear in that session.
##
## mode "choose": both options; "reconnect": the own phone was lost mid-game.

signal chosen(mode: String)   # "own" or "game"

var mode := "choose"
var allow_back := false   # "reconnect" opened from the pause menu can be dismissed
var _status: Label
var _status_dot: Panel
var _status_sub: Label
var _done := false


func _ready() -> void:
	no_back = mode == "reconnect" and not allow_back
	if mode == "reconnect":
		_show_qr(true)
	else:
		_show_choice()


# ================================================================ backdrop
## Both screens are full screen, in the game's night: grain, a red standby
## glow, a big thin line of text. Returns the root to lay things out in.
func _scene(glow_x: float) -> Control:
	UI.clear(self)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/ui/night_backdrop.gdshader")
	mat.set_shader_parameter("glow_at", Vector2(glow_x, 0.5))
	bg.material = mat
	add_child(bg)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	if UI.motion_ok():
		root.modulate.a = 0.0
		create_tween().tween_property(root, "modulate:a", 1.0, 0.6)
	return root


func _kicker(text: String) -> Control:
	var h := UI.hbox(10)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(9, 9)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", UI.box(Color("e04545"), 5))
	h.add_child(dot)
	var l := UI.label(text.to_upper(), 13, "dim")
	l.add_theme_font_override("font", UI.font("semibold"))
	l.add_theme_constant_override("outline_size", 0)
	h.add_child(l)
	_pulse(dot)
	return h


func _pulse(c: Control) -> void:
	if not UI.motion_ok():
		return
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "modulate:a", 0.2, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _big(text: String, size := 54) -> Label:
	var l := UI.label(text, size)
	l.add_theme_font_override("font", UI.font("display"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _back_row(extra: Array) -> Control:
	var h := UI.hbox(12)
	for e in extra:
		h.add_child(e)
	h.add_child(UI.expand())
	if not no_back:
		h.add_child(UI.pill_button("Voltar", close, "surf2", "dim"))
	return h


# ================================================================ choice
func _show_choice() -> void:
	var root := _scene(0.5)
	var m := UI.margin(90, 70, 90, 54)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(m)
	var v := UI.vbox(18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)
	v.add_child(_kicker("antes de começar"))
	v.add_child(_big("Que telemóvel vais usar?"))
	v.add_child(UI.label("Mensagens, chamadas, fotografias: é por ele que a história te chega. Escolhe onde o queres ter esta noite.", 17, "dim", true))
	v.add_child(UI.spacer(10))
	var cards := UI.hbox(22)
	var own := _option("mobile", "O meu telemóvel", "O teu telemóvel passa a ser o do Daniel: ecrã inteiro, toque, vibração, som. Na mesma rede Wi-Fi que este computador.", "Recomendado", func(): _show_qr(false))
	var game := _option("desktop", "O telemóvel do jogo", "Aparece no ecrã do computador e usas o rato.", "", func(): _finish("game"))
	if Settings.get_value("phone_mode_last", "own") == "game":
		cards.add_child(game)
		cards.add_child(own)
		game.call_deferred("grab_focus")
	else:
		cards.add_child(own)
		cards.add_child(game)
		own.call_deferred("grab_focus")
	v.add_child(cards)
	v.add_child(UI.spacer(6))
	v.add_child(_back_row([]))


func _option(glyph: String, title: String, text: String, tag: String, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 250)
	var normal := UI.box(Color(1, 1, 1, 0.035), 22, Color(1, 1, 1, 0.08), 1)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.06), 22, Color(UI.c("accent"), 0.5), 1))
	b.add_theme_stylebox_override("pressed", UI.box(Color(1, 1, 1, 0.08), 22, UI.c("accent"), 1))
	b.add_theme_stylebox_override("focus", UI.box(Color(0, 0, 0, 0), 22, UI.c("accent"), 2))
	var m := UI.margin(28, 26, 28, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(m)
	var v := UI.vbox(10)
	m.add_child(v)
	var top := UI.hbox(10)
	var ic := UI.glyph(glyph, 84, "accent")
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(ic)
	top.add_child(UI.expand())
	if tag != "":
		var t := UI.panel(Color(UI.c("accent"), 0.14), 12, 10, 3, 10, 3)
		var tl := UI.label(tag, 12, "accent")
		tl.add_theme_font_override("font", UI.font("semibold"))
		t.add_child(tl)
		t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		top.add_child(t)
	v.add_child(top)
	v.add_child(UI.expand())
	v.add_child(UI.label(title, 24))
	v.add_child(UI.label(text, 15, "dim", true))
	UI._ignore_mouse(m)
	b.pressed.connect(func():
		Audio.play("tap", -8.0)
		cb.call())
	UI.press_fx(b, 0.985)
	return b


# ================================================================ QR
func _show_qr(reconnect: bool) -> void:
	var root := _scene(0.7)
	var m := UI.margin(90, 60, 90, 48)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(m)
	var cols := UI.hbox(70)
	m.add_child(cols)
	var left := UI.vbox(16)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_child(left)
	left.add_child(_kicker("ligação perdida" if reconnect else "o telemóvel do Daniel"))
	left.add_child(_big("Voltaste? Liga-o outra vez." if reconnect else "Ainda estás acordado?"))
	if not Companion.running and not Companion.start():
		left.add_child(UI.label("Não foi possível abrir a ligação na rede local (portas %d–%d ocupadas?)." % [Companion.HTTP_PORT, Companion.HTTP_PORT + 9], 16, "danger", true))
		left.add_child(_back_row([_alt_button()]))
		return
	left.add_child(UI.label("A partir de agora, o telemóvel dele é o teu.", 18, "dim", true))
	left.add_child(UI.spacer(4))
	var steps := [
		"Liga o telemóvel à mesma rede Wi-Fi que este computador.",
		"Aponta a câmara ao código e abre a página.",
		"Toca em «Começar». Som alto. Se puderes, auscultadores.",
	]
	for i in steps.size():
		var row := UI.hbox(14)
		var n := UI.label("%02d" % (i + 1), 14, "accent")
		n.add_theme_font_override("font", UI.font("semibold"))
		n.custom_minimum_size = Vector2(26, 0)
		row.add_child(n)
		var t := UI.label(steps[i], 15, "text", true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(t)
		left.add_child(row)
	left.add_child(UI.spacer(6))
	var st := UI.hbox(10)
	_status_dot = Panel.new()
	_status_dot.custom_minimum_size = Vector2(10, 10)
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.add_child(_status_dot)
	_status = UI.label("", 17, "dim")
	_status.add_theme_font_override("font", UI.font("medium"))
	st.add_child(_status)
	left.add_child(st)
	_status_sub = UI.label("", 14, "faint", true)
	left.add_child(_status_sub)
	left.add_child(UI.spacer(4))
	var fine := UI.label("A página não acede à câmara, ao microfone, aos contactos, aos ficheiros nem à localização do telemóvel: só mostra o telemóvel do jogo. No Windows, se a firewall perguntar, permite redes privadas. No iPhone: Partilhar → «Adicionar ao ecrã principal» tira a barra do Safari.", 12, "faint", true)
	left.add_child(fine)
	left.add_child(UI.spacer(4))
	left.add_child(_back_row([_alt_button()]))
	# the code, printed on a scrap of paper, in a camera's frame
	var right := CenterContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(_paper(Companion.url()))
	print("COMPANION_URL ", Companion.url())
	Companion.clients_changed.connect(_update)
	_update(Companion.client_count())


func _paper(url: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(380, 470)
	var frame := ScanFrame.new()
	frame.position = Vector2(0, 0)
	frame.size = holder.custom_minimum_size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := PanelContainer.new()
	var sb := UI.box(Color("e8e3d9"), 4)
	sb.shadow_color = Color(0, 0, 0, 0.65)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(4, 10)
	paper.add_theme_stylebox_override("panel", UI.pad(sb, 22, 22, 22, 16))
	var pv := UI.vbox(10)
	paper.add_child(pv)
	var q := qr_rect(url)
	q.custom_minimum_size = Vector2(270, 270)
	pv.add_child(q)
	var cap := UI.label("acordado?", 17)
	cap.add_theme_font_override("font", UI.font("italic"))
	cap.add_theme_color_override("font_color", Color("4a4540"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(cap)
	paper.position = Vector2(42, 52)
	paper.size = Vector2(296, 340)
	paper.pivot_offset = paper.size / 2
	paper.rotation = deg_to_rad(-2.2)
	holder.add_child(paper)
	holder.add_child(frame)
	var link := UI.label(url, 12, "faint")
	link.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	link.position = Vector2(0, 432)
	link.size = Vector2(380, 18)
	holder.add_child(link)
	return holder


## Camera-viewfinder corners around the code and a faint red line sweeping
## down over it, as if something were reading it.
class ScanFrame extends Control:
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(14, 22), Vector2(size.x - 28, 386))
		var L := 30.0
		var col := Color(1, 1, 1, 0.55)
		for k in 4:
			var cx := r.position.x if k % 2 == 0 else r.end.x
			var cy := r.position.y if k < 2 else r.end.y
			var sx := 1.0 if k % 2 == 0 else -1.0
			var sy := 1.0 if k < 2 else -1.0
			draw_line(Vector2(cx, cy), Vector2(cx + L * sx, cy), col, 2.0, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + L * sy), col, 2.0, true)
		if UI.motion_ok():
			var y := r.position.y + 30 + fposmod(_t * 70.0, r.size.y - 60)
			draw_line(Vector2(r.position.x + 30, y), Vector2(r.end.x - 30, y), Color(0.95, 0.2, 0.2, 0.35), 2.0)
			draw_line(Vector2(r.position.x + 30, y - 3), Vector2(r.end.x - 30, y - 3), Color(0.95, 0.2, 0.2, 0.1), 4.0)


func _alt_button() -> Button:
	var alt := UI.pill_button("Usar antes o telemóvel do jogo", func(): _finish("game"), "surf2", "dim")
	alt.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return alt


func _update(n: int) -> void:
	if not is_instance_valid(_status) or _done:
		return
	if n > 0:
		_status.text = "Telemóvel ligado."
		_status.add_theme_color_override("font_color", UI.c("text"))
		_status_sub.text = "Não o desligues."
		_status_dot.add_theme_stylebox_override("panel", UI.box(UI.c("ok"), 5))
		_status_dot.modulate.a = 1.0
		Audio.play("unlock", -6.0)
		get_tree().create_timer(1.6, true).timeout.connect(func(): _finish("own"))
	else:
		_status.text = "À espera do telemóvel…"
		_status.add_theme_color_override("font_color", UI.c("dim"))
		_status_sub.text = ""
		_status_dot.add_theme_stylebox_override("panel", UI.box(Color("e04545"), 5))
		if not _status_dot.has_meta("pulsing"):
			_status_dot.set_meta("pulsing", true)
			_pulse(_status_dot)


func _finish(m: String) -> void:
	if _done:
		return
	_done = true
	if Companion.clients_changed.is_connected(_update):
		Companion.clients_changed.disconnect(_update)
	Settings.set_value("phone_mode_last", m)
	queue_free()
	chosen.emit(m)


func close() -> void:
	if Companion.clients_changed.is_connected(_update):
		Companion.clients_changed.disconnect(_update)
	super.close()


static func qr_rect(text: String) -> TextureRect:
	var m := QR.encode(text)
	var n := m.size()
	var q := 4  # quiet zone
	var img := Image.create(n + q * 2, n + q * 2, false, Image.FORMAT_L8)
	img.fill(Color.WHITE)
	for y in n:
		for x in n:
			if m[y][x]:
				img.set_pixel(x + q, y + q, Color.BLACK)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tr.custom_minimum_size = Vector2(260, 260)
	return tr
