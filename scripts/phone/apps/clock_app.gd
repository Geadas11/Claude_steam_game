extends PhoneApp
## Clock: time, alarms (including ones Daniel never set), world clock, stopwatch.

const TABS := ["Relógio", "Alarmes", "Cronómetro"]

var _root: VBoxContainer
var _tab := 0
var _big: Label
var _date: Label
var _sw_label: Label
var _sw_running := false
var _sw_time := 0.0


func build() -> void:
	_root = content_root()
	Events.time_changed.connect(func(_t): _tick())
	Events.content_changed.connect(func(k): if k == "alarms": _render())
	_render()


func _render() -> void:
	UI.clear(_root)
	_root.add_child(UI.header("Relógio", Callable()))
	_root.add_child(UI.tabs(TABS, _tab, func(i):
		_tab = i
		_render()))
	var sc := UI.scroll()
	var v := UI.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(18, 20, 18, 20)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(v)
	sc.add_child(m)
	_root.add_child(sc)
	match _tab:
		0: _clock(v)
		1: _alarms(v)
		2: _stopwatch(v)


func _clock(v: VBoxContainer) -> void:
	var face := ClockFace.new()
	face.custom_minimum_size = Vector2(240, 240)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(face)
	_big = UI.label("", 44)
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_big)
	_date = UI.label("", 15, "dim")
	_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_date)
	v.add_child(UI.spacer(20))
	v.add_child(UI.label("Outras cidades", 13, "accent"))
	var cities := [["Salgueira (local)", 0], ["Londres", 0], ["Nova Iorque", -5], ["Tóquio", 8]]
	if GameState.flag("clock_extra_city"):
		cities.append(["Cais Velho", "03:17"])
	for c in cities:
		var h := UI.hbox(8)
		var n := UI.label(str(c[0]), 15)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		var t := ""
		if typeof(c[1]) == TYPE_STRING:
			t = c[1]
		else:
			t = Clock.fmt_time(Clock.now() + int(c[1]) * 3600)
		h.add_child(UI.label(t, 15, "danger" if typeof(c[1]) == TYPE_STRING else "dim"))
		v.add_child(h)
	_tick()
	GameState.set_var("checked_clock", true)
	Director.notify_player_action()


func _tick() -> void:
	if _big and is_instance_valid(_big):
		_big.text = Clock.display_time()
		_date.text = Clock.fmt_date_long(Clock.now())


func _alarms(v: VBoxContainer) -> void:
	for i in GameState.data.alarms.size():
		var a: Dictionary = GameState.data.alarms[i]
		var h := UI.hbox(10)
		var tv := UI.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.label(str(a.time), 34, "text" if a.get("on", true) else "faint"))
		tv.add_child(UI.label(str(a.get("label", "")), 13, "dim"))
		h.add_child(tv)
		var cb := CheckButton.new()
		cb.button_pressed = a.get("on", true)
		var idx = i
		cb.toggled.connect(func(on):
			GameState.data.alarms[idx].on = on
			if a.get("foreign", false) and not on:
				GameState.set_var("disabled_foreign_alarm", true)
				Director.notify_player_action())
		h.add_child(cb)
		var p := UI.panel(UI.c("surf"), 14, 16, 10, 16, 10)
		p.add_child(h)
		v.add_child(p)
		if a.get("foreign", false):
			GameState.set_var("saw_foreign_alarm", true)
			Director.notify_player_action()


func _stopwatch(v: VBoxContainer) -> void:
	_sw_label = UI.label(_fmt_sw(), 48)
	_sw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_sw_label)
	var h := UI.hbox(20)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(UI.pill_button("Iniciar / Parar", func(): _sw_running = not _sw_running, "surf2"))
	h.add_child(UI.pill_button("Repor", func():
		_sw_running = false
		_sw_time = 0.0
		_sw_label.text = _fmt_sw(), "surf2", "dim"))
	v.add_child(h)


func _fmt_sw() -> String:
	return "%02d:%02d.%d" % [int(_sw_time) / 60, int(_sw_time) % 60, int(_sw_time * 10) % 10]


func _process(delta: float) -> void:
	if _sw_running:
		_sw_time += delta
		if _sw_label and is_instance_valid(_sw_label):
			_sw_label.text = _fmt_sw()


class ClockFace extends Control:
	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 4
		draw_circle(c, r, Color(1, 1, 1, 0.04))
		draw_arc(c, r, 0, TAU, 64, Color(1, 1, 1, 0.2), 2, true)
		for i in 12:
			var a := i * TAU / 12.0
			var d := Vector2(sin(a), -cos(a))
			draw_line(c + d * r * 0.86, c + d * r * 0.95, Color(1, 1, 1, 0.5), 2, true)
		var t := Time.get_datetime_dict_from_unix_time(int(Clock.now()))
		var sec := fmod(Clock.now(), 60.0)
		var hm = (t.hour % 12) + t.minute / 60.0
		var ha = hm * TAU / 12.0
		var ma = (t.minute + sec / 60.0) * TAU / 60.0
		draw_line(c, c + Vector2(sin(ha), -cos(ha)) * r * 0.5, Color(1, 1, 1, 0.9), 5, true)
		draw_line(c, c + Vector2(sin(ma), -cos(ma)) * r * 0.75, Color(1, 1, 1, 0.8), 3, true)
		var sa := sec * TAU / 60.0
		draw_line(c, c + Vector2(sin(sa), -cos(sa)) * r * 0.82, Color("d9b26f"), 1.5, true)
		draw_circle(c, 5, Color("d9b26f"))
