class_name SettingsPanel
extends MenuPanel
## Game settings (audio, text, accessibility, display, controls).


func _ready() -> void:
	make("Definições", 640)
	_section("Áudio")
	_slider("Volume geral", "master_volume", 0.0, 1.0)
	_slider("Efeitos e notificações", "sfx_volume", 0.0, 1.0)
	_slider("Ambiente", "ambient_volume", 0.0, 1.0)
	_slider("Música", "music_volume", 0.0, 1.0)
	_slider("Vozes e respiração", "voice_volume", 0.0, 1.0)
	_section("Texto")
	_slider("Tamanho do texto", "text_scale", 0.85, 1.5, 0.05)
	_slider("Velocidade das mensagens", "text_speed", 0.5, 3.0, 0.25)
	_slider("Velocidade do relógio do jogo", "clock_speed", 1.0, 3.0, 0.25)
	body.add_child(UI.label("O relógio também acelera sozinho quando ficas parado e a história só está à espera da hora certa.", 12, "faint", true))
	_toggle("Legendas em chamadas e gravações", "subtitles")
	_toggle("Legendas de sons ([respiração], [estática]…)", "sound_captions")
	_toggle("Avisar quando encontras uma pista", "clue_toasts")
	_section("Acessibilidade")
	_toggle("Alto contraste", "high_contrast")
	_toggle("Reduzir efeitos visuais (interferências, cintilação)", "reduce_effects")
	_toggle("Reduzir movimento (transições, tremor)", "reduce_motion")
	_toggle("Suavizar sons súbitos (pancadas, interferências)", "soften_sudden")
	_section("Ecrã")
	_toggle("Ecrã inteiro (F11)", "fullscreen")
	_toggle("Sincronização vertical", "vsync")
	_resolution()
	_section("Controlos")
	for action in Settings.REMAPPABLE:
		_keybind(action)
	for line in [
		"Rato — tocar no ecrã do telemóvel",
		"Roda do rato — deslizar listas",
		"Comando: setas/analógico para navegar, A para escolher, B para voltar, Start para pausa",
	]:
		body.add_child(UI.label(line, 14, "dim"))


func _section(t: String) -> void:
	body.add_child(UI.spacer(6))
	body.add_child(UI.label(t.to_upper(), 13, "accent"))


func _slider(label_text: String, key: String, mn: float, mx: float, step := 0.05) -> void:
	var h := UI.hbox(12)
	var l := UI.label(label_text, 15)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(220, 24)
	s.focus_mode = Control.FOCUS_ALL
	var val := UI.label("", 13, "dim")
	val.custom_minimum_size = Vector2(46, 0)
	val.text = _fmt(key, s.value)
	s.value_changed.connect(func(v):
		val.text = _fmt(key, v)
		Settings.set_value(key, v)
		if key == "sfx_volume":
			Audio.play("msg"))
	h.add_child(s)
	h.add_child(val)
	body.add_child(h)


func _fmt(key: String, v: float) -> String:
	if key == "text_scale" or key == "text_speed" or key == "clock_speed":
		return "%.2fx" % v
	return "%d%%" % int(round(v * 100))


func _toggle(label_text: String, key: String) -> void:
	var c := CheckButton.new()
	c.text = label_text
	c.button_pressed = bool(Settings.get_value(key))
	c.add_theme_font_size_override("font_size", UI.fs(15))
	c.focus_mode = Control.FOCUS_ALL
	c.toggled.connect(func(on): Settings.set_value(key, on))
	body.add_child(c)


func _resolution() -> void:
	var h := UI.hbox(12)
	var l := UI.label("Resolução (janela)", 15)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var o := OptionButton.new()
	var opts := ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
	for i in opts.size():
		o.add_item(opts[i])
		if opts[i] == Settings.get_value("resolution"):
			o.select(i)
	o.item_selected.connect(func(i): Settings.set_value("resolution", opts[i]))
	h.add_child(o)
	body.add_child(h)


var _waiting_action := ""
var _waiting_button: Button


func _keybind(action: String) -> void:
	var h := UI.hbox(12)
	var l := UI.label(Settings.REMAPPABLE[action], 15)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := UI.pill_button(Settings.key_label(action), func(): pass, "surf2", "accent", 13)
	b.pressed.connect(func():
		_waiting_action = action
		_waiting_button = b
		b.text = "Prime uma tecla…")
	h.add_child(b)
	body.add_child(h)


func _input(event: InputEvent) -> void:
	if _waiting_action == "" or not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if event.physical_keycode == KEY_ESCAPE and _waiting_action != "pause_menu":
		_waiting_button.text = Settings.key_label(_waiting_action)
		_waiting_action = ""
		return
	Settings.rebind(_waiting_action, event.physical_keycode)
	_waiting_button.text = Settings.key_label(_waiting_action)
	_waiting_action = ""
