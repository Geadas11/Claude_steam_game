class_name Phone
extends Control
## The smartphone: frame, screen, lock screen, home screen, status bar,
## notification banners, call overlay and screen effects.

const STATUS_H := 30
const NAV_H := 38
const BEZEL := 14

const APPS := {
	"messages": {"name": "Mensagens", "glyph": "messages", "color": "#3b7357", "script": "res://scripts/phone/apps/messages_app.gd"},
	"phone": {"name": "Telefone", "glyph": "phone", "color": "#33677a", "script": "res://scripts/phone/apps/dialer_app.gd"},
	"contacts": {"name": "Contactos", "glyph": "contacts", "color": "#6e5a39", "script": "res://scripts/phone/apps/contacts_app.gd"},
	"gallery": {"name": "Galeria", "glyph": "gallery", "color": "#7a3d5a", "script": "res://scripts/phone/apps/gallery_app.gd"},
	"camera": {"name": "Câmara", "glyph": "camera", "color": "#3a3f47", "script": "res://scripts/phone/apps/camera_app.gd"},
	"browser": {"name": "Navegador", "glyph": "browser", "color": "#3b5378", "script": "res://scripts/phone/apps/browser_app.gd"},
	"maps": {"name": "Mapas", "glyph": "maps", "color": "#4d7539", "script": "res://scripts/phone/apps/maps_app.gd"},
	"email": {"name": "Email", "glyph": "email", "color": "#7a573a", "script": "res://scripts/phone/apps/email_app.gd"},
	"notes": {"name": "Notas", "glyph": "notes", "color": "#8a7633", "script": "res://scripts/phone/apps/notes_app.gd"},
	"files": {"name": "Ficheiros", "glyph": "files", "color": "#465566", "script": "res://scripts/phone/apps/files_app.gd"},
	"settings": {"name": "Definições", "glyph": "settings", "color": "#4a4f57", "script": "res://scripts/phone/apps/settings_app.gd"},
	"clock": {"name": "Relógio", "glyph": "clock", "color": "#2c3240", "script": "res://scripts/phone/apps/clock_app.gd"},
	"eco": {"name": "ECO", "glyph": "eco", "color": "#070707", "script": "res://scripts/phone/apps/eco_app.gd"},
}
const GRID := ["contacts", "gallery", "maps", "email", "notes", "files", "clock", "settings"]
const DOCK := ["phone", "messages", "browser", "camera"]

var screen: Control
var wallpaper: PhotoView
var home: Control
var app_layer: Control
var lock_layer: Control
var status_bar: Control
var nav_bar: Control
var banner_layer: Control
var call_layer: Control
var fx_layer: ColorRect
var off_layer: ColorRect
var toast_label: Label

var current_app: PhoneApp
var current_app_id := ""
var locked := true
var interactive := true

var _status_time: Label
var _status_batt: Label
var _status_icons: Control
var _banner_queue: Array = []
var _banner_showing := false
var _fx_tween: Tween
var _call_ui: CallScreen
var _lock_screen: LockScreen
var _home_badges := {}
var _base_pos := Vector2.ZERO
var using_pad := false


func _ready() -> void:
	custom_minimum_size = UI.SCREEN + Vector2(BEZEL * 2, BEZEL * 2)
	size = custom_minimum_size
	theme = UI.build_theme()
	_build_frame()
	_build_screen()
	Events.time_changed.connect(func(_t): _update_status())
	Events.phone_state_changed.connect(_on_phone_state)
	Events.notification_posted.connect(_on_notification)
	Events.open_app_requested.connect(_on_open_request)
	Events.lock_requested.connect(lock)
	Events.glitch_requested.connect(glitch)
	Events.vibrate_requested.connect(vibrate)
	Events.toast_requested.connect(toast)
	Events.screen_off_requested.connect(screen_off)
	Events.restart_requested.connect(restart)
	Events.reflection_requested.connect(reflection)
	Events.call_incoming.connect(_on_call)
	Events.call_started.connect(_on_call_started)
	Events.message_added.connect(func(_a, _b): _refresh_badges())
	Events.thread_read.connect(func(_a): _refresh_badges())
	Events.content_changed.connect(func(_k): _refresh_badges())
	Events.settings_changed.connect(_on_settings_changed)
	_update_status()


