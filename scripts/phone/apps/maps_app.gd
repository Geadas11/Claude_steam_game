extends PhoneApp
## Maps: a hand-drawn fictional Salgueira, searchable places, distances and the
## location timeline (with one day that should not be empty).

var _root: VBoxContainer
var _map: MapView
var _card: Control
var _tab := 0


func build() -> void:
	_root = content_root()
	_render()


func on_back() -> bool:
	if _card and is_instance_valid(_card) and _card.visible:
		_card.visible = false
		return true
	return false


func _render() -> void:
	UI.clear(_root)
	_root.add_child(UI.header("Mapas", Callable()))
	_root.add_child(UI.tabs(["Explorar", "Cronologia"], _tab, func(i):
		_tab = i
		_render()))
	if _tab == 0:
		_explore()
	else:
		_timeline()


func _explore() -> void:
	var bar := UI.margin(10, 6, 10, 6)
	var le := LineEdit.new()
	le.placeholder_text = "Procurar local"
	le.text_submitted.connect(_search)
	bar.add_child(le)
	_root.add_child(bar)
	var holder := Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	_root.add_child(holder)
	_map = MapView.new()
	_map.app = self
	_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_map)
	_card = UI.panel(UI.c("surf"), 16, 16, 14, 16, 14)
	_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_card.offset_top = -210
	_card.offset_left = 8
	_card.offset_right = -8
	_card.offset_bottom = -8
	_card.visible = false
	holder.add_child(_card)
	var loc_btn := UI.icon_button("locate", func(): _map.center_on(GameState.data.location), 44, "text")
	loc_btn.add_theme_stylebox_override("normal", UI.box(UI.c("surf2"), 22))
	loc_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	loc_btn.position = Vector2(UI.SCREEN.x - 60, 10)
	holder.add_child(loc_btn)
	if params.get("param", "") != "":
		_map.center_on.call_deferred(params.param)
		show_location.call_deferred(params.param)


func _search(q: String) -> void:
	var nq := q.to_lower().strip_edges()
	var locs: Dictionary = Content.all("map").get("locations", {})
	for id in locs:
		var l: Dictionary = locs[id]
		if not _loc_visible(id):
			continue
		var hay := (str(l.name) + " " + str(l.get("address", "")) + " " + " ".join(PackedStringArray(l.get("keywords", [])))).to_lower()
		if hay.contains(nq) or nq.contains(str(l.name).to_lower()):
			_map.center_on(id)
			show_location(id)
			return
	phone.toast("Nenhum local encontrado.")


static func _loc_visible(id: String) -> bool:
	var l: Dictionary = Content.all("map").get("locations", {}).get(id, {})
	if l.is_empty():
		return false
	var req := str(l.get("requires", ""))
	return req == "" or GameState.data.map_marks.has(id) or Director.check(req)


func show_location(id: String) -> void:
	var l: Dictionary = Content.all("map").get("locations", {}).get(id, {})
	if l.is_empty() or _card == null:
		return
	GameState.set_var("viewed_loc_" + id, true)
	Events.location_viewed.emit(id)
	UI.clear(_card)
	var v := UI.vbox(6)
	_card.add_child(v)
	var top := UI.hbox(8)
	var t := UI.label(str(l.name), 18)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	top.add_child(UI.icon_button("close", func(): _card.visible = false, 32, "dim"))
	v.add_child(top)
	v.add_child(UI.label(str(l.get("address", "")), 13, "faint", true))
	var here: Dictionary = Content.all("map").get("locations", {}).get(GameState.data.location, {})
	if not here.is_empty() and id != GameState.data.location:
		var d := Vector2(float(here.x), float(here.y)).distance_to(Vector2(float(l.x), float(l.y))) * float(Content.all("map").get("km_per_unit", 4.0))
		v.add_child(UI.label("%.1f km de ti · %d min a pé" % [d, int(d / 4.8 * 60.0)], 13, "accent"))
	elif id == GameState.data.location:
		v.add_child(UI.label("Estás aqui.", 13, "accent"))
	var desc := str(l.get("desc", ""))
	for alt in l.get("alt", []):
		if Director.check(str(alt.when)):
			desc = str(alt.desc)
	v.add_child(UI.label(desc, 14, "dim", true))
	_card.visible = true
	for c in l.get("clues", []):
		Director.add_clue(c)
	Director.notify_player_action()


func _timeline() -> void:
	var sc := UI.scroll()
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(14, 10, 14, 20)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	v.add_child(UI.label("A tua cronologia guarda os locais por onde passaste.", 12, "faint", true))
	var tl: Dictionary = Content.all("map").get("timeline", {})
	var days: Array = tl.keys()
	days.sort()
	days.reverse()
	# live entries from this week
	var by_day := {}
	for e in GameState.data.location_log:
		var dd := Time.get_datetime_dict_from_unix_time(int(e.t))
		var key := "%04d-%02d-%02d" % [dd.year, dd.month, dd.day]
		if not by_day.has(key):
			by_day[key] = []
		by_day[key].append(e)
	var live_days: Array = by_day.keys()
	live_days.sort()
	live_days.reverse()
	for key in live_days:
		_day_header(v, key)
		for e in by_day[key]:
			_tl_row(v, Clock.fmt_time(float(e.t)), str(e.loc))
	for day in days:
		var entry: Dictionary = tl[day]
		_day_header(v, day)
		var unlocked := str(entry.get("requires", "")) == "" or Director.check(str(entry.requires))
		if not unlocked:
			var l := UI.label(str(entry.get("empty_text", "Sem dados de localização para este dia.")), 13, "faint", true)
			v.add_child(l)
			GameState.set_var("saw_empty_" + day, true)
			continue
		for row in entry.get("stops", []):
			_tl_row(v, str(row.t), str(row.loc), str(row.get("note", "")))
		for c in entry.get("clues", []):
			Director.add_clue(c)
	Director.notify_player_action()


