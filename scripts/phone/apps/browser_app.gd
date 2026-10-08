extends PhoneApp
## Browser: a fictional internet. Search is a real mechanic: pages are found by
## keywords, some only appear once the story (or the player) unlocks them.

var _root: VBoxContainer
var _url: LineEdit
var _body: VBoxContainer
var _scroll: ScrollContainer
var _page := ""
var _back_stack: Array = []
var _current := {"kind": "start", "id": ""}


func build() -> void:
	_root = content_root()
	var bar := UI.panel(UI.c("bg"), 0, 10, 8, 10, 8)
	var h := UI.hbox(6)
	bar.add_child(h)
	_url = LineEdit.new()
	_url.placeholder_text = "Pesquisar ou escrever endereço"
	_url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_url.add_theme_font_size_override("font_size", UI.fs(15))
	_url.text_submitted.connect(_submit)
	_url.select_all_on_focus = true
	h.add_child(_url)
	h.add_child(UI.icon_button("history", _show_history, 38, "dim"))
	_root.add_child(bar)
	_scroll = UI.scroll()
	var m := UI.margin(0, 0, 0, 0)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body = UI.vbox(0)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(_body)
	_scroll.add_child(m)
	_root.add_child(_scroll)
	if params.get("page", "") != "":
		open_page(params.page)
	elif params.get("param", "") != "":
		open_page(params.param)
	else:
		_show_start()


func reopen(p: Dictionary) -> void:
	params = p
	if p.get("page", "") != "":
		open_page(p.page)


func on_back() -> bool:
	if not _back_stack.is_empty():
		var prev: Dictionary = _back_stack.pop_back()
		match prev.kind:
			"page": open_page(prev.id, false)
			"search": _search(prev.id, false)
			"start": _show_start(false)
			"history": _show_history(false)
		return true
	return false





# ---------------------------------------------------------------- start
func _show_start(push := true) -> void:
	if push and _body.get_child_count() > 0:
		_back_stack.append(_current)
	_current = {"kind": "start", "id": ""}
	_page = ""
	_url.text = ""
	UI.clear(_body)
	var m := UI.margin(24, 50, 24, 20)
	var v := UI.vbox(14)
	m.add_child(v)
	_body.add_child(m)
	var logo := UI.label("procura", 34, "dim")
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(logo)
	var tip := UI.label("Escreve na barra acima e prime Enter.", 13, "faint")
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tip)
	v.add_child(UI.spacer(20))
	v.add_child(UI.label("Favoritos", 13, "accent"))
	for pid in Content.all("chapters_meta").get("initial", {}).get("bookmarks", []):
		var pg := Content.get_item("pages", pid)
		v.add_child(_link_row(pid, str(pg.get("title", pid)), str(pg.get("url", ""))))
	var recent := _recent_searches()
	if not recent.is_empty():
		v.add_child(UI.spacer(10))
		v.add_child(UI.label("Pesquisas recentes", 13, "accent"))
		for q in recent:
			var b := UI.button("  " + q, func(): _search(q), 15, "dim")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			v.add_child(b)


func _recent_searches() -> Array:
	var out := []
	for h in GameState.data.browser.history:
		var q: String = h.q
		if not q.begins_with("http") and not out.has(q):
			out.append(q)
		if out.size() >= 4:
			break
	return out


# ---------------------------------------------------------------- search
static func normalize(s: String) -> String:
	return UI.norm(s)


func _submit(text: String) -> void:
	var t := text.strip_edges()
	if t == "":
		return
	_url.release_focus()
	# direct URL?
	for pid in Content.all("pages"):
		var pg: Dictionary = Content.get_item("pages", pid)
		var u := str(pg.get("url", ""))
		if u != "" and (normalize(u) == normalize(t) or normalize(u).trim_prefix("www ") == normalize(t).trim_prefix("www ")):
			if page_available(pid):
				open_page(pid)
				return
	_search(t)


static func page_available(pid: String) -> bool:
	var pg := Content.get_item("pages", pid)
	if pg.is_empty():
		return false
	if GameState.data.browser.unlocked.has(pid):
		return true
	var req: String = pg.get("requires", "")
	return req == "" or Director.check(req)