func _on_settings_changed() -> void:
	theme = UI.build_theme()
	_refresh_home()


# ================================================================= building
func _build_frame() -> void:
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := UI.box(Color("0d0e10"), 46, Color("2b2d31"), 2)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 40
	frame.add_theme_stylebox_override("panel", sb)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	# side buttons
	for y in [150.0, 210.0]:
		var b := ColorRect.new()
		b.color = Color("1b1c1f")
		b.position = Vector2(-3, y)
		b.size = Vector2(3, 46)
		add_child(b)
	var pw := ColorRect.new()
	pw.color = Color("1b1c1f")
	pw.position = Vector2(size.x, 180)
	pw.size = Vector2(3, 70)
	add_child(pw)


func _build_screen() -> void:
	screen = Control.new()
	screen.position = Vector2(BEZEL, BEZEL)
	screen.size = UI.SCREEN
	screen.clip_contents = true
	add_child(screen)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(black)
	wallpaper = PhotoView.new()
	wallpaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(wallpaper)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(dim)
	home = Control.new()
	home.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(home)
	app_layer = Control.new()
	app_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	app_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(app_layer)
	_build_status_bar()
	_build_nav_bar()
	lock_layer = Control.new()
	lock_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	lock_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(lock_layer)
	banner_layer = Control.new()
	banner_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(banner_layer)
	call_layer = Control.new()
	call_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	call_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(call_layer)
	# status bar must stay above lock screen, apps and calls
	screen.move_child(status_bar, -1)
	toast_label = UI.label("", 14)
	var tp := UI.panel(Color(0.12, 0.13, 0.15, 0.95), 16, 14, 8, 14, 8)
	tp.name = "Toast"
	tp.add_child(toast_label)
	tp.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tp.position = Vector2(UI.SCREEN.x / 2 - 120, UI.SCREEN.y - 110)
	tp.custom_minimum_size = Vector2(240, 0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tp.modulate.a = 0.0
	tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(tp)
	fx_layer = ColorRect.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/ui/glitch.gdshader")
	fx_layer.material = mat
	fx_layer.visible = false
	screen.add_child(fx_layer)
	off_layer = ColorRect.new()
	off_layer.color = Color.BLACK
	off_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	off_layer.visible = false
	off_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(off_layer)
	_build_home()
	_lock_screen = LockScreen.new()
	_lock_screen.phone = self
	_lock_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	lock_layer.add_child(_lock_screen)
	_call_ui = CallScreen.new()
	_call_ui.phone = self
	_call_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_call_ui.visible = false
	call_layer.add_child(_call_ui)
	_update_wallpaper()


func _build_status_bar() -> void:
	status_bar = Control.new()
	status_bar.size = Vector2(UI.SCREEN.x, STATUS_H)
	status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(status_bar)
	var h := UI.hbox(6)
	h.position = Vector2(18, 4)
	h.size = Vector2(UI.SCREEN.x - 36, 22)
	status_bar.add_child(h)
	_status_time = UI.label("00:00", 14)
	h.add_child(_status_time)
	h.add_child(UI.expand())
	_status_icons = StatusIcons.new()
	_status_icons.custom_minimum_size = Vector2(52, 20)
	h.add_child(_status_icons)
	_status_batt = UI.label("82%", 13)
	h.add_child(_status_batt)


func _build_nav_bar() -> void:
	nav_bar = Control.new()
	nav_bar.position = Vector2(0, UI.SCREEN.y - NAV_H)
	nav_bar.size = Vector2(UI.SCREEN.x, NAV_H)
	screen.add_child(nav_bar)
	var back_b := UI.icon_button("back", back, 36, "dim")
	back_b.position = Vector2(26, 1)
	back_b.tooltip_text = "Voltar (Backspace)"
	nav_bar.add_child(back_b)
	var home_b := Button.new()
	home_b.position = Vector2(UI.SCREEN.x / 2 - 60, 6)
	home_b.size = Vector2(120, 26)
	home_b.tooltip_text = "Ecrã principal (H)"
	home_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pill := ColorRect.new()
	pill.color = Color(1, 1, 1, 0.55)
	pill.size = Vector2(110, 5)
	pill.position = Vector2(5, 11)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_b.add_child(pill)
	home_b.pressed.connect(go_home)
	nav_bar.add_child(home_b)


func _build_home() -> void:
	UI.clear(home)
	_home_badges.clear()
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = STATUS_H + 30
	v.offset_bottom = -NAV_H - 8
	home.add_child(v)
	# clock widget
	var w := UI.vbox(2)
	var t := UI.label("", 54)
	t.name = "HomeClock"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_child(t)
	var d := UI.label("", 15, "dim")
	d.name = "HomeDate"
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w.add_child(d)
	v.add_child(w)
	v.add_child(UI.expand())
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 18)
	var gm := UI.margin(14, 0, 14, 0)
	gm.add_child(grid)
	v.add_child(gm)
	var apps: Array = GRID.duplicate()
	if GameState.data.phone.get("eco_app", false):
		apps.append("eco")
	for id in apps:
		grid.add_child(_app_icon(id, true))
	v.add_child(UI.spacer(26))
	var dock := UI.panel(Color(1, 1, 1, 0.07), 26, 10, 10, 10, 10)
	var dh := UI.hbox(6)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(dh)
	for id in DOCK:
		dh.add_child(_app_icon(id, false))
	var dm := UI.margin(12, 0, 12, 0)
	dm.add_child(dock)
	v.add_child(dm)
	_update_status()
	_refresh_badges()


