extends PhoneApp
## Gallery: albums, photo grid, viewer with zoom/pan, metadata and hidden details.

var _root: VBoxContainer
var _album := "Todas"
var _photo := ""
var _viewer: PhotoViewer


func build() -> void:
	_root = content_root()
	Events.content_changed.connect(func(k): if k == "photos" and _photo == "": _show_grid())
	Events.photo_changed.connect(func(pid): if pid == _photo and _viewer: _viewer.refresh())
	if params.get("photo", "") == "" and str(params.get("param", "")).begins_with("IMG"):
		params.photo = params.param
	if params.get("photo", "") != "":
		_show_photo(params.photo)
	else:
		_show_grid()


func reopen(p: Dictionary) -> void:
	params = p
	if p.get("photo", "") == "" and str(p.get("param", "")).begins_with("IMG"):
		params.photo = p.param
	if params.get("photo", "") != "":
		_show_photo(params.photo)


func on_back() -> bool:
	if _photo != "":
		if params.get("from_thread", "") != "":
			var th: String = params.from_thread
			params = {}
			phone.open_app("messages", {"thread": th})
			return true
		slide(false)
		_show_grid()
		return true
	return false


static func photo_info(pid: String) -> Dictionary:
	## Static data merged with dynamic (player-taken) photos.
	var d := Content.get_item("photos", pid)
	if not d.is_empty():
		return d
	var st: Dictionary = GameState.data.photos.get(pid, {})
	if st.has("dyn"):
		var base := Content.get_item("photos", st.dyn.scene_id).duplicate(true)
		base.file = st.dyn.file
		base.date = st.dyn.date
		base.place = st.dyn.get("place", "")
		base.device = "Lumen One"
		base.album = "Câmara"
		base.erase("hotspots")
		return base
	return {}


func _albums() -> Array:
	var out := ["Todas"]
	for pid in GameState.data.photo_order:
		var a: String = GameState.data.photos[pid].get("album", "Câmara")
		if not out.has(a):
			out.append(a)
	return out


func _show_grid() -> void:
	_photo = ""
	_viewer = null
	UI.clear(_root)
	_root.add_child(UI.header("Galeria", Callable()))
	var albums := _albums()
	if not albums.has(_album):
		_album = "Todas"
	var tabs_scroll := ScrollContainer.new()
	tabs_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs_scroll.custom_minimum_size = Vector2(0, 46)
	var th := UI.hbox(6)
	for a in albums:
		var b := UI.pill_button(a, func():
			_album = a
			_show_grid(), "accent" if a == _album else "surf2", "bg" if a == _album else "dim", 13)
		th.add_child(b)
	var tm := UI.margin(10, 0, 10, 6)
	tm.add_child(th)
	tabs_scroll.add_child(tm)
	_root.add_child(tabs_scroll)
	var sc := UI.scroll()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	sc.add_child(grid)
	_root.add_child(sc)
	var n := 0
	var last_month := ""
	for pid in GameState.data.photo_order:
		var st: Dictionary = GameState.data.photos[pid]
		if _album != "Todas" and st.get("album", "") != _album:
			continue
		grid.add_child(_thumb(pid, st.get("new", false)))
		n += 1
	if n == 0:
		_root.add_child(UI.empty_state("Sem fotografias.", "gallery"))
	var cnt := UI.label("%d fotografias" % n, 12, "faint")
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(cnt)


func _thumb(pid: String, is_new: bool) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(137, 137)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_ALL
	b.clip_contents = true
	var info := photo_info(pid)
	var pv := PhotoView.new()
	var aspect: float = float(info.get("aspect", 0.75))
	# centre-crop to square
	if aspect < 1.0:
		pv.size = Vector2(137, 137 / aspect)
		pv.position = Vector2(0, -(pv.size.y - 137) / 2)
	else:
		pv.size = Vector2(137 * aspect, 137)
		pv.position = Vector2(-(pv.size.x - 137) / 2, 0)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pv)
	_set_pv(pv, pid)
	if is_new:
		var dot := ColorRect.new()
		dot.color = UI.c("accent")
		dot.size = Vector2(8, 8)
		dot.position = Vector2(122, 7)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
	b.pressed.connect(func(): slide(); _show_photo(pid))
	UI.press_fx(b, 0.94)
	return b


