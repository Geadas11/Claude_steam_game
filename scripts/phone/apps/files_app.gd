extends PhoneApp
## Files: documents, downloads, recordings, hidden system folders, archives.

var _root: VBoxContainer
var _folder := ""
var _file := ""


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if k == "files" and _file == "": _render())
	Events.phone_state_changed.connect(func(): if _file == "": _render())
	if params.get("file", "") != "":
		_open_file(params.file)
	else:
		_render()


func reopen(p: Dictionary) -> void:
	params = p
	if p.get("file", "") != "":
		_open_file(p.file)


func on_back() -> bool:
	if _file != "":
		_file = ""
		_render()
		return true
	if _folder != "":
		_folder = ""
		_render()
		return true
	return false


func _visible_files() -> Array:
	var show_hidden: bool = GameState.data.phone.get("hidden_files", false)
	return GameState.data.files.filter(func(fid):
		var f := Content.get_item("files", fid)
		return not f.is_empty() and (show_hidden or not str(f.get("folder", "")).begins_with(".")))


func _render() -> void:
	if not is_inside_tree():
		return
	UI.clear(_root)
	if _folder == "":
		_root.add_child(UI.header("Ficheiros", Callable()))
	else:
		_root.add_child(UI.header(_folder, func(): on_back()))
	var sc := UI.scroll()
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	_root.add_child(sc)
	var files := _visible_files()
	if _folder == "":
		var folders := {}
		for fid in files:
			var fo := str(Content.get_item("files", fid).get("folder", "Documentos"))
			folders[fo] = int(folders.get(fo, 0)) + 1
		var names: Array = folders.keys()
		names.sort_custom(func(a, b): return (a.begins_with(".") and not b.begins_with(".")) == false and a < b)
		for fo in names:
			var h := UI.hbox(12)
			h.add_child(UI.glyph("folder", 30, "faint" if fo.begins_with(".") else "accent"))
			var fv := UI.vbox(0)
			fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fv.add_child(UI.label(fo, 16, "dim" if fo.begins_with(".") else "text"))
			fv.add_child(UI.label("%d itens" % folders[fo], 12, "faint"))
			h.add_child(fv)
			v.add_child(UI.row(h, func():
				_folder = fo
				if fo.begins_with("."):
					GameState.set_var("opened_hidden_" + fo.substr(1), true)
					Director.notify_player_action()
				_render(), 62))
		if names.is_empty():
			v.add_child(UI.empty_state("Sem ficheiros.", "files"))
		var storage := UI.label("Armazenamento: %s de 128 GB usados" % ("61,4" if GameState.flag("storage_grew") else "38,2"), 12, "faint")
		storage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(UI.spacer(14))
		v.add_child(storage)
		return
	for fid in files:
		var f := Content.get_item("files", fid)
		if str(f.get("folder", "")) != _folder:
			continue
		var h2 := UI.hbox(12)
		var g = {"audio": "audio", "image": "image", "archive": "folder", "log": "doc"}.get(str(f.get("type", "doc")), "doc")
		h2.add_child(UI.glyph(g, 26, "dim"))
		var fv2 := UI.vbox(0)
		fv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := UI.label(str(f.get("name", fid)), 15)
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		fv2.add_child(nl)
		fv2.add_child(UI.label("%s · %s" % [f.get("size", ""), _date(str(f.get("date", "")))], 12, "faint"))
		h2.add_child(fv2)
		v.add_child(UI.row(h2, func(): _open_file(fid), 60))


static func _date(s: String) -> String:
	if s == "":
		return ""
	if s.begins_with("?"):
		return s.substr(1)
	var t := Clock.parse_datetime(s)
	return "%s %s" % [Clock.fmt_date_short(t), Clock.fmt_time(t)]