func _app_icon(id: String, with_label: bool) -> Control:
	var info: Dictionary = APPS[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(90, 84 if with_label else 66)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = info.name
	var icon := AppIcon.new()
	icon.glyph = info.glyph
	icon.bg = Color(info.color)
	icon.size = Vector2(58, 58)
	icon.position = Vector2(16, 2)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	if with_label:
		var l := UI.label(info.name, 12)
		l.position = Vector2(0, 62)
		l.size = Vector2(90, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l)
	var badge := UI.panel(UI.c("danger"), 10, 6, 0, 6, 0)
	var bl := UI.label("", 11)
	badge.add_child(bl)
	badge.position = Vector2(62, -2)
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(badge)
	_home_badges[id] = bl
	b.pressed.connect(func(): open_app(id))
	return b


func _refresh_home() -> void:
	_build_home()


## Rebuild everything that depends on GameState (after new game / load).
func refresh_all() -> void:
	_close_current()
	var br := float(GameState.data.phone.get("brightness", 1.0))
	screen.modulate = Color(br, br, br, 1.0)
	_update_wallpaper()
	_build_home()
	_update_status()
	_status_icons.queue_redraw()
	_call_ui.visible = false
	off_layer.visible = false
	fx_layer.visible = false


# ================================================================= status
func _update_status() -> void:
	if _status_time == null:
		return
	_status_time.text = Clock.display_time()
	var batt := int(GameState.data.get("battery", 80))
	_status_batt.text = "%d%%" % batt
	_status_batt.add_theme_color_override("font_color", UI.c("danger") if batt <= 15 else UI.c("text"))
	var hc := home.find_child("HomeClock", true, false)
	if hc:
		hc.text = Clock.display_time()
		home.find_child("HomeDate", true, false).text = Clock.fmt_date_long(Clock.now())
	if _lock_screen:
		_lock_screen.update_clock()


func _on_phone_state() -> void:
	_update_status()
	_update_wallpaper()
	if (GameState.data.phone.get("eco_app", false)) != home.find_children("*", "AppIcon", true, false).any(func(i): return i.glyph == "eco"):
		_build_home()
	_status_icons.queue_redraw()


func _update_wallpaper() -> void:
	var wp: String = GameState.data.phone.get("wallpaper", "IMG_2207")
	if Content.has_item("photos", wp):
		wallpaper.set_photo(wp)


func _refresh_badges() -> void:
	var counts := {
		"messages": GameState.unread_total(),
		"phone": GameState.data.calls.filter(func(c): return c.dir == "missed" and not c.get("seen", false)).size() + GameState.data.voicemails.filter(func(vm): return not vm.get("heard", false)).size(),
		"email": GameState.data.emails.filter(func(e): return not GameState.data.emails_read.has(e.id)).size(),
		"gallery": GameState.data.photos.values().filter(func(p): return p.get("new", false)).size(),
	}
	for id in _home_badges:
		var l: Label = _home_badges[id]
		if not is_instance_valid(l):
			continue
		var n: int = counts.get(id, 0)
		l.text = str(n)
		l.get_parent().visible = n > 0


# ================================================================= navigation
func open_app(id: String, p := {}) -> void:
	if not APPS.has(id):
		return
	if locked and not p.get("forced", false):
		return
	if locked:
		unlock(true)
	if _call_ui.visible and not p.get("forced", false):
		return
	if current_app_id == id and current_app:
		current_app.reopen(p)
		return
	_close_current()
	var script: GDScript = load(APPS[id].script)
	var app: PhoneApp = script.new()
	app.app_id = id
	current_app = app
	current_app_id = id
	app_layer.add_child(app)
	app.setup(self, p)
	GameState.current_app = id
	GameState.data.opened[id] = int(GameState.data.opened.get(id, 0)) + 1
	GameState.data.chapter_opened[id] = int(GameState.data.chapter_opened.get(id, 0)) + 1
	home.visible = false
	Audio.play("app_open", -10.0)
	if not Settings.get_value("reduce_motion", false):
		app.modulate.a = 0.0
		app.scale = Vector2(0.97, 0.97)
		app.pivot_offset = UI.SCREEN / 2
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(app, "modulate:a", 1.0, 0.16)
		tw.tween_property(app, "scale", Vector2.ONE, 0.2)
	Events.app_opened.emit(id)
	Director.notify_player_action()
	Clock.notify_activity()
	if using_pad:
		get_tree().create_timer(0.25).timeout.connect(focus_first)


func _close_current() -> void:
	if current_app:
		var old_id := current_app_id
		current_app.queue_free()
		current_app = null
		current_app_id = ""
		GameState.current_app = ""
		Events.app_closed.emit(old_id)


func go_home() -> void:
	if locked or not interactive:
		return
	_close_current()
	home.visible = true
	GameState.current_app = "home"
	_refresh_badges()
	Clock.notify_activity()
	focus_first.call_deferred()


func back() -> void:
	if locked or not interactive:
		return
	if _call_ui.visible:
		return
	if current_app and current_app.on_back():
		return
	go_home()


func _on_open_request(id: String, p: Dictionary) -> void:
	if id == "home":
		go_home()
		return
	open_app(id, p)


func lock() -> void:
	if locked:
		return
	locked = true
	_close_current()
	home.visible = false
	GameState.current_app = "lock"
	_lock_screen.show_lock()
	Audio.play("lock", -6.0)


func unlock(silent := false) -> void:
	if not locked:
		return
	locked = false
	_lock_screen.hide_lock()
	home.visible = current_app == null
	if GameState.current_app == "lock" or GameState.current_app == "":
		GameState.current_app = "home"
	if not silent:
		Audio.play("unlock", -8.0)
	_refresh_badges()
	Events.unlocked.emit()
	Director.notify_player_action()
	if not Settings.get_value("seen_controls_hint", false) and GameState.in_game:
		Settings.set_value("seen_controls_hint", true)
		toast("Backspace: voltar · H: ecrã principal · Esc: pausa")


func show_locked_immediately() -> void:
	locked = true
	_close_current()
	home.visible = false
	GameState.current_app = "lock"
	_lock_screen.show_lock(true)


func _input(event: InputEvent) -> void:
	# remember whether the player is on a controller, so we only move focus for them
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if not using_pad:
			using_pad = true
			focus_first.call_deferred()
	elif event is InputEventMouseButton or event is InputEventKey:
		using_pad = false


## Give keyboard/controller focus to the first button on the current screen.
func focus_first() -> void:
	if not using_pad or locked:
		return
	var root: Node = current_app if current_app else home
	var b := _first_button(root)
	if b:
		b.grab_focus()


func _first_button(n: Node) -> Control:
	for ch in n.get_children():
		if ch is BaseButton and ch.is_visible_in_tree() and ch.focus_mode != Control.FOCUS_NONE and not ch.disabled:
			return ch
		var r := _first_button(ch)
		if r:
			return r
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.in_game or get_tree().paused:
		return
	if event.is_action_pressed("phone_back"):
		var fo := get_viewport().gui_get_focus_owner()
		if fo is LineEdit or fo is TextEdit:
			return
		back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("phone_home"):
		var fo2 := get_viewport().gui_get_focus_owner()
		if fo2 is LineEdit or fo2 is TextEdit:
			return
		go_home()
		get_viewport().set_input_as_handled()
	elif locked and (event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE)):
		_lock_screen.try_unlock()