static func search_results(q: String) -> Array:
	var nq := normalize(q)
	var words := nq.split(" ", false)
	var scored: Array = []
	for pid in Content.all("pages"):
		var pg: Dictionary = Content.get_item("pages", pid)
		if not page_available(pid):
			continue
		var kws: Array = pg.get("keywords", [])
		var score := 0
		var exact: bool = false
		for kw in kws:
			var nk := normalize(str(kw))
			if nk == nq or nq.contains(nk) and nk.length() >= 5:
				exact = true
				score += 3
		if pg.get("hidden", false) and not exact:
			continue
		for w in words:
			if w.length() < 3:
				continue
			for kw in kws:
				var nk2 := normalize(str(kw))
				if nk2 == w or (w.length() >= 4 and (nk2.begins_with(w) or w.begins_with(nk2) and nk2.length() >= 4)):
					score += 1
					break
		if score > 0:
			scored.append([score + int(pg.get("rank", 0)), pid])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	return scored.map(func(x): return x[1])


func _search(q: String, push := true) -> void:
	if push:
		_back_stack.append(_current)
	_current = {"kind": "search", "id": q}
	_page = ""
	_url.text = q
	var nq := normalize(q)
	GameState.data.browser.searched[nq] = true
	if push:
		GameState.data.browser.history.push_front({"q": q, "t": Clock.now(), "injected": false})
	Events.searched.emit(nq)
	Director.notify_player_action()
	Clock.notify_activity()
	UI.clear(_body)
	var res := search_results(q)
	var m := UI.margin(16, 10, 16, 20)
	var v := UI.vbox(16)
	m.add_child(v)
	_body.add_child(m)
	v.add_child(UI.label("Cerca de %d resultados" % (res.size() * 37 + 3) if res.size() > 0 else "Sem resultados", 12, "faint"))
	if res.is_empty():
		v.add_child(UI.label("A tua pesquisa — %s — não corresponde a nenhum documento.\n\nSugestões:\n• Verifica a ortografia.\n• Usa palavras-chave diferentes (nomes, locais, datas).\n• Usa menos palavras." % q, 14, "dim", true))
	for pid in res:
		var pg := Content.get_item("pages", pid)
		var rv := UI.vbox(2)
		rv.add_child(UI.label(str(pg.get("url", "")), 12, "faint"))
		var t := UI.label(str(pg.get("title", pid)), 17, "link", true)
		rv.add_child(t)
		var snip := UI.label(str(pg.get("snippet", "")), 13, "dim", true)
		rv.add_child(snip)
		var row := UI.row(rv, func(): open_page(pid), 96)
		var mm: MarginContainer = row.get_child(0)
		mm.add_theme_constant_override("margin_left", 0)
		v.add_child(row)


func _link_row(pid: String, title: String, url: String) -> Control:
	var rv := UI.vbox(0)
	rv.add_child(UI.label(title, 15, "link"))
	rv.add_child(UI.label(url, 11, "faint"))
	return UI.row(rv, func(): open_page(pid), 52)


# ---------------------------------------------------------------- pages
func open_page(pid: String, push := true) -> void:
	var pg := Content.get_item("pages", pid)
	if pg.is_empty() or not page_available(pid):
		_not_found(pid)
		return
	if push:
		_back_stack.append(_current)
	_current = {"kind": "page", "id": pid}
	if pg.get("password", "") != "" and not GameState.flag("unlocked_page_" + pid):
		_password_gate(pid, pg)
		return
	_page = pid
	_url.text = str(pg.get("url", ""))
	if push:
		GameState.data.browser.history.push_front({"q": str(pg.get("url", "")), "t": Clock.now(), "injected": false})
	GameState.data.browser.visited[pid] = int(GameState.data.browser.visited.get(pid, 0)) + 1
	Events.page_visited.emit(pid)
	UI.clear(_body)
	_body.add_child(_site_header(pg))
	var m := UI.margin(18, 14, 18, 30)
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	_body.add_child(m)
	var blocks: Array = pg.get("blocks", [])
	for alt in pg.get("alt", []):
		if Director.check(str(alt.get("when", "false"))):
			if alt.get("replace", false):
				blocks = alt.blocks
			else:
				blocks = blocks + alt.blocks
	for b in blocks:
		var c := _block(b)
		if c:
			v.add_child(c)
	for c2 in pg.get("clues", []):
		Director.add_clue(c2)
	await get_tree().process_frame
	_scroll.scroll_vertical = 0
	Director.notify_player_action()
	Clock.notify_activity()


