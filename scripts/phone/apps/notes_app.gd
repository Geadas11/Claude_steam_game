extends PhoneApp
## Notes: Daniel's notes (and notes he didn't write), the clue board where the
## player decides what they believe, and the reconstruction of the night.

const TAGS := ["Facto", "Hipótese", "Mentira", "Incompleta", "Dúvida"]

var _root: VBoxContainer
var _tab := 0
var _open_note := ""
var _focus_clue := ""
var _clue_filter := "Todas"


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if (k == "notes" or k == "clues") and _open_note == "": _render())
	if params.get("deduction", false):
		_tab = 2
	elif params.get("param", "") == "clues":
		_tab = 1
	_render()


func reopen(p: Dictionary) -> void:
	params = p
	if p.get("deduction", false):
		_tab = 2
		_open_note = ""
		_render()


func on_back() -> bool:
	if _open_note != "":
		_open_note = ""
		_render()
		return true
	return false


func _tabs() -> Array:
	var t := ["Notas", "Pistas (%d)" % GameState.clue_count()]
	if GameState.flag("deduction_unlocked") or params.get("deduction", false):
		t.append("Reconstrução")
	return t


func _render() -> void:
	if not is_inside_tree():
		return
	UI.clear(_root)
	var plus := UI.icon_button("plus", _new_note, 40, "accent")
	plus.tooltip_text = "Nova nota"
	plus.visible = _tab == 0
	_root.add_child(UI.header("Notas", Callable(), [plus]))
	var tabs := _tabs()
	_tab = mini(_tab, tabs.size() - 1)
	_root.add_child(UI.tabs(tabs, _tab, func(i):
		_tab = i
		_render()))
	match _tab:
		0: _notes_list()
		1: _clue_board()
		2: _deduction()


# ---------------------------------------------------------------- notes
func _all_notes() -> Array:
	var out: Array = []
	for nid in GameState.data.notes:
		var n := Content.get_item("notes", nid)
		if n.is_empty():
			continue
		out.append({"id": nid, "title": n.get("title", ""), "text": n.get("text", ""), "t": Clock.parse_datetime(n.date) if n.has("date") else 0.0, "static": true})
	for i in GameState.data.player_notes.size():
		var pn: Dictionary = GameState.data.player_notes[i]
		out.append({"id": "p%d" % i, "title": pn.title, "text": pn.text, "t": float(pn.t), "static": false})
	out.sort_custom(func(a, b): return a.t > b.t)
	return out


func _notes_list() -> void:
	var sc := UI.scroll()
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(12, 8, 12, 12)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	var notes := _all_notes()
	if notes.is_empty():
		v.add_child(UI.empty_state("Sem notas.", "notes"))
	for n in notes:
		var rv := UI.vbox(3)
		var t := UI.label(str(n.title) if str(n.title) != "" else "(sem título)", 16)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rv.add_child(t)
		var pv := UI.label(str(n.text).replace("\n", " ").left(90), 13, "dim")
		pv.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rv.add_child(pv)
		rv.add_child(UI.label(Clock.fmt_relative(float(n.t)) if float(n.t) > 0 else "", 11, "faint"))
		var row := UI.row(rv, func(): _show_note(n), 84)
		row.add_theme_stylebox_override("normal", UI.box(UI.c("surf"), 12))
		v.add_child(row)