# ================================================================= notifications
func _on_notification(n: Dictionary) -> void:
	_refresh_badges()
	if locked:
		_lock_screen.refresh_notifications()
		Audio.play(_notif_sound(n), -4.0)
		_wake_bump()
		return
	if current_app and not current_app.wants_banner(n):
		return
	_banner_queue.append(n)
	if not _banner_showing:
		_show_next_banner()


func _notif_sound(n: Dictionary) -> String:
	match n.get("app", ""):
		"messages": return "msg"
		"email": return "mail"
		_: return "notif"


func _wake_bump() -> void:
	vibrate(1)


func _show_next_banner() -> void:
	if _banner_queue.is_empty():
		_banner_showing = false
		return
	_banner_showing = true
	var n: Dictionary = _banner_queue.pop_front()
	Audio.play(_notif_sound(n), -4.0)
	var b := Banner.new()
	b.setup(n)
	b.position = Vector2(10, -110)
	b.size = Vector2(UI.SCREEN.x - 20, 76)
	b.pressed.connect(func():
		var app_id: String = n.get("app", "")
		if APPS.has(app_id):
			open_app(app_id, n))
	banner_layer.add_child(b)
	var tw := create_tween()
	tw.tween_property(b, "position:y", STATUS_H + 4.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.6)
	tw.tween_property(b, "position:y", -110.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		b.queue_free()
		_show_next_banner())