static func _set_pv(pv: PhotoView, pid: String) -> void:
	if Content.has_item("photos", pid):
		pv.set_photo(pid)
		return
	var st: Dictionary = GameState.data.photos.get(pid, {})
	if st.has("dyn"):
		var base := Content.get_item("photos", st.dyn.scene_id)
		pv.set_scene(base.get("scene", {}), st.dyn.get("variant", "base"))


func _show_photo(pid: String) -> void:
	if not GameState.data.photos.has(pid):
		GameState.add_photo(pid, "Mensagens")
	_photo = pid
	GameState.data.photos[pid].new = false
	GameState.data.viewed[pid] = int(GameState.data.viewed.get(pid, 0)) + 1
	GameState.current_app = "gallery:" + pid
	Events.photo_viewed.emit(pid)
	Director.notify_player_action()
	UI.clear(_root)
	var info := photo_info(pid)
	var info_b := UI.icon_button("info", func(): _meta_sheet(pid), 40, "text")
	info_b.tooltip_text = "Detalhes"
	var wall_b := UI.icon_button("image", func():
		GameState.data.phone.wallpaper = pid
		Events.phone_state_changed.emit()
		phone.toast("Definida como fundo"), 40, "dim")
	wall_b.tooltip_text = "Definir como fundo"
	wall_b.visible = Content.has_item("photos", pid)
	var pair := str(info.get("pair", ""))
	var cmp_b := UI.icon_button("gallery", func(): _compare(pid, pair), 40, "dim")
	cmp_b.tooltip_text = "Comparar com " + pair + ".jpg"
	cmp_b.visible = pair != "" and GameState.data.photos.has(pair)
	_root.add_child(UI.header(str(info.get("file", pid)), on_back_btn, [cmp_b, wall_b, info_b]))
	_viewer = PhotoViewer.new()
	_viewer.pid = pid
	_viewer.app = self
	_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_viewer)
	var bar := UI.hbox(6)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(UI.icon_button("zoom_in", func(): _viewer.zoom_by(1.5), 40, "dim"))
	var zl := UI.label("Roda do rato ou duplo clique para ampliar · arrastar para mover", 11, "faint")
	bar.add_child(zl)
	var bm := UI.margin(8, 4, 8, 6)
	bm.add_child(bar)
	_root.add_child(bm)


## Two near-identical photos, one above the other.
func _compare(a: String, b: String) -> void:
	GameState.set_var("compared_" + a, true)
	GameState.set_var("compared_" + b, true)
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(bg)
	var v := UI.vbox(6)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = Phone.STATUS_H + 6
	v.offset_bottom = -Phone.NAV_H
	sheet.add_child(v)
	var top := UI.hbox(6)
	top.add_child(UI.icon_button("close", func(): sheet.queue_free(), 40, "text"))
	top.add_child(UI.label("Comparar", 18))
	v.add_child(top)
	for pid in [a, b]:
		var info := photo_info(pid)
		v.add_child(UI.label("%s · %s" % [info.get("file", pid), _fmt_date(str(info.get("date", "")))], 12, "faint"))
		var pv := PhotoView.new()
		var h := 330.0
		pv.custom_minimum_size = Vector2(h * float(info.get("aspect", 1.0)), h)
		pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(pv)
		_set_pv(pv, pid)
	v.add_child(UI.label("Toca numa fotografia na galeria e amplia para ver pormenores.", 11, "faint", true))
	add_child(sheet)
	Director.notify_player_action()


func on_back_btn() -> void:
	on_back()


func _meta_sheet(pid: String) -> void:
	var info := photo_info(pid)
	var v_id := GameState.photo_variant(pid)
	var meta: Dictionary = {}
	for k in ["file", "date", "place", "device", "size", "origin"]:
		if info.has(k):
			meta[k] = info[k]
	var over: Dictionary = info.get("meta_variants", {}).get(v_id, {})
	for k in over:
		meta[k] = over[k]
	var sheet := Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: sheet.queue_free())
	sheet.add_child(dim)
	var p := UI.panel(UI.c("surf"), 18, 22, 18, 22, 30)
	p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_top = -360
	sheet.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.label("Detalhes", 18))
	var rows := [
		["Nome", meta.get("file", pid)],
		["Data", _fmt_date(str(meta.get("date", "")))],
		["Local", meta.get("place", "—") if str(meta.get("place", "")) != "" else "Sem dados de localização"],
		["Dispositivo", meta.get("device", "—")],
		["Tamanho", meta.get("size", "3024 × 4032 · 2,8 MB")],
		["Origem", meta.get("origin", _origin(pid))],
	]
	for r in rows:
		var h := UI.hbox(10)
		var k := UI.label(r[0], 14, "dim")
		k.custom_minimum_size = Vector2(110, 0)
		h.add_child(k)
		var val := UI.label(str(r[1]), 14, "text", true)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(val)
		v.add_child(h)
	add_child(sheet)
	GameState.set_var("meta_" + pid, true)
	for c in info.get("meta_clues", []):
		Director.add_clue(c)
	Director.notify_player_action()


