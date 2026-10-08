extends PhoneApp
## Contacts: saved people, details, Daniel's private notes about each person.

var _root: VBoxContainer
var _open := ""


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if k == "contacts":
		if _open == "": _show_list()
		else: _show_contact(_open))
	if params.get("param", "") != "":
		_show_contact(params.param)
	else:
		_show_list()


func reopen(p: Dictionary) -> void:
	params = p
	if p.get("param", "") != "":
		_show_contact(p.param)


func on_back() -> bool:
	if _open != "":
		slide(false)
		_show_list()
		return true
	return false


func _show_list() -> void:
	_open = ""
	UI.clear(_root)
	_root.add_child(UI.header("Contactos", Callable()))
	var sc := UI.scroll()
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	_root.add_child(sc)
	var ids: Array = []
	for id in Content.all("characters"):
		var c := GameState.contact(id)
		if c.get("saved", false) and not c.get("group", false) and not c.get("hidden", false):
			ids.append(id)
	ids.sort_custom(func(a, b): return UI.norm(GameState.contact_name(a)) < UI.norm(GameState.contact_name(b)))
	var last_letter := ""
	for id in ids:
		var nm := GameState.contact_name(id)
		var letter := UI.norm(nm).left(1).to_upper()
		if letter != last_letter:
			last_letter = letter
			var ll := UI.label(letter, 13, "accent")
			var lm := UI.margin(18, 10, 0, 2)
			lm.add_child(ll)
			v.add_child(lm)
		var h := UI.hbox(12)
		h.add_child(UI.avatar(id, 40))
		var name := UI.label(nm, 16)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name)
		v.add_child(UI.row(h, func(): slide(); _show_contact(id), 56))
	var count := UI.label("%d contactos" % ids.size(), 12, "faint")
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(UI.spacer(10))
	v.add_child(count)


func _show_contact(id: String) -> void:
	_open = id
	var c := GameState.contact(id)
	GameState.set_var("viewed_contact_" + id, true)
	Director.notify_player_action()
	UI.clear(_root)
	_root.add_child(UI.header("", _show_list))
	var sc := UI.scroll()
	var m := UI.margin(22, 10, 22, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	var av := UI.avatar(id, 96)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(av)
	var nm := UI.label(GameState.contact_name(id), 24)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var actions := UI.hbox(24)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_child(_action("messages", "Mensagem", func():
		GameState.ensure_thread(id)
		if not GameState.data.thread_order.has(id):
			GameState.data.thread_order.push_front(id)
		phone.open_app("messages", {"thread": id})))
	actions.add_child(_action("call", "Ligar", func(): Director.player_call(id)))
	v.add_child(actions)
	v.add_child(UI.separator())
	_field(v, "Telemóvel", str(c.get("number", "")))
	if c.get("email", "") != "":
		_field(v, "Email", str(c.email))
	if c.get("birthday", "") != "":
		_field(v, "Aniversário", str(c.birthday))
	if c.get("address", "") != "":
		_field(v, "Morada", str(c.address))
	if c.get("note", "") != "":
		_field(v, "Notas", str(c.note))
	if c.get("note2", "") != "" and Director.check(str(c.get("note2_when", "true"))):
		_field(v, "", str(c.note2))
	if c.get("last_edit", "") != "":
		var le := UI.label("Última alteração: " + str(c.last_edit), 11, "faint")
		v.add_child(le)
	for cl in c.get("clues", []):
		Director.add_clue(cl)


func _action(glyph: String, text: String, cb: Callable) -> Control:
	var vv := UI.vbox(4)
	var b := UI.icon_button(glyph, cb, 52, "accent")
	b.add_theme_stylebox_override("normal", UI.box(UI.c("surf2"), 26))
	vv.add_child(b)
	var l := UI.label(text, 12, "dim")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(l)
	return vv


func _field(v: VBoxContainer, k: String, val: String) -> void:
	if k != "":
		v.add_child(UI.label(k, 12, "faint"))
	v.add_child(UI.label(val, 15, "text", true))