func toast(text: String) -> void:
	var tp: Control = screen.get_node("Toast")
	toast_label.text = text
	var tw := create_tween()
	tw.tween_property(tp, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.4)
	tw.tween_property(tp, "modulate:a", 0.0, 0.4)


# ================================================================= calls
func _on_call(call: Dictionary) -> void:
	_call_ui.show_incoming(call)
	if locked:
		_lock_screen.visible = true


func _on_call_started(call: Dictionary) -> void:
	_call_ui.show_connected(call)


# ================================================================= effects
func glitch(intensity: float, duration: float) -> void:
	var k := Settings.effects_scale()
	if k <= 0.0:
		return
	var mat: ShaderMaterial = fx_layer.material
	fx_layer.visible = true
	if _fx_tween:
		_fx_tween.kill()
	mat.set_shader_parameter("intensity", intensity * k)
	mat.set_shader_parameter("seed", randf() * 100.0)
	_fx_tween = create_tween()
	_fx_tween.tween_interval(duration * 0.6)
	_fx_tween.tween_method(func(v): mat.set_shader_parameter("intensity", v), intensity * k, 0.0, duration * 0.4)
	_fx_tween.tween_callback(func(): fx_layer.visible = false)


func vibrate(count := 1) -> void:
	if Settings.get_value("reduce_motion", false):
		return
	if _base_pos == Vector2.ZERO:
		_base_pos = position
	var tw := create_tween()
	for i in count * 6:
		tw.tween_property(self, "position", _base_pos + Vector2(randf_range(-3, 3), randf_range(-2, 2)), 0.03)
	tw.tween_property(self, "position", _base_pos, 0.03)