func _show_note(n: Dictionary) -> void:
	_open_note = n.id
	UI.clear(_root)
	if n.static:
		GameState.set_var("read_note_" + n.id, true)
		for c in Content.get_item("notes", n.id).get("clues", []):
			Director.add_clue(c)
		Director.notify_player_action()
	_root.add_child(UI.header("", func(): on_back()))
	var sc := UI.scroll()
	var m := UI.margin(20, 4, 20, 20)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	if n.static:
		v.add_child(UI.label(str(n.title), 22, "text", true))
		v.add_child(UI.label(Clock.fmt_date_long(float(n.t)) + " · " + Clock.fmt_time(float(n.t)) if float(n.t) > 0 else "", 12, "faint"))
		v.add_child(UI.label(str(n.text), 16, "text", true))
	else:
		var idx := int(str(n.id).substr(1))
		var title := LineEdit.new()
		title.text = str(n.title)
		title.placeholder_text = "Título"
		title.add_theme_font_size_override("font_size", UI.fs(18))
		v.add_child(title)
		var body := TextEdit.new()
		body.text = str(n.text)
		body.placeholder_text = "Escreve aqui as tuas teorias…"
		body.custom_minimum_size = Vector2(0, 520)
		body.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		body.add_theme_font_size_override("font_size", UI.fs(15))
		v.add_child(body)
		var save := func(_x = null):
			if idx < GameState.data.player_notes.size():
				GameState.data.player_notes[idx].title = title.text
				GameState.data.player_notes[idx].text = body.text
		title.text_changed.connect(save)
		body.text_changed.connect(save)
		var del := UI.pill_button("Apagar nota", func():
			GameState.data.player_notes.remove_at(idx)
			_open_note = ""
			_render(), "surf", "danger", 13)
		del.size_flags_horizontal = Control.SIZE_SHRINK_END
		v.add_child(del)
		body.grab_focus()


func _new_note() -> void:
	GameState.data.player_notes.append({"title": "", "text": "", "t": Clock.now()})
	var idx = GameState.data.player_notes.size() - 1
	GameState.set_var("wrote_note", true)
	Achievements.unlock("first_note")
	_show_note({"id": "p%d" % idx, "title": "", "text": "", "t": Clock.now(), "static": false})


# ---------------------------------------------------------------- clue board
func _clue_board() -> void:
	var sc := UI.scroll()
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(12, 8, 12, 12)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	var ids: Array = GameState.data.clues.keys()
	if ids.is_empty():
		v.add_child(UI.empty_state("Ainda não registaste nenhuma pista.\nAs coisas que reparares aparecem aqui.", "notes"))
		return
	v.add_child(UI.label("Marca cada pista com aquilo em que acreditas. Ninguém te vai dizer se tens razão.", 12, "faint", true))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	for f in ["Todas", "Por marcar"] + TAGS:
		var on: bool = f == _clue_filter
		var n: int = ids.size() if f == "Todas" else ids.filter(func(c): return str(GameState.data.clues[c].get("tag", "")) == ("" if f == "Por marcar" else f)).size()
		chips.add_child(UI.pill_button("%s %d" % [f, n], func():
			_clue_filter = f
			_render(), "accent" if on else "surf2", "bg" if on else "dim", 12))
	v.add_child(chips)
	if _clue_filter != "Todas" and _focus_clue == "":
		var want := "" if _clue_filter == "Por marcar" else _clue_filter
		ids = ids.filter(func(c): return str(GameState.data.clues[c].get("tag", "")) == want)
	ids.sort_custom(func(a, b): return float(GameState.data.clues[a].t) > float(GameState.data.clues[b].t))
	var focus_node: Control = null
	for cid in ids:
		var card := _clue_card(cid)
		v.add_child(card)
		if cid == _focus_clue:
			focus_node = card
		GameState.data.clues[cid].seen = true
	if focus_node:
		await get_tree().process_frame
		sc.ensure_control_visible(focus_node)
		_focus_clue = ""


