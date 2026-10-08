extends PhoneApp
## Phone settings (in-fiction). Some entries are puzzles: hidden files,
## developer options, accounts that shouldn't exist, battery usage by "ECO".

var _root: VBoxContainer
var _page := ""
var _taps := 0


func build() -> void:
	_root = content_root()
	_render()


func on_back() -> bool:
	if _page != "":
		_page = "" if not _page.begins_with("dev_") else "dev"
		_render()
		return true
	return false


func _render() -> void:
	UI.clear(_root)
	var titles := {"": "Definições", "wifi": "Wi-Fi", "display": "Ecrã", "sound": "Som", "battery": "Bateria", "storage": "Armazenamento", "accounts": "Contas", "files": "Ficheiros", "about": "Sobre o telefone", "dev": "Opções de programador", "dev_proc": "Serviços em execução", "dev_log": "Registo do sistema", "dev_eco": "ECO"}
	_root.add_child(UI.header(titles.get(_page, ""), Callable() if _page == "" else func(): on_back()))
	var sc := UI.scroll()
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	_root.add_child(sc)
	match _page:
		"": _main(v)
		"wifi": _wifi(v)
		"display": _display(v)
		"sound": _sound(v)
		"battery": _battery(v)
		"storage": _storage(v)
		"accounts": _accounts(v)
		"files": _files(v)
		"about": _about(v)
		"dev": _dev(v)
		"dev_proc": _dev_proc(v)
		"dev_log": _dev_log(v)
		"dev_eco": _dev_eco(v)


func _entry(v: VBoxContainer, glyph: String, title: String, sub: String, page: String) -> void:
	var h := UI.hbox(14)
	h.add_child(UI.glyph(glyph, 24, "dim"))
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(title, 16))
	if sub != "":
		tv.add_child(UI.label(sub, 12, "faint"))
	h.add_child(tv)
	h.add_child(UI.glyph("chevron", 16, "faint"))
	v.add_child(UI.row(h, func():
		_page = page
		GameState.set_var("settings_" + page, true)
		Director.notify_player_action()
		_render(), 62))


func _main(v: VBoxContainer) -> void:
	var prof := UI.hbox(14)
	prof.add_child(UI.avatar("me", 52))
	var pv := UI.vbox(0)
	pv.add_child(UI.label("Daniel Reis", 18))
	pv.add_child(UI.label("Conta Lumen · daniel.reis@mail.pt", 12, "faint"))
	prof.add_child(pv)
	var pm := UI.margin(18, 10, 18, 14)
	pm.add_child(prof)
	v.add_child(pm)
	v.add_child(UI.separator())
	_entry(v, "wifi", "Wi-Fi", "MEO-7A21" if not GameState.flag("wifi_weird") else "LUMEN-ECO-NODE-04", "wifi")
	_entry(v, "image", "Ecrã", "Brilho, fundo", "display")
	_entry(v, "speaker", "Som", "Não incomodar: %s" % ("ativo" if GameState.data.phone.get("dnd", false) else "desativado"), "sound")
	_entry(v, "dot", "Bateria", "%d%%" % int(GameState.data.battery), "battery")
	_entry(v, "folder", "Armazenamento", "", "storage")
	_entry(v, "person", "Contas", "", "accounts")
	_entry(v, "files", "Ficheiros", "Visibilidade", "files")
	_entry(v, "info", "Sobre o telefone", "Lumen One · Lumen OS 3.2", "about")
	if GameState.data.phone.get("dev_mode", false):
		_entry(v, "settings", "Opções de programador", "", "dev")


func _toggle(v: VBoxContainer, title: String, sub: String, key: String, cb := Callable()) -> void:
	var h := UI.hbox(10)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(title, 16))
	if sub != "":
		tv.add_child(UI.label(sub, 12, "faint", true))
	h.add_child(tv)
	var c := CheckButton.new()
	c.button_pressed = bool(GameState.data.phone.get(key, false))
	c.toggled.connect(func(on):
		GameState.data.phone[key] = on
		Events.phone_state_changed.emit()
		Director.notify_player_action()
		if cb.is_valid():
			cb.call(on))
	h.add_child(c)
	var m := UI.margin(18, 10, 18, 10)
	m.add_child(h)
	v.add_child(m)


func _text(v: VBoxContainer, t: String, col := "dim", size := 14) -> void:
	var m := UI.margin(18, 8, 18, 8)
	m.add_child(UI.label(t, size, col, true))
	v.add_child(m)


