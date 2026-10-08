extends PhoneApp
## Phone: recents, favourites, keypad, voicemail.

const TABS := ["Recentes", "Contactos", "Teclado", "Correio de voz"]

var _root: VBoxContainer
var _tab := 0
var _body: VBoxContainer
var _number := ""
var _num_label: Label


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if k == "calls": _render())
	Events.call_ended.connect(func(_c): _render())
	if params.get("param", "") == "voicemail":
		_tab = 3
	_render()


func _render() -> void:
	if not is_inside_tree():
		return
	UI.clear(_root)
	_root.add_child(UI.header("Telefone", Callable()))
	_root.add_child(UI.tabs(TABS, _tab, func(i):
		_tab = i
		_render()))
	var sc := UI.scroll()
	_body = UI.vbox(0)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_body)
	_root.add_child(sc)
	match _tab:
		0: _recents()
		1: _favourites()
		2: _keypad()
		3: _voicemail()


func _who_label(c: Dictionary) -> String:
	if c.get("unknown", false):
		return "Número privado"
	if str(c.get("number", "")) != "":
		return c.number
	return GameState.contact_name(c.who)


func _recents() -> void:
	if GameState.data.calls.is_empty():
		_body.add_child(UI.empty_state("Sem chamadas recentes.", "phone"))
		return
	for c in GameState.data.calls:
		c.seen = true
		var h := UI.hbox(12)
		var g := "arrow_in"
		var col := "dim"
		match c.dir:
			"out": g = "arrow_out"
			"missed":
				g = "missed"
				col = "danger"
		h.add_child(UI.glyph(g, 18, col))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label(_who_label(c), 16, "danger" if c.dir == "missed" else "text"))
		var sub = {"in": "Recebida", "out": "Efetuada", "missed": "Perdida"}.get(c.dir, "")
		var dur := int(c.get("dur", 0))
		if c.dir != "missed":
			sub += " · %d:%02d" % [dur / 60, dur % 60]
		v.add_child(UI.label(sub, 12, "faint"))
		h.add_child(v)
		h.add_child(UI.label(Clock.fmt_relative(float(c.t)) if float(c.t) > 0 else "—", 12, "faint"))
		var who: String = c.who
		var unknown: bool = c.get("unknown", false)
		_body.add_child(UI.row(h, func():
			if unknown:
				phone.toast("Não é possível ligar para um número privado.")
			else:
				Director.player_call(who), 62))
	Events.content_changed.emit("badges")


func _favourites() -> void:
	var ids: Array = []
	for id in Content.all("characters"):
		var c := GameState.contact(id)
		if c.get("saved", false) and not c.get("group", false) and not c.get("no_call", false):
			ids.append(id)
	ids.sort_custom(func(a, b): return GameState.contact_name(a) < GameState.contact_name(b))
	for id in ids:
		var h := UI.hbox(12)
		h.add_child(UI.avatar(id, 40))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label(GameState.contact_name(id), 16))
		v.add_child(UI.label(str(GameState.contact(id).get("number", "")), 12, "faint"))
		h.add_child(v)
		h.add_child(UI.glyph("call", 22, "ok"))
		_body.add_child(UI.row(h, func(): Director.player_call(id), 60))


func _keypad() -> void:
	var m := UI.margin(30, 30, 30, 10)
	var v := UI.vbox(18)
	m.add_child(v)
	_body.add_child(m)
	_num_label = UI.label(_number, 30)
	_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num_label.custom_minimum_size = Vector2(0, 44)
	v.add_child(_num_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"]:
		var b := UI.button(k, func():
			if _number.length() < 16:
				_number += k
				_num_label.text = _number, 26)
		b.custom_minimum_size = Vector2(72, 64)
		b.add_theme_stylebox_override("normal", UI.box(Color(1, 1, 1, 0.06), 32))
		grid.add_child(b)
	v.add_child(grid)
	var h := UI.hbox(30)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var call := UI.icon_button("call", _dial, 66, "text")
	call.add_theme_stylebox_override("normal", UI.box(UI.c("ok").darkened(0.2), 33))
	h.add_child(call)
	h.add_child(UI.button("Apagar", func():
		_number = _number.substr(0, maxi(0, _number.length() - 1))
		_num_label.text = _number, 14, "dim"))
	v.add_child(h)


func _unhandled_key_input(event: InputEvent) -> void:
	if _tab != 2 or not (event is InputEventKey) or not event.pressed:
		return
	var ch := char(event.unicode) if event.unicode > 0 else ""
	if ch.length() == 1 and "0123456789*#+".contains(ch):
		_number += ch
		_num_label.text = _number
		Audio.play("tap", -10.0)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_dial()
		get_viewport().set_input_as_handled()


static func digits(s: String) -> String:
	var out := ""
	for ch in s:
		if ch >= "0" and ch <= "9":
			out += ch
	if out.begins_with("351") and out.length() > 9:
		out = out.substr(3)
	return out


func _dial() -> void:
	var n := digits(_number)
	if n == "":
		return
	GameState.set_var("dialed_" + n, true)
	for id in Content.all("characters"):
		var c := GameState.contact(id)
		if digits(str(c.get("number", ""))) == n and n.length() >= 9:
			Director.player_call(id, _number)
			return
	var special: Dictionary = Content.all("chapters_meta").get("special_numbers", {})
	if special.has(n):
		Director.player_call(str(special[n]), _number)
		return
	Director.player_call("nobody", _number)


func _voicemail() -> void:
	if GameState.data.voicemails.is_empty():
		_body.add_child(UI.empty_state("Sem mensagens de voz.", "voicemail"))
		return
	for vm in GameState.data.voicemails:
		var d := Content.get_item("voicemails", vm.id)
		var h := UI.hbox(12)
		h.add_child(UI.glyph("play", 20, "accent" if not vm.get("heard", false) else "dim"))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label(str(d.get("title", "Mensagem de voz")), 15, "text"))
		v.add_child(UI.label("%s · %s" % [Clock.fmt_relative(float(vm.t)), d.get("duration", "0:10")], 12, "faint"))
		h.add_child(v)
		var vid: String = vm.id
		_body.add_child(UI.row(h, func():
			vm.heard = true
			Events.content_changed.emit("badges")
			var sheet = load("res://scripts/phone/apps/messages_app.gd").AudioSheet.new()
			sheet.setup(vid, d)
			add_child(sheet), 60))