func _clue_card(cid: String) -> Control:
	var c := Content.get_item("clues", cid)
	var st: Dictionary = GameState.data.clues[cid]
	var p := UI.panel(UI.c("surf"), 12, 14, 12, 14, 12)
	var v := UI.vbox(6)
	p.add_child(v)
	var top := UI.hbox(8)
	var t := UI.label(str(c.get("title", cid)), 16, "text", true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	if not st.get("seen", false):
		top.add_child(UI.label("novo", 11, "accent"))
	v.add_child(top)
	v.add_child(UI.label(str(c.get("desc", "")), 14, "dim", true))
	v.add_child(UI.label("Fonte: %s" % c.get("source", "—"), 11, "faint", true))
	# related clues
	var rel: Array = c.get("related", [])
	if not rel.is_empty():
		var rh := HFlowContainer.new()
		rh.add_theme_constant_override("h_separation", 6)
		rh.add_theme_constant_override("v_separation", 6)
		var hidden := 0
		for r in rel:
			if GameState.has_clue(r):
				var rc := Content.get_item("clues", r)
				rh.add_child(UI.pill_button("↔ " + str(rc.get("title", r)), func():
					_focus_clue = r
					_clue_filter = "Todas"
					_render(), "surf2", "link", 12))
			else:
				hidden += 1
		if hidden > 0:
			rh.add_child(UI.label("+%d ligação por descobrir" % hidden if hidden == 1 else "+%d ligações por descobrir" % hidden, 11, "faint"))
		v.add_child(rh)
	# tags
	var th := HFlowContainer.new()
	th.add_theme_constant_override("h_separation", 6)
	th.add_theme_constant_override("v_separation", 6)
	for tag in TAGS:
		var on: bool = st.get("tag", "") == tag
		var b := UI.pill_button(tag, func():
			GameState.data.clues[cid].tag = "" if on else tag
			GameState.set_var("tagged_any", true)
			Director.notify_player_action()
			_render(), "accent" if on else "bg", "bg" if on else "dim", 12)
		th.add_child(b)
	v.add_child(th)
	return p


# ---------------------------------------------------------------- deduction
func _deduction() -> void:
	var data: Dictionary = Content.all("chapters_meta").get("deduction", {})
	var sc := UI.scroll()
	var v := UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(14, 10, 14, 20)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	v.add_child(UI.label(str(data.get("title", "A noite de 14 de outubro")), 20, "text", true))
	v.add_child(UI.label(str(data.get("intro", "")), 14, "dim", true))
	var done := GameState.flag("deduction_done")
	for q in data.get("questions", []):
		var qv := UI.vbox(6)
		qv.add_child(UI.label(str(q.q), 16, "text", true))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		var cur := str(GameState.data.deduction.get(q.id, ""))
		for opt in q.options:
			var available: bool = opt.get("needs", "") == "" or GameState.has_clue(str(opt.needs)) or Director.check(str(opt.get("needs_expr", "false")))
			if not available:
				flow.add_child(UI.pill_button("???", func(): phone.toast("Ainda não sabes o suficiente."), "bg", "faint", 13))
				continue
			var on: bool = cur == opt.id
			var b := UI.pill_button(str(opt.text), func():
				if done:
					return
				GameState.data.deduction[q.id] = opt.id
				_render(), "accent" if on else "surf2", "bg" if on else "text", 13)
			b.disabled = done and not on
			flow.add_child(b)
		qv.add_child(flow)
		var p := UI.panel(UI.c("surf"), 12, 12, 10, 12, 10)
		p.add_child(qv)
		v.add_child(p)
	if done:
		v.add_child(UI.label("Reconstrução fechada.", 13, "faint"))
		return
	var answered := 0
	for q2 in data.get("questions", []):
		if GameState.data.deduction.has(q2.id):
			answered += 1
	var total: int = data.get("questions", []).size()
	var confirm := UI.pill_button("Confirmar reconstrução (%d/%d)" % [answered, total], func():
		if answered < total:
			phone.toast("Responde a todas as perguntas.")
			return
		_confirm_deduction(data), "accent" if answered == total else "surf2", "bg" if answered == total else "dim", 15)
	v.add_child(confirm)


func _confirm_deduction(data: Dictionary) -> void:
	var score := 0
	for q in data.get("questions", []):
		if str(GameState.data.deduction.get(q.id, "")) == str(q.answer):
			score += 1
	GameState.set_var("deduction_score", score)
	GameState.set_var("deduction_done", true)
	if score == data.get("questions", []).size():
		Achievements.unlock("deduction_perfect")
	Audio.play("clue")
	Director.notify_player_action()
	_render()