func _kv(v: VBoxContainer, k: String, val: String, cb := Callable()) -> void:
	var h := UI.vbox(0)
	h.add_child(UI.label(k, 15))
	h.add_child(UI.label(val, 13, "faint", true))
	if cb.is_valid():
		v.add_child(UI.row(h, cb, 60))
	else:
		var m := UI.margin(16, 8, 16, 8)
		m.add_child(h)
		v.add_child(m)


func _wifi(v: VBoxContainer) -> void:
	_text(v, "Ligado a", "faint", 12)
	_kv(v, "MEO-7A21" if not GameState.flag("wifi_weird") else "LUMEN-ECO-NODE-04", "Ligado · Seguro")
	v.add_child(UI.separator())
	_text(v, "Redes disponíveis", "faint", 12)
	var nets := ["Vodafone-Casa-Brito", "NOS-2B11", "Livraria_Mare_Clientes"]
	if GameState.flag("wifi_weird") or Director.check("v(\"chapter_n\") >= 5"):
		nets.append("ainda_estas_acordado")
	for n in nets:
		_kv(v, n, "Protegida")
	if nets.has("ainda_estas_acordado"):
		GameState.set_var("saw_wifi_name", true)


func _display(v: VBoxContainer) -> void:
	_text(v, "Fundo do ecrã: escolhe uma fotografia na Galeria e toca em \"Definir como fundo\".")
	if not GameState.data.phone.has("auto_lock"):
		GameState.data.phone.auto_lock = true
	_toggle(v, "Bloqueio automático", "Escurece e bloqueia o ecrã ao fim de dois minutos sem uso.", "auto_lock")
	var h := UI.hbox(10)
	h.add_child(UI.label("Brilho", 15))
	var s := HSlider.new()
	s.min_value = 0.35
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(GameState.data.phone.get("brightness", 1.0))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(val):
		GameState.data.phone.brightness = val
		phone.screen.modulate = Color(val, val, val, 1.0))
	h.add_child(s)
	var m := UI.margin(18, 10, 18, 10)
	m.add_child(h)
	v.add_child(m)


func _sound(v: VBoxContainer) -> void:
	_toggle(v, "Não incomodar", "Silencia notificações. Chamadas de contactos favoritos tocam na mesma.", "dnd", func(on):
		if on:
			GameState.set_var("tried_dnd", true))
	if GameState.data.phone.get("dnd", false) and Director.check("v(\"chapter_n\") >= 5"):
		_text(v, "Algumas aplicações do sistema ignoram o modo Não incomodar.", "faint", 12)


func _battery(v: VBoxContainer) -> void:
	_kv(v, "Nível", "%d%%" % int(GameState.data.battery))
	_text(v, "Utilização desde o último carregamento", "faint", 12)
	var rows := [["Ecrã", 31], ["Mensagens", 12], ["Navegador", 9], ["Sistema Lumen OS", 7]]
	if Director.check("v(\"chapter_n\") >= 5"):
		rows.push_front(["ECO Service", 41])
		GameState.set_var("saw_eco_battery", true)
		Director.notify_player_action()
	for r in rows:
		var h := UI.hbox(10)
		var n := UI.label(str(r[0]), 15, "accent" if str(r[0]).begins_with("ECO") else "text")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(UI.label("%d%%" % int(r[1]), 14, "dim"))
		var m := UI.margin(18, 8, 18, 8)
		m.add_child(h)
		v.add_child(m)


func _storage(v: VBoxContainer) -> void:
	var used := "61,4" if GameState.flag("storage_grew") else "38,2"
	_kv(v, "Utilizado", "%s GB de 128 GB" % used)
	_kv(v, "Fotografias", "%d itens" % GameState.data.photos.size())
	_kv(v, "Mensagens", "1,2 GB")
	_kv(v, "Sistema", "14,8 GB")
	if GameState.flag("storage_grew"):
		_kv(v, "Outros", "23,2 GB · origem desconhecida")


func _accounts(v: VBoxContainer) -> void:
	_kv(v, "daniel.reis@mail.pt", "Email · Contactos · Calendário")
	_kv(v, "Conta Lumen (dispositivo)", "d.reis · gerida pela organização Lumen Systems")
	if GameState.flag("ines_account"):
		_kv(v, "ines.matos@lumen.pt", "Adicionada a 14/10/2025 03:21 · Sincronização: ativa", func():
			GameState.set_var("tapped_ines_account", true)
			Director.add_clue("ines_account")
			phone.toast("Não é possível remover esta conta: gerida pela organização."))
	_text(v, "Este dispositivo é gerido pela tua organização. A organização pode ver e alterar dados, aplicações e definições.", "faint", 12)
	GameState.set_var("saw_managed_device", true)
	Director.notify_player_action()


