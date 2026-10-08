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
var _done := false


func _ready() -> void:
	no_back = mode == "reconnect" and not allow_back
	if mode == "reconnect":
		_show_qr(true)
	else:
		_show_choice()


func _show_choice() -> void:
	make("Que telemóvel vais usar?", 640, true)
	body.add_child(UI.label("O telemóvel é a tua ligação à história: mensagens, chamadas, fotografias. Escolhe onde o queres ter durante esta sessão.", 15, "dim", true))
	body.add_child(UI.spacer(4))
	var own := _option("O meu telemóvel", "O teu telemóvel passa a ser o do Daniel, em ecrã inteiro, com toque, vibração e som. Tem de estar na mesma rede Wi-Fi que este computador.", func(): _show_qr(false))
	var game := _option("O telemóvel do jogo", "O telemóvel aparece no ecrã do computador e usas o rato.", func(): _finish("game"))
	if Settings.get_value("phone_mode_last", "own") == "game":
		body.add_child(game)
		body.add_child(own)
		game.call_deferred("grab_focus")
	else:
		body.add_child(own)
		body.add_child(game)
		own.call_deferred("grab_focus")


func _option(title: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(0, 112)
	b.add_theme_stylebox_override("normal", UI.box(UI.c("surf"), 14, UI.c("line"), 1))
	b.add_theme_stylebox_override("hover", UI.box(UI.c("surf2"), 14, UI.c("accent").darkened(0.3), 1))
	b.add_theme_stylebox_override("pressed", UI.box(UI.c("surf2"), 14, UI.c("accent"), 1))
	b.add_theme_stylebox_override("focus", UI.box(Color(0, 0, 0, 0), 14, UI.c("accent"), 2))
	var t := UI.label(title, 19)
	t.position = Vector2(18, 14)
	b.add_child(t)
	var d := UI.label(text, 14, "dim", true)
	d.position = Vector2(18, 44)
	d.size = Vector2(530, 60)
	b.add_child(d)
	b.resized.connect(func(): d.size.x = b.size.x - 36)
	UI._ignore_mouse(t)
	UI._ignore_mouse(d)
	b.pressed.connect(func():
		Audio.play("tap", -8.0)
		cb.call())
	UI.press_fx(b, 0.98)
	return b


func _show_qr(reconnect: bool) -> void:
	make("O teu telemóvel ficou sem ligação" if reconnect else "Liga o teu telemóvel", 640, true)
	if not Companion.running and not Companion.start():
		body.add_child(UI.label("Não foi possível abrir a ligação na rede local (portas %d–%d ocupadas?)." % [Companion.HTTP_PORT, Companion.HTTP_PORT + 9], 15, "danger", true))
		body.add_child(_alt_button())
		return
	body.add_child(UI.label("Aponta a câmara do telemóvel ao código. O telemóvel e este computador têm de estar na mesma rede Wi-Fi.", 15, "text", true))
	print("COMPANION_URL ", Companion.url())
	var center := CenterContainer.new()
	center.add_child(qr_rect(Companion.url()))
	body.add_child(center)
	var url := UI.label(Companion.url(), 14, "accent")
	url.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(url)
	_status = UI.label("", 16, "dim")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)
	body.add_child(UI.label("No iPhone, para ficar sem a barra do Safari: botão Partilhar → «Adicionar ao ecrã principal» e abre-o a partir do ícone. No Windows, se a firewall perguntar, permite o acesso em redes privadas.", 12, "faint", true))
	body.add_child(UI.label("A página no telemóvel não acede à câmara, ao microfone, aos contactos, aos ficheiros nem à localização. Só mostra o telemóvel do jogo.", 12, "faint", true))
	body.add_child(_alt_button())
	Companion.clients_changed.connect(_update)
	_update(Companion.client_count())


func _alt_button() -> Button:
	var alt := UI.pill_button("Usar antes o telemóvel do jogo", func(): _finish("game"), "surf", "dim")
	alt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return alt


func _update(n: int) -> void:
	if not is_instance_valid(_status) or _done:
		return
	if n > 0:
		_status.text = "Telemóvel ligado ✓"
		_status.add_theme_color_override("font_color", UI.c("accent"))
		get_tree().create_timer(0.9, true).timeout.connect(func(): _finish("own"))
	else:
		_status.text = "À espera do telemóvel…"
		_status.add_theme_color_override("font_color", UI.c("dim"))


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
