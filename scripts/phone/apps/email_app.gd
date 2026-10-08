extends PhoneApp
## Email: inbox, sent, trash; message view with attachments.

const FOLDERS := ["Entrada", "Enviados", "Lixo"]

var _root: VBoxContainer
var _folder := "Entrada"
var _open := ""


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if k == "emails" and _open == "": _show_list())
	if params.get("email", "") != "":
		_show_email(params.email)
	else:
		_show_list()


func on_back() -> bool:
	if _open != "":
		slide(false)
		_show_list()
		return true
	return false


static func email_time(entry: Dictionary, e: Dictionary) -> float:
	if e.has("date"):
		return Clock.parse_datetime(str(e.date))
	return float(entry.get("t", 0.0))


func _show_list() -> void:
	_open = ""
	UI.clear(_root)
	_root.add_child(UI.header("Email", Callable()))
	_root.add_child(UI.tabs(FOLDERS, FOLDERS.find(_folder), func(i):
		_folder = FOLDERS[i]
		_show_list()))
	var sc := UI.scroll()
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	_root.add_child(sc)
	var entries: Array = GameState.data.emails.filter(func(en): return str(Content.get_item("emails", en.id).get("folder", "Entrada")) == _folder)
	entries.sort_custom(func(a, b): return email_time(a, Content.get_item("emails", a.id)) > email_time(b, Content.get_item("emails", b.id)))
	if entries.is_empty():
		v.add_child(UI.empty_state("Nada aqui.", "email"))
	for en in entries:
		var e := Content.get_item("emails", en.id)
		var unread = not GameState.data.emails_read.has(en.id)
		var rv := UI.vbox(2)
		var top := UI.hbox(6)
		var who := UI.label(str(e.get("to_name", "")) if _folder == "Enviados" else str(e.get("from_name", "")), 15, "text" if unread else "dim")
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		top.add_child(who)
		top.add_child(UI.label(Clock.fmt_relative(email_time(en, e)), 12, "accent" if unread else "faint"))
		rv.add_child(top)
		var subj := UI.label(str(e.get("subject", "")), 14, "text" if unread else "dim")
		subj.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rv.add_child(subj)
		var prev := UI.label(str(e.get("body", "")).replace("\n", " ").left(80), 12, "faint")
		prev.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rv.add_child(prev)
		var eid: String = en.id
		v.add_child(UI.row(rv, func(): slide(); _show_email(eid), 82))
		v.add_child(UI.separator())


func _show_email(eid: String) -> void:
	_open = eid
	var e := Content.get_item("emails", eid)
	var entry := {}
	for en in GameState.data.emails:
		if en.id == eid:
			entry = en
	GameState.data.emails_read[eid] = true
	Events.email_opened.emit(eid)
	UI.clear(_root)
	_root.add_child(UI.header("", _show_list))
	var sc := UI.scroll()
	var m := UI.margin(18, 6, 18, 30)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	v.add_child(UI.label(str(e.get("subject", "")), 20, "text", true))
	var fh := UI.hbox(10)
	fh.add_child(UI.avatar(str(e.get("from_contact", "")), 38))
	var fv := UI.vbox(0)
	fv.add_child(UI.label("%s <%s>" % [e.get("from_name", ""), e.get("from", "")], 13, "text", true))
	fv.add_child(UI.label("para %s" % e.get("to", "daniel.reis@mail.pt"), 12, "faint", true))
	var t := email_time(entry, e)
	fv.add_child(UI.label("%s · %s" % [Clock.fmt_date_long(t), Clock.fmt_time(t)], 12, "faint"))
	fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(fv)
	v.add_child(fh)
	v.add_child(UI.separator())
	var body := UI.rich(str(e.get("body", "")), 15)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	for att in e.get("attachments", []):
		v.add_child(_att(att))
	for c in e.get("clues", []):
		Director.add_clue(c)
	Director.notify_player_action()


func _att(att: Dictionary) -> Control:
	var h := UI.hbox(10)
	var title := ""
	var glyph := "doc"
	match att.type:
		"photo":
			title = str(GameState.data.photos.get(att.id, {}).get("file", Content.get_item("photos", att.id).get("file", att.id)))
			glyph = "image"
		"file":
			title = str(Content.get_item("files", att.id).get("name", att.id))
		"page":
			title = str(Content.get_item("pages", att.id).get("url", att.id))
			glyph = "link"
	h.add_child(UI.glyph(glyph, 24, "dim"))
	var l := UI.label(title, 14, "link")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := UI.row(h, func(): _open_att(att), 52)
	b.add_theme_stylebox_override("normal", UI.box(UI.c("surf"), 10))
	return b


func _open_att(att: Dictionary) -> void:
	match att.type:
		"photo":
			if not GameState.data.photos.has(att.id):
				GameState.add_photo(att.id, "Transferências")
				Events.content_changed.emit("photos")
			phone.open_app("gallery", {"photo": att.id})
		"file":
			if not GameState.data.files.has(att.id):
				GameState.data.files.append(att.id)
				Events.content_changed.emit("files")
			phone.open_app("files", {"file": att.id})
		"page":
			GameState.data.browser.unlocked[att.id] = true
			phone.open_app("browser", {"page": att.id})