func _open_file(fid: String) -> void:
	var f := Content.get_item("files", fid)
	if f.is_empty():
		return
	_file = fid
	_folder = str(f.get("folder", ""))
	GameState.data.files_opened[fid] = int(GameState.data.files_opened.get(fid, 0)) + 1
	Events.file_opened.emit(fid)
	UI.clear(_root)
	_root.add_child(UI.header(str(f.get("name", fid)), func(): on_back()))
	var sc := UI.scroll()
	var m := UI.margin(18, 8, 18, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	v.add_child(UI.label("%s · %s" % [f.get("size", ""), _date(str(f.get("date", "")))], 12, "faint"))
	match str(f.get("type", "doc")):
		"doc":
			var r := UI.rich(str(f.get("content", "")), 15)
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(r)
		"log":
			var p := UI.panel(Color(0, 0, 0, 0.5), 6, 10, 10, 10, 10)
			var l := UI.label(str(f.get("content", "")), 12, "ok", true)
			p.add_child(l)
			v.add_child(p)
		"image":
			var pv := PhotoView.new()
			var info := Content.get_item("photos", str(f.photo))
			pv.custom_minimum_size = Vector2(380, 380 / float(info.get("aspect", 0.75)))
			v.add_child(pv)
			pv.set_photo(str(f.photo))
			v.add_child(UI.pill_button("Abrir na Galeria", func():
				if not GameState.data.photos.has(f.photo):
					GameState.add_photo(str(f.photo), "Transferências")
					Events.content_changed.emit("photos")
				phone.open_app("gallery", {"photo": f.photo}), "surf2", "text", 14))
		"audio":
			_audio(v, f)
		"archive":
			_archive(v, fid, f)
	for c in f.get("clues", []):
		Director.add_clue(c)
	Director.notify_player_action()


func _audio(v: VBoxContainer, f: Dictionary) -> void:
	var h := UI.hbox(12)
	var lines_box := UI.vbox(8)
	lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var play := UI.icon_button("play", func(): _play_lines(f, lines_box), 54, "accent")
	play.add_theme_stylebox_override("normal", UI.box(UI.c("surf2"), 27))
	h.add_child(play)
	h.add_child(UI.glyph("wave", 120, "dim"))
	h.add_child(UI.label(str(f.get("duration", "")), 13, "dim"))
	v.add_child(h)
	v.add_child(UI.separator())
	v.add_child(lines_box)


var _playing := false


func _play_lines(f: Dictionary, box: VBoxContainer) -> void:
	if _playing:
		return
	_playing = true
	UI.clear(box)
	for s in f.get("sfx", []):
		Audio.play(s, -4.0)
	if f.get("ambient", "") != "":
		Audio.play(str(f.ambient), -4.0)
	for line in f.get("lines", []):
		if not is_inside_tree() or _file == "":
			_playing = false
			return
		var t := str(line)
		var l := UI.label(t, 15, "faint" if t.begins_with("[") else "text", true)
		box.add_child(l)
		if t.begins_with("["):
			Audio.play("static", -18.0)
		await get_tree().create_timer(1.1 + t.length() * 0.045).timeout
	_playing = false
	var fid := _file
	GameState.set_var("heard_" + fid, true)
	for c in f.get("clues_end", []):
		Director.add_clue(c)
	Director.notify_player_action()


func _archive(v: VBoxContainer, fid: String, f: Dictionary) -> void:
	var opened := GameState.flag("extracted_" + fid)
	v.add_child(UI.label("Arquivo comprimido · %d ficheiros" % f.get("contains", []).size(), 15))
	if opened:
		v.add_child(UI.label("Extraído para " + str(f.get("extract_to", "Documentos")) + ".", 14, "ok"))
		return
	if f.get("password", "") == "":
		v.add_child(UI.pill_button("Extrair", func(): _extract(fid, f), "surf2", "accent"))
		return
	v.add_child(UI.label("Este arquivo está protegido.", 14, "dim"))
	if f.get("hint", "") != "":
		v.add_child(UI.label("Dica do autor: " + str(f.hint), 13, "faint", true))
	var le := LineEdit.new()
	le.secret = true
	le.placeholder_text = "Palavra-passe"
	v.add_child(le)
	var err := UI.label("", 13, "danger", true)
	var attempt := func(_t = ""):
		if UI.norm(le.text, true) == UI.norm(str(f.password), true):
			_extract(fid, f)
		else:
			Audio.play("error")
			GameState.inc_var("pw_fail_" + fid)
			err.text = "Palavra-passe incorreta."
			var fails := int(GameState.get_var("pw_fail_" + fid, 0))
			if fails >= 3 and f.get("hint2", "") != "":
				err.text += "\n" + str(f.hint2)
	le.text_submitted.connect(attempt)
	v.add_child(UI.pill_button("Extrair", attempt, "surf2", "accent"))
	v.add_child(err)


func _extract(fid: String, f: Dictionary) -> void:
	GameState.set_var("extracted_" + fid, true)
	for c in f.get("contains", []):
		if not GameState.data.files.has(c):
			GameState.data.files.append(c)
	Audio.play("unlock")
	Events.content_changed.emit("files")
	phone.toast("%d ficheiros extraídos" % f.get("contains", []).size())
	Director.notify_player_action()
	_open_file(fid)