func _not_found(pid: String) -> void:
	UI.clear(_body)
	var m := UI.margin(24, 60, 24, 20)
	var v := UI.vbox(10)
	m.add_child(v)
	v.add_child(UI.label("404", 40, "faint"))
	v.add_child(UI.label("Esta página não existe ou foi removida.", 15, "dim", true))
	_body.add_child(m)


func _password_gate(pid: String, pg: Dictionary) -> void:
	_page = pid
	_url.text = str(pg.get("url", ""))
	UI.clear(_body)
	_body.add_child(_site_header(pg))
	var m := UI.margin(24, 40, 24, 20)
	var v := UI.vbox(12)
	m.add_child(v)
	_body.add_child(m)
	v.add_child(UI.label(str(pg.get("gate_title", "Área privada")), 18))
	v.add_child(UI.label(str(pg.get("gate_text", "Introduz a palavra-passe.")), 14, "dim", true))
	var le := LineEdit.new()
	le.secret = true
	le.placeholder_text = "Palavra-passe"
	v.add_child(le)
	var err := UI.label("", 13, "danger", true)
	var try_pw := func(_t = ""):
		if normalize(le.text) == normalize(str(pg.password)):
			GameState.set_var("unlocked_page_" + pid, true)
			Audio.play("unlock")
			_back_stack.pop_back()
			open_page(pid)
		else:
			Audio.play("error")
			GameState.inc_var("pw_fail_" + pid)
			err.text = "Palavra-passe incorreta." + ("\nDica: " + str(pg.get("hint", "")) if int(GameState.get_var("pw_fail_" + pid, 0)) >= 2 and pg.get("hint", "") != "" else "")
			if int(GameState.get_var("pw_fail_" + pid, 0)) >= 8:
				err.text += "\n" + UI.password_nudge(str(pg.password))
	le.text_submitted.connect(try_pw)
	v.add_child(UI.pill_button("Entrar", try_pw, "surf2"))
	v.add_child(err)


func _site_header(pg: Dictionary) -> Control:
	var col := Color(str(pg.get("site_color", "#20242b")))
	var p := UI.panel(col, 0, 18, 12, 18, 12)
	var h := UI.hbox(8)
	p.add_child(h)
	var site := UI.label(str(pg.get("site", "")), 15)
	site.add_theme_color_override("font_color", Color.WHITE if col.get_luminance() < 0.55 else Color.BLACK)
	h.add_child(site)
	return p