func _files(v: VBoxContainer) -> void:
	_toggle(v, "Mostrar ficheiros ocultos", "Mostra pastas e ficheiros do sistema cujo nome começa por um ponto.", "hidden_files", func(on):
		if on:
			GameState.set_var("enabled_hidden", true)
			Achievements.unlock("hidden_files"))


func _about(v: VBoxContainer) -> void:
	_kv(v, "Modelo", "Lumen One (LM-1)")
	_kv(v, "Lumen OS", "3.2.7")
	_kv(v, "Número de telemóvel", "+351 936 118 245")
	_kv(v, "Registo do dispositivo", "Oferecido por Lumen Systems · 03/11/2025")
	_kv(v, "Número de compilação", "LMN-3.2.7-ECO.sim.047", func():
		if GameState.data.phone.get("dev_mode", false):
			phone.toast("Já és programador.")
			return
		_taps += 1
		if _taps >= 7:
			GameState.data.phone.dev_mode = true
			GameState.set_var("dev_mode", true)
			Achievements.unlock("developer")
			phone.toast("Agora és programador.")
			Director.notify_player_action()
		elif _taps >= 3:
			phone.toast("Faltam %d passos para seres programador." % (7 - _taps)))
	GameState.set_var("saw_build_number", true)
	Director.notify_player_action()


func _dev(v: VBoxContainer) -> void:
	_entry(v, "settings", "Serviços em execução", "", "dev_proc")
	_entry(v, "doc", "Registo do sistema", "", "dev_log")
	_entry(v, "eco", "ECO", "Depuração do serviço preditivo", "dev_eco")


func _dev_proc(v: VBoxContainer) -> void:
	var procs := [["system_server", "212 MB"], ["lumen.launcher", "88 MB"], ["lumen.messages", "64 MB"], ["eco.mirror", "1,4 GB"], ["eco.sim  #047", "2,1 GB"], ["eco.predict", "512 MB"], ["eco.voice", "256 MB"]]
	for p in procs:
		var h := UI.hbox(10)
		var n := UI.label(str(p[0]), 15, "accent" if str(p[0]).begins_with("eco") else "text")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(UI.label(str(p[1]), 13, "dim"))
		var m := UI.margin(18, 8, 18, 8)
		m.add_child(h)
		v.add_child(m)
	GameState.set_var("saw_eco_procs", true)
	Director.add_clue("eco_processes")


func _dev_log(v: VBoxContainer) -> void:
	var p := UI.panel(Color(0, 0, 0, 0.5), 0, 12, 12, 12, 12)
	var lines: Array = Content.all("chapters_meta").get("system_log", [])
	var shown: Array = []
	for l in lines:
		if Director.check(str(l.get("when", "true"))):
			shown.append(str(l.text))
	var lab := UI.label("\n".join(PackedStringArray(shown)), 11, "ok", true)
	p.add_child(lab)
	v.add_child(p)
	GameState.set_var("read_syslog", true)
	Director.add_clue("system_log")


func _dev_eco(v: VBoxContainer) -> void:
	_text(v, "Serviço preditivo ECO · modo de depuração", "text", 15)
	_text(v, "Introduz a chave de depuração para aceder à consola do modelo.", "dim", 13)
	if GameState.flag("eco_console"):
		_text(v, "Consola ativa. A aplicação ECO está disponível no ecrã principal.", "ok", 13)
		return
	var le := LineEdit.new()
	le.placeholder_text = "Chave"
	le.secret = true
	var m := UI.margin(18, 0, 18, 0)
	m.add_child(le)
	v.add_child(m)
	var err := UI.label("", 13, "danger")
	var attempt := func(_t = ""):
		var key := str(Content.all("chapters_meta").get("eco_key", "mare"))
		if le.text.strip_edges().to_lower() == key:
			GameState.set_var("eco_console", true)
			GameState.data.phone.eco_app = true
			Events.phone_state_changed.emit()
			Audio.play("glitch_short")
			Achievements.unlock("eco_console")
			Director.notify_player_action()
			_render()
		else:
			Audio.play("error")
			err.text = "Chave inválida."
	le.text_submitted.connect(attempt)
	var bm := UI.margin(18, 8, 18, 0)
	bm.add_child(UI.pill_button("Ativar consola", attempt, "surf2", "accent"))
	v.add_child(bm)
	var em := UI.margin(18, 4, 18, 0)
	em.add_child(err)
	v.add_child(em)