func screen_off(duration: float) -> void:
	off_layer.visible = true
	off_layer.modulate.a = 1.0
	UI.clear(off_layer)
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func(): off_layer.visible = false)


func reflection() -> void:
	## The screen goes dark and, in the black glass, a faint reflection: the
	## player's silhouette... and someone standing behind it.
	off_layer.visible = true
	UI.clear(off_layer)
	var pv := PhotoView.new()
	pv.set_anchors_preset(Control.PRESET_FULL_RECT)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	off_layer.add_child(pv)
	pv.set_scene({"preset": "black", "grain": 0.05, "vignette": 0.9, "layers": [
		{"t": "glow", "p": [0.5, 0.45], "r": 0.6, "c": "#ffffff06"},
		{"t": "ellipse", "p": [0.5, 0.5], "rx": 0.22, "ry": 0.17, "c": "#ffffff07"},
		{"t": "ellipse", "p": [0.5, 0.85], "rx": 0.45, "ry": 0.2, "c": "#ffffff05"},
		{"t": "figure", "p": [0.8, 0.95], "h": 0.62, "c": "#ffffff", "a": 0.035},
	]})
	pv.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(pv, "modulate:a", 1.0, 1.2)
	tw.tween_interval(1.4)
	tw.tween_callback(func():
		off_layer.visible = false
		UI.clear(off_layer))


func restart() -> void:
	## Forced reboot: black, logo, boot chime, then PIN lock.
	_close_current()
	off_layer.visible = true
	UI.clear(off_layer)
	var logo := UI.label("lumen", 30, "dim")
	logo.set_anchors_preset(Control.PRESET_CENTER)
	logo.position = UI.SCREEN / 2 - Vector2(45, 20)
	logo.modulate.a = 0.0
	off_layer.add_child(logo)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func(): Audio.play("boot"))
	tw.tween_property(logo, "modulate:a", 1.0, 0.8)
	tw.tween_interval(1.4)
	tw.tween_property(logo, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		off_layer.visible = false
		UI.clear(off_layer)
		locked = false
		lock())


# ================================================================= helpers
class AppIcon extends Control:
	var glyph := ""
	var bg := Color.GRAY

	func _draw() -> void:
		var sb := UI.box(bg, 16)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		draw_rect(Rect2(Vector2(0, 0), Vector2(size.x, size.y * 0.5)), Color(1, 1, 1, 0.04))
		Glyph.draw_glyph(self, glyph, Rect2(size * 0.24, size * 0.52), Color(1, 1, 1, 0.92))


class StatusIcons extends Control:
	func _draw() -> void:
		var col := Color(1, 1, 1, 0.9)
		var sig := int(GameState.data.phone.get("signal", 4))
		for i in 4:
			var h := 4.0 + i * 3.0
			draw_rect(Rect2(Vector2(i * 5.0, 15 - h), Vector2(3.5, h)), col if i < sig else Color(1, 1, 1, 0.25))
		Glyph.draw_glyph(self, "wifi", Rect2(Vector2(26, -1), Vector2(18, 18)), col, 1.6)


class Banner extends Button:
	var n: Dictionary

	func setup(p_n: Dictionary) -> void:
		n = p_n
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sb := UI.box(Color(0.13, 0.14, 0.16, 0.97), 18)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 12
		add_theme_stylebox_override("normal", sb)
		add_theme_stylebox_override("hover", sb)
		add_theme_stylebox_override("pressed", sb)
		var h := UI.hbox(12)
		h.position = Vector2(14, 12)
		h.size = Vector2(UI.SCREEN.x - 48, 52)
		add_child(h)
		var info: Dictionary = Phone.APPS.get(n.get("app", ""), {"glyph": "dot", "color": "#444444"})
		var ic := AppIcon.new()
		ic.glyph = info.glyph
		ic.bg = Color(info.color)
		ic.custom_minimum_size = Vector2(36, 36)
		h.add_child(ic)
		var v := UI.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := UI.label(str(n.get("title", "")), 14)
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(t)
		var b := UI.label(str(n.get("body", "")), 13, "dim")
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(b)
		h.add_child(v)
		UI._ignore_mouse(h)