func _block(b: Dictionary) -> Control:
	if b.has("when") and not Director.check(str(b.when)):
		return null
	if b.has("h"):
		return UI.label(str(b.h), 22, "text", true)
	if b.has("h2"):
		return UI.label(str(b.h2), 17, "text", true)
	if b.has("meta"):
		return UI.label(str(b.meta), 12, "faint", true)
	if b.has("p"):
		var r := UI.rich(str(b.p), 15)
		r.meta_clicked.connect(_on_meta)
		return r
	if b.has("quote"):
		var qp := UI.panel(Color(1, 1, 1, 0.04), 6, 14, 10, 14, 10)
		qp.add_child(UI.label(str(b.quote), 15, "dim", true))
		return qp
	if b.has("img"):
		var v := UI.vbox(4)
		var pv := PhotoView.new()
		var info := Content.get_item("photos", str(b.img))
		var aspect: float = float(info.get("aspect", 1.33))
		pv.custom_minimum_size = Vector2(370, 370 / aspect)
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var holder := Button.new()
		holder.custom_minimum_size = pv.custom_minimum_size
		holder.add_child(pv)
		holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		holder.tooltip_text = "Guardar imagem"
		holder.pressed.connect(func():
			if not GameState.data.photos.has(b.img):
				GameState.add_photo(b.img, "Transferências")
				Events.content_changed.emit("photos")
				phone.toast("Imagem guardada na Galeria")
				Director.notify_player_action())
		pv.set_photo(str(b.img))
		UI.press_fx(holder, 0.98)
		v.add_child(holder)
		if b.has("cap"):
			v.add_child(UI.label(str(b.cap), 12, "faint", true))
		return v
	if b.has("link"):
		var pg := Content.get_item("pages", str(b.link))
		var t: String = str(b.get("text", pg.get("title", b.link)))
		return UI.wrap_button("→ " + t, func(): open_page(str(b.link)), UI.SCREEN.x - 36, 15, "surf", "link")
	if b.has("comment"):
		var c: Dictionary = b.comment
		var cp := UI.panel(UI.c("surf"), 8, 12, 10, 12, 10)
		var cv := UI.vbox(4)
		var top := UI.hbox(8)
		top.add_child(UI.label(str(c.get("user", "anónimo")), 13, "accent"))
		top.add_child(UI.label(str(c.get("time", "")), 11, "faint"))
		cv.add_child(top)
		cv.add_child(UI.label(str(c.get("text", "")), 14, "text", true))
		cp.add_child(cv)
		return cp
	if b.has("list"):
		var lv := UI.vbox(4)
		for item in b.list:
			lv.add_child(UI.label("•  " + str(item), 14, "text", true))
		return lv
	if b.has("sep"):
		return UI.separator()
	if b.has("mono"):
		var mp := UI.panel(Color(0, 0, 0, 0.35), 4, 10, 8, 10, 8)
		var ml := UI.label(str(b.mono), 13, "dim", true)
		mp.add_child(ml)
		return mp
	if b.has("clue"):
		Director.add_clue(str(b.clue))
		return null
	if b.has("file"):
		var f := Content.get_item("files", str(b.file))
		return UI.pill_button("Transferir " + str(f.get("name", b.file)), func():
			if not GameState.data.files.has(b.file):
				GameState.data.files.append(b.file)
				Events.content_changed.emit("files")
				phone.toast("Transferido: " + str(f.get("name", "")))
				Director.notify_player_action(), "surf2", "link", 14)
	return null


func _on_meta(meta) -> void:
	var s := str(meta)
	if s.begins_with("page:"):
		open_page(s.substr(5))
	elif s.begins_with("search:"):
		_search(s.substr(7))


# ---------------------------------------------------------------- history
func _show_history(push := true) -> void:
	if push:
		_back_stack.append(_current)
	_current = {"kind": "history", "id": ""}
	_page = ""
	UI.clear(_body)
	var m := UI.margin(16, 10, 16, 20)
	var v := UI.vbox(2)
	m.add_child(v)
	_body.add_child(m)
	v.add_child(UI.label("Histórico", 20))
	v.add_child(UI.spacer(8))
	var hist: Array = GameState.data.browser.history.duplicate()
	hist.sort_custom(func(a, b): return float(a.t) > float(b.t))
	if hist.is_empty():
		v.add_child(UI.label("O histórico está vazio.", 14, "faint"))
	var shown := 0
	for h in hist:
		if shown > 80:
			break
		shown += 1
		var hh := UI.hbox(10)
		hh.add_child(UI.glyph("search" if not str(h.q).contains(".") else "globe", 18, "faint"))
		var l := UI.label(str(h.q), 15, "text")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hh.add_child(l)
		hh.add_child(UI.label(Clock.fmt_relative(float(h.t)) if float(h.t) > 0 else "—", 12, "faint"))
		var q: String = h.q
		v.add_child(UI.row(hh, func():
			if h.get("injected", false):
				GameState.set_var("clicked_injected_" + normalize(q).replace(" ", "_"), true)
			_submit(q), 46))
	GameState.set_var("viewed_history", true)
	Director.notify_player_action()
