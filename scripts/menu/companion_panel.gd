class_name CompanionPanel
extends MenuPanel
## "Telemóvel real": shows the QR code the player scans with their own phone.

var _status: Label


func _ready() -> void:
	make("Telemóvel real", 620)
	if not Companion.running and not Companion.start():
		body.add_child(UI.label("Não foi possível abrir a ligação na rede local (portas %d–%d ocupadas?)." % [Companion.HTTP_PORT, Companion.HTTP_PORT + 9], 15, "danger", true))
		return
	body.add_child(UI.label("Recebe as mensagens, as chamadas e as vibrações do jogo no teu telemóvel. O computador e o telemóvel têm de estar na mesma rede Wi-Fi.", 15, "text", true))
	var center := CenterContainer.new()
	center.add_child(_qr_rect(Companion.url()))
	body.add_child(center)
	var url := UI.label(Companion.url(), 14, "accent")
	url.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(url)
	body.add_child(UI.label("Aponta a câmara do telemóvel ao código, ou escreve o endereço no navegador. No Windows, se aparecer um aviso da firewall, permite o acesso em redes privadas.", 12, "faint", true))
	_status = UI.label("", 15, "dim")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)
	_update(Companion.client_count())
	Companion.clients_changed.connect(_update)
	var off := UI.pill_button("Desligar telemóvel real", func():
		Companion.stop()
		close(), "surf", "dim")
	off.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(off)
	body.add_child(UI.label("A página no telemóvel não acede à câmara, ao microfone, aos contactos, aos ficheiros nem à localização. Só recebe o que o jogo lhe envia.", 12, "faint", true))


func _update(n: int) -> void:
	if is_instance_valid(_status):
		_status.text = "Telemóvel ligado ✓" if n > 0 else "À espera do telemóvel…"
		_status.add_theme_color_override("font_color", UI.c("accent") if n > 0 else UI.c("dim"))


static func _qr_rect(text: String) -> TextureRect:
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