func _day_header(v: VBoxContainer, key: String) -> void:
	var t := Clock.parse_datetime(key)
	var m := UI.margin(0, 10, 0, 2)
	m.add_child(UI.label(Clock.fmt_date_long(t) + " de " + key.left(4), 14, "accent"))
	v.add_child(m)


func _tl_row(v: VBoxContainer, time_s: String, loc_id: String, note := "") -> void:
	var l: Dictionary = Content.all("map").get("locations", {}).get(loc_id, {})
	var h := UI.hbox(12)
	var tl := UI.label(time_s, 14, "dim")
	tl.custom_minimum_size = Vector2(52, 0)
	h.add_child(tl)
	h.add_child(UI.glyph("pin", 18, "accent"))
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(str(l.get("name", loc_id)), 15))
	if note != "":
		tv.add_child(UI.label(note, 12, "faint", true))
	h.add_child(tv)
	v.add_child(UI.row(h, func():
		_tab = 0
		_render()
		_map.center_on.call_deferred(loc_id)
		show_location.call_deferred(loc_id), 52))


class MapView extends Control:
	var app
	var offset := Vector2.ZERO
	var zoom := 1.0
	var _drag := false
	var _moved := 0.0
	const W := 1000.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true
		resized.connect(func(): if offset == Vector2.ZERO: center_on(GameState.data.location))

	func to_screen(p: Vector2) -> Vector2:
		return (p * W - offset) * zoom + size / 2.0

	func center_on(loc_id: String) -> void:
		var l: Dictionary = Content.all("map").get("locations", {}).get(loc_id, {})
		if l.is_empty():
			return
		offset = Vector2(float(l.x), float(l.y)) * W
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				zoom = clampf(zoom * 1.15, 0.5, 3.0)
				queue_redraw()
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				zoom = clampf(zoom / 1.15, 0.5, 3.0)
				queue_redraw()
			elif e.button_index == MOUSE_BUTTON_LEFT:
				if e.pressed:
					_drag = true
					_moved = 0.0
				else:
					_drag = false
					if _moved < 6:
						_click(e.position)
		elif e is InputEventMouseMotion and _drag:
			offset -= e.relative / zoom
			_moved += e.relative.length()
			queue_redraw()

	func _click(pos: Vector2) -> void:
		var locs: Dictionary = Content.all("map").get("locations", {})
		var best := ""
		var bd := 26.0
		for id in locs:
			if not app._loc_visible(id):
				continue
			var sp := to_screen(Vector2(float(locs[id].x), float(locs[id].y)))
			var d := sp.distance_to(pos)
			if d < bd:
				bd = d
				best = id
		if best != "":
			app.show_location(best)

	func _draw() -> void:
		var m: Dictionary = Content.all("map")
		draw_rect(Rect2(Vector2.ZERO, size), Color("1b2129"))
		# land
		var land := PackedVector2Array()
		for pt in m.get("land", []):
			land.append(to_screen(Vector2(float(pt[0]), float(pt[1]))))
		if land.size() >= 3:
			draw_colored_polygon(land, Color("232a22"))
		# sea label
		for area in m.get("areas", []):
			var poly := PackedVector2Array()
			for pt in area.pts:
				poly.append(to_screen(Vector2(float(pt[0]), float(pt[1]))))
			if poly.size() >= 3:
				draw_colored_polygon(poly, Color(str(area.c)))
		for road in m.get("roads", []):
			var pts := PackedVector2Array()
			for pt in road.pts:
				pts.append(to_screen(Vector2(float(pt[0]), float(pt[1]))))
			var w: float = float(road.get("w", 4.0)) * zoom
			draw_polyline(pts, Color("39404a") if road.get("major", false) else Color("2f353d"), w, true)
		var font := get_theme_default_font()
		for lab in m.get("labels", []):
			var p := to_screen(Vector2(float(lab.x), float(lab.y)))
			draw_string(font, p, str(lab.t), HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * clampf(zoom, 0.8, 1.4)), Color(1, 1, 1, float(lab.get("a", 0.35))))
		var locs: Dictionary = m.get("locations", {})
		for id in locs:
			if not app._loc_visible(id):
				continue
			var l: Dictionary = locs[id]
			var sp := to_screen(Vector2(float(l.x), float(l.y)))
			var col := Color(str(l.get("color", "#d9b26f")))
			Glyph.draw_glyph(self, "pin", Rect2(sp - Vector2(13, 26), Vector2(26, 26)), col)
			draw_string(font, sp + Vector2(10, 4), str(l.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.75))
		var here: Dictionary = locs.get(GameState.data.location, {})
		if not here.is_empty():
			var hp := to_screen(Vector2(float(here.x), float(here.y)))
			draw_circle(hp, 14, Color(0.4, 0.65, 1.0, 0.18))
			draw_circle(hp, 7, Color(0.45, 0.7, 1.0))
			draw_arc(hp, 7, 0, TAU, 20, Color.WHITE, 2, true)