func _origin(pid: String) -> String:
	var st: Dictionary = GameState.data.photos.get(pid, {})
	match st.get("album", ""):
		"Mensagens": return "Recebida por mensagem"
		"Câmara": return "Câmara deste dispositivo"
		"Recuperadas": return "Cópia de segurança (nuvem)"
		"Transferências": return "Transferida"
	return str(st.get("album", "Desconhecida"))


static func _fmt_date(s: String) -> String:
	if s == "":
		return "Desconhecida"
	if s.begins_with("?"):
		return s.substr(1)
	var t := Clock.parse_datetime(s)
	return "%s · %s" % [Clock.fmt_date_short(t), Clock.fmt_time(t)]


func hotspot_clicked(h: Dictionary) -> void:
	var clue: String = h.get("clue", "")
	if h.get("flag", "") != "":
		GameState.set_var(h.flag, true)
	if clue != "" and not GameState.has_clue(clue):
		Director.add_clue(clue)
		phone.toast(str(h.get("label", "Reparaste num pormenor.")))
	elif clue == "" and h.get("label", "") != "":
		phone.toast(str(h.label))
	Director.notify_player_action()


class PhotoViewer extends Control:
	var pid := ""
	var app
	var zoom := 1.0
	var pan := Vector2.ZERO
	var _pv: PhotoView
	var _dragging := false
	var _drag_moved := 0.0
	var _base_size := Vector2.ZERO

	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		var bg := ColorRect.new()
		bg.color = Color.BLACK
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		_pv = PhotoView.new()
		_pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_pv)
		refresh()
		resized.connect(_layout)

	func refresh() -> void:
		app._set_pv(_pv, pid)
		_layout()

	func _layout() -> void:
		if size.x <= 0:
			return
		var info: Dictionary = app.photo_info(pid)
		var aspect: float = float(info.get("aspect", 0.75))
		var w := size.x
		var h := w / aspect
		if h > size.y:
			h = size.y
			w = h * aspect
		_base_size = Vector2(w, h)
		_pv.size = _base_size * zoom
		var max_pan := (_pv.size - size) / 2.0
		max_pan = max_pan.max(Vector2.ZERO)
		pan = pan.clamp(-max_pan, max_pan)
		_pv.position = (size - _pv.size) / 2.0 + pan

	func zoom_by(f: float, at := Vector2(-1, -1)) -> void:
		var old := zoom
		zoom = clampf(zoom * f, 1.0, 5.0)
		if at.x >= 0:
			var rel := at - size / 2.0 - pan
			pan -= rel * (zoom / old - 1.0)
		if zoom == 1.0:
			pan = Vector2.ZERO
		_layout()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				zoom_by(1.2, event.position)
				accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				zoom_by(1.0 / 1.2, event.position)
				accept_event()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.double_click:
					if zoom > 1.01:
						zoom = 1.0
						pan = Vector2.ZERO
						_layout()
					else:
						zoom_by(2.5, event.position)
				elif event.pressed:
					_dragging = true
					_drag_moved = 0.0
				else:
					_dragging = false
					if _drag_moved < 6.0:
						_click(event.position)
		elif event is InputEventMouseMotion and _dragging:
			pan += event.relative
			_drag_moved += event.relative.length()
			_layout()

	func _click(pos: Vector2) -> void:
		var info: Dictionary = app.photo_info(pid)
		var local := (pos - _pv.position) / _pv.size
		var variant := GameState.photo_variant(pid)
		for h in info.get("hotspots", []):
			if h.has("variant") and h.variant != variant:
				continue
			if zoom < float(h.get("zoom", 1.0)) - 0.01:
				continue
			if h.has("when") and not Director.check(h.when):
				continue
			var r: Array = h.r
			if local.x >= float(r[0]) and local.y >= float(r[1]) and local.x <= float(r[0]) + float(r[2]) and local.y <= float(r[1]) + float(r[3]):
				app.hotspot_clicked(h)
				return
