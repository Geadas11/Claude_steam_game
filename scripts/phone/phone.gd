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
var input_active := true      # false while the phone is in Daniel's pocket (3D house)

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
var _home_has_eco := false
var _launch_from := Rect2()   # the icon an app was opened from (its zoom grows out of it)
var _launched := {}           # app id -> icon rect it was opened from (it shrinks back into it)


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
	Events.photo_changed.connect(func(pid): if pid == GameState.data.phone.get("wallpaper", ""): _update_wallpaper())
	_update_status()


func _on_settings_changed() -> void:
	if not (Settings.last_changed_key in ["text_scale", "high_contrast"]):
		return
	theme = UI.build_theme()
	_refresh_home()
	# rebuild the open app so text size / contrast apply immediately
	if current_app and not locked:
		var id := current_app_id
		var p: Dictionary = current_app.params.duplicate()
		p["forced"] = true
		_close_current()
		open_app(id, p)


# ================================================================= building
func _build_frame() -> void:
	var frame := Frame.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)


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
	# legibility veil: darker where the clock, notifications and icons sit,
	# almost clear in the middle so the wallpaper keeps its light
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 0.62, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.22), Color(0, 0, 0, 0.08), Color(0, 0, 0, 0.2), Color(0, 0, 0, 0.55)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 256
	var dim := TextureRect.new()
	dim.texture = gt
	dim.stretch_mode = TextureRect.STRETCH_SCALE
	dim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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
	var tp := UI.glass(22, 18, 11, 18, 11, "thick")
	tp.name = "Toast"
	tp.add_child(toast_label)
	# anchored to the bottom centre of the screen, growing upwards
	tp.anchor_left = 0.5
	tp.anchor_right = 0.5
	tp.anchor_top = 1.0
	tp.anchor_bottom = 1.0
	tp.offset_left = -150
	tp.offset_right = 150
	tp.offset_top = -168
	tp.offset_bottom = -154
	tp.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tp.custom_minimum_size = Vector2(300, 0)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tp.modulate.a = 0.0
	tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# clue toasts are clickable: they open the clue board
	tp.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and toast_label.text.begins_with("Nova pista"):
			tp.accept_event()
			open_app("notes", {"param": "clues"}))
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
	var corners := ScreenCorners.new()
	corners.set_anchors_preset(Control.PRESET_FULL_RECT)
	corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(corners)
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
	h.position = Vector2(26, 5)
	h.size = Vector2(UI.SCREEN.x - 50, 22)
	status_bar.add_child(h)
	_status_time = UI.label("00:00", 15)
	_status_time.add_theme_font_override("font", UI.font("semibold"))
	h.add_child(_status_time)
	h.add_child(UI.expand())
	_status_batt = UI.label("82", 10)
	_status_batt.visible = false
	h.add_child(_status_batt)
	_status_icons = StatusIcons.new()
	_status_icons.custom_minimum_size = Vector2(78, 20)
	h.add_child(_status_icons)
	# the status bar opens the notification shade
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.size = Vector2(UI.SCREEN.x, STATUS_H)
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = "Notificações"
	hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit.pressed.connect(func(): open_shade())
	status_bar.add_child(hit)
	status_bar.mouse_filter = Control.MOUSE_FILTER_PASS


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
	var pill := Panel.new()
	pill.add_theme_stylebox_override("panel", UI.box(Color(1, 1, 1, 0.7), 3))
	pill.size = Vector2(124, 5)
	pill.position = Vector2(-2, 12)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_b.add_child(pill)
	home_b.pressed.connect(go_home)
	UI.press_fx(home_b, 0.92)
	nav_bar.add_child(home_b)


func _build_home() -> void:
	UI.clear(home)
	_home_badges.clear()
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = STATUS_H + 14
	v.offset_bottom = -NAV_H - 6
	home.add_child(v)
	# a glass widget: the day and the time
	var w := UI.glass(26, 20, 16, 20, 16)
	var wh := UI.hbox(10)
	w.add_child(wh)
	var dv := UI.vbox(0)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	var day := UI.label("", 12, "accent")
	day.name = "HomeDay"
	day.add_theme_font_override("font", UI.font("semibold"))
	dv.add_child(day)
	var d := UI.label("", 17)
	d.name = "HomeDate"
	d.add_theme_font_override("font", UI.font("semibold"))
	dv.add_child(d)
	var d2 := UI.label("", 12, "dim")
	d2.name = "HomeWhere"
	dv.add_child(d2)
	wh.add_child(dv)
	var t := UI.label("", 50)
	t.name = "HomeClock"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wh.add_child(t)
	var wm := UI.margin(16, 0, 16, 0)
	wm.add_child(w)
	v.add_child(wm)
	v.add_child(UI.spacer(22))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 14)
	var gm := UI.margin(12, 0, 12, 0)
	gm.add_child(grid)
	v.add_child(gm)
	var apps: Array = GRID.duplicate()
	_home_has_eco = bool(GameState.data.phone.get("eco_app", false))
	if _home_has_eco:
		apps.append("eco")
	for id in apps:
		grid.add_child(_app_icon(id, true))
	v.add_child(UI.expand())
	# page dots
	var dots := UI.hbox(7)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 2:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(7, 7)
		dot.add_theme_stylebox_override("panel", UI.box(Color(1, 1, 1, 0.9 if i == 0 else 0.3), 4))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
	v.add_child(dots)
	v.add_child(UI.spacer(12))
	var dock := UI.glass(34, 12, 12, 12, 12)
	var dh := UI.hbox(0)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(dh)
	for id in DOCK:
		dh.add_child(_app_icon(id, false))
	var dm := UI.margin(10, 0, 10, 0)
	dm.add_child(dock)
	v.add_child(dm)
	_update_status()
	_refresh_badges()


func _app_icon(id: String, with_label: bool) -> Control:
	var info: Dictionary = APPS[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(98 if with_label else 92, 92 if with_label else 66)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = info.name
	for st in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", UI.box(Color(1, 1, 1, 0.08), 18))
	var icon := AppIcon.new()
	icon.name = "Icon"
	icon.glyph = info.glyph
	icon.bg = Color(info.color)
	icon.size = Vector2(62, 62)
	icon.position = Vector2((b.custom_minimum_size.x - 62) / 2, 2)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	if with_label:
		var l := UI.label(info.name, 12)
		l.add_theme_font_override("font", UI.font("medium"))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 1)
		l.position = Vector2(0, 68)
		l.size = Vector2(b.custom_minimum_size.x, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(l)
	var badge := UI.panel(Color("ff4545"), 11, 6, 1, 6, 1)
	var bl := UI.label("", 12)
	bl.add_theme_font_override("font", UI.font("semibold"))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.custom_minimum_size = Vector2(10, 0)
	badge.add_child(bl)
	badge.position = icon.position + Vector2(48, -6)
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(badge)
	_home_badges[id] = bl
	b.pressed.connect(func():
		_launch_from = icon.get_global_rect()
		open_app(id))
	UI.press_fx(b, 0.9)
	return b


func _refresh_home() -> void:
	_build_home()


## Rebuild everything that depends on GameState (after new game / load).
func refresh_all() -> void:
	_close_current()
	home.scale = Vector2.ONE
	home.modulate.a = 1.0
	var br := float(GameState.data.phone.get("brightness", 1.0))
	screen.modulate = Color(br, br, br, 1.0)
	_wallpaper_key = ""
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
	if _status_icons:
		_status_icons.queue_redraw()
	var hc := home.find_child("HomeClock", true, false)
	if hc:
		hc.text = Clock.display_time()
		var long := Clock.fmt_date_long(Clock.now())
		var parts := long.split(",", false, 1)
		home.find_child("HomeDay", true, false).text = parts[0].strip_edges().to_upper()
		home.find_child("HomeDate", true, false).text = parts[1].strip_edges() if parts.size() > 1 else long
		home.find_child("HomeWhere", true, false).text = "Bateria %d%%" % batt
	if _lock_screen:
		_lock_screen.update_clock()


func _on_phone_state() -> void:
	_update_status()
	_update_wallpaper()
	if bool(GameState.data.phone.get("eco_app", false)) != _home_has_eco:
		_build_home()
	_status_icons.queue_redraw()


var _wallpaper_key := ""


func _update_wallpaper() -> void:
	var wp: String = GameState.data.phone.get("wallpaper", "IMG_2207")
	var key := wp + ":" + GameState.photo_variant(wp)
	if key == _wallpaper_key:
		return
	_wallpaper_key = key
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
	# set before setup(): an app may refine it (e.g. "messages:<thread>")
	GameState.current_app = id
	app.setup(self, p)
	GameState.data.opened[id] = int(GameState.data.opened.get(id, 0)) + 1
	GameState.data.chapter_opened[id] = int(GameState.data.chapter_opened.get(id, 0)) + 1
	Audio.play("app_open", -10.0)
	var from := _icon_point()
	_launched[id] = _launch_from
	_launch_from = Rect2()
	if UI.motion_ok() and home.visible and from != Vector2.INF:
		# the app grows out of its icon while the home screen sinks back
		app.pivot_offset = from
		app.scale = Vector2.ONE * 0.16
		app.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(app, "scale", Vector2.ONE, UI.T_OPEN)
		tw.tween_property(app, "modulate:a", 1.0, UI.T_OPEN * 0.4)
		_sink_home(true)
	elif UI.motion_ok():
		home.visible = false
		app.modulate.a = 0.0
		app.scale = Vector2(0.96, 0.96)
		app.pivot_offset = UI.SCREEN / 2
		var tw2 := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw2.tween_property(app, "modulate:a", 1.0, UI.T_SCREEN * 0.8)
		tw2.tween_property(app, "scale", Vector2.ONE, UI.T_SCREEN)
	else:
		home.visible = false
	Events.app_opened.emit(id)
	Director.notify_player_action()
	Clock.notify_activity()
	if using_pad:
		get_tree().create_timer(0.25).timeout.connect(focus_first)


func _close_current(animate := false) -> void:
	if current_app:
		var old_id := current_app_id
		var old := current_app
		if animate and UI.motion_ok():
			# the app shrinks back into its icon (or just fades, if it wasn't
			# opened from one), under a blocker so it can't be tapped mid-way
			var blocker := Control.new()
			blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
			blocker.mouse_filter = Control.MOUSE_FILTER_STOP
			old.add_child(blocker)
			var back_to := _icon_of(old_id)
			var tw := old.create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			if back_to != Vector2.INF:
				old.pivot_offset = back_to
				tw.tween_property(old, "scale", Vector2.ONE * 0.16, UI.T_OPEN * 0.85)
				tw.tween_property(old, "modulate:a", 0.0, UI.T_OPEN * 0.6).set_delay(UI.T_OPEN * 0.15)
			else:
				old.pivot_offset = UI.SCREEN / 2
				tw.tween_property(old, "modulate:a", 0.0, UI.T_SCREEN * 0.75)
				tw.tween_property(old, "scale", Vector2(0.97, 0.97), UI.T_SCREEN * 0.75)
			tw.chain().tween_callback(old.queue_free)
		else:
			old.queue_free()
		current_app = null
		current_app_id = ""
		GameState.current_app = ""
		Events.app_closed.emit(old_id)


func go_home() -> void:
	if locked or not interactive:
		return
	var from_app := current_app != null
	_close_current(true)
	home.visible = true
	if from_app and UI.motion_ok():
		_sink_home(false)
	else:
		if _home_tw:
			_home_tw.kill()
		home.scale = Vector2.ONE
		home.modulate.a = 1.0
	GameState.current_app = "home"
	_refresh_badges()
	Clock.notify_activity()
	focus_first.call_deferred()


## Where an app's icon sits on the screen (its centre, in screen
## coordinates), or INF when there is no icon to grow from / shrink into.
func _icon_point() -> Vector2:
	if not _launch_from.has_area():
		return Vector2.INF
	var k := screen.get_global_transform().get_scale()
	return (_launch_from.get_center() - screen.global_position) / k


func _icon_of(id: String) -> Vector2:
	var r: Rect2 = _launched.get(id, Rect2())
	if not r.has_area():
		return Vector2.INF
	var k := screen.get_global_transform().get_scale()
	return (r.get_center() - screen.global_position) / k


## The home screen sinks back and dims while an app is open over it, and
## rises again when you come back.
var _home_tw: Tween


func _sink_home(sink: bool) -> void:
	if _home_tw:
		_home_tw.kill()
	home.pivot_offset = UI.SCREEN / 2
	home.visible = true
	_home_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if sink:
		_home_tw.tween_property(home, "scale", Vector2.ONE * 0.92, UI.T_OPEN)
		_home_tw.tween_property(home, "modulate:a", 0.0, UI.T_OPEN * 0.7)
		_home_tw.chain().tween_callback(func(): if current_app: home.visible = false)
	else:
		home.scale = Vector2.ONE * 0.92
		home.modulate.a = 0.0
		_home_tw.tween_property(home, "scale", Vector2.ONE, UI.T_OPEN)
		_home_tw.tween_property(home, "modulate:a", 1.0, UI.T_OPEN * 0.6)


func back() -> void:
	if _shade and is_instance_valid(_shade):
		close_shade()
		return
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
	close_shade()
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
	if home.visible and UI.motion_ok() and not silent:
		home.pivot_offset = UI.SCREEN / 2
		home.scale = Vector2.ONE * 1.08
		home.modulate.a = 0.0
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(home, "scale", Vector2.ONE, 0.5).set_delay(0.06)
		tw.tween_property(home, "modulate:a", 1.0, 0.3).set_delay(0.06)
	else:
		home.scale = Vector2.ONE
		home.modulate.a = 1.0
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


var _untouched := 0.0
var _dimmed := false


func _process(delta: float) -> void:
	# auto-lock like a real phone: dim after 100 s untouched, lock at 130 s
	if not GameState.in_game or locked or get_tree().paused or (_call_ui and _call_ui.visible):
		_untouched = 0.0
		_set_dim(false)
		return
	if not GameState.data.phone.get("auto_lock", true) or current_app_id == "camera":
		return
	_untouched += delta
	if _untouched > 100.0:
		_set_dim(true)
	if _untouched > 130.0:
		_untouched = 0.0
		_set_dim(false)
		lock()


func _set_dim(on: bool) -> void:
	if on == _dimmed:
		return
	_dimmed = on
	var br := float(GameState.data.phone.get("brightness", 1.0))
	var target := br * (0.35 if on else 1.0)
	create_tween().tween_property(screen, "modulate", Color(target, target, target, 1.0), 0.6)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton or (event is InputEventMouseMotion and event.relative.length() > 3.0):
		_untouched = 0.0
		_set_dim(false)
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
	if not GameState.in_game or get_tree().paused or not input_active:
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
	if UI.motion_ok():
		# drops in with a little overshoot, like something with weight
		b.pivot_offset = Vector2(b.size.x / 2, 0)
		b.scale = Vector2(0.94, 0.94)
		tw.set_parallel(true)
		tw.tween_property(b, "position:y", STATUS_H + 4.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.set_parallel(false)
	else:
		tw.tween_property(b, "position:y", STATUS_H + 4.0, 0.01)
	tw.tween_interval(3.6)
	tw.tween_property(b, "position:y", -110.0, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		b.queue_free()
		_show_next_banner())


var _toast_tw: Tween
var _toast_queue: Array = []


## Shows a short message at the bottom of the screen. Toasts never cut each
## other off: a new one waits for the current one (repeats are dropped).
func toast(text: String) -> void:
	if _toast_tw and _toast_tw.is_running():
		if text != toast_label.text and not _toast_queue.has(text) and _toast_queue.size() < 4:
			_toast_queue.append(text)
		return
	var tp: Control = screen.get_node("Toast")
	toast_label.text = text
	# clickable only where it can't swallow a tap meant for a reply button or a call
	var clickable := text.begins_with("Nova pista") and not GameState.current_app.begins_with("messages") and not _call_ui.visible
	tp.mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE
	tp.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_toast_tw = create_tween()
	_toast_tw.tween_property(tp, "modulate:a", 1.0, 0.2)
	_toast_tw.tween_interval(2.4 + text.length() * 0.02)
	_toast_tw.tween_property(tp, "modulate:a", 0.0, 0.4)
	_toast_tw.finished.connect(func():
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not _toast_queue.is_empty():
			toast(_toast_queue.pop_front()))


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
## Signal, Wi-Fi and the battery (its level drawn inside it).
class StatusIcons extends Control:
	func _draw() -> void:
		var col := Color(1, 1, 1, 0.95)
		var sig := int(GameState.data.phone.get("signal", 4))
		for i in 4:
			var h := 4.0 + i * 2.6
			var sb := UI.box(col if i < sig else Color(1, 1, 1, 0.28), 1)
			draw_style_box(sb, Rect2(Vector2(i * 4.6, 14 - h), Vector2(3.2, h)))
		Glyph.draw_glyph(self, "wifi", Rect2(Vector2(21, -1), Vector2(17, 17)), col, 1.9)
		var batt := int(GameState.data.get("battery", 80))
		var low := batt <= 15
		var r := Rect2(Vector2(44, 2.5), Vector2(27, 13))
		draw_style_box(UI.box(Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.45), 1), r)
		var fill := Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4) * clampf(batt / 100.0, 0.04, 1.0), r.size.y - 4))
		draw_style_box(UI.box(UI.c("danger") if low else col, 2), fill)
		draw_style_box(UI.box(Color(1, 1, 1, 0.45), 1), Rect2(r.end.x + 1, r.position.y + 4, 2, 5))


## The phone itself: a thin titanium band, a black glass front, the side
## buttons, and a soft shadow underneath.
class Frame extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var shadow := UI.box(Color(0, 0, 0, 0), 58)
		shadow.shadow_color = Color(0, 0, 0, 0.55)
		shadow.shadow_size = 46
		shadow.shadow_offset = Vector2(0, 16)
		draw_style_box(shadow, r.grow(-6))
		# side buttons
		for y in [150.0, 212.0]:
			draw_style_box(UI.box(Color("55575c"), 2), Rect2(-3, y, 5, 50))
		draw_style_box(UI.box(Color("55575c"), 2), Rect2(size.x - 2, 186, 5, 76))
		# the band: brushed metal, lighter at the top edge
		var band := UI.box(Color("3c3d42"), 58, Color("75777d"), 1)
		draw_style_box(band, r)
		draw_style_box(UI.box(Color("1d1e21"), 55), r.grow(-2.5))
		draw_style_box(UI.box(Color("030304"), 54), r.grow(-4))


## Round screen corners and the front camera, drawn over whatever is on the
## screen (the screen is a plain rectangle underneath).
class ScreenCorners extends Control:
	const R := 42.0

	func _draw() -> void:
		var black := Color("030304")
		for k in 4:
			var corner := Vector2(0 if k % 2 == 0 else size.x, 0 if k < 2 else size.y)
			var inward := Vector2(1 if k % 2 == 0 else -1, 1 if k < 2 else -1)
			var centre := corner + inward * R
			var pts := PackedVector2Array([corner])
			for i in 13:
				var a := PI / 2.0 * i / 12.0
				pts.append(centre - Vector2(cos(a) * inward.x, sin(a) * inward.y) * R)
			draw_colored_polygon(pts, black)
		# the front camera, a punch hole between the clock and the icons
		var cam := Vector2(size.x / 2, 17)
		draw_circle(cam, 8.5, Color("050506"))
		draw_circle(cam, 4.2, Color("12151c"))
		draw_circle(cam + Vector2(-1.4, -1.4), 1.3, Color(0.5, 0.6, 0.9, 0.35))


class Banner extends Button:
	var n: Dictionary

	func setup(p_n: Dictionary) -> void:
		n = p_n
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sb := UI.glass_box(24, 0, 0, 0, 0, "thick")
		for st in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(st, sb)
		if UI.glass_ok():
			material = UI.glass_material("thick")
		var h := UI.hbox(12)
		h.position = Vector2(14, 13)
		h.size = Vector2(UI.SCREEN.x - 48, 50)
		add_child(h)
		var info: Dictionary = Phone.APPS.get(n.get("app", ""), {"glyph": "dot", "color": "#444444"})
		var ic := AppIcon.new()
		ic.glyph = info.glyph
		ic.bg = Color(info.color)
		ic.custom_minimum_size = Vector2(40, 40)
		h.add_child(ic)
		var v := UI.vbox(1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var top := UI.hbox(6)
		var t := UI.label(str(n.get("title", "")), 15)
		t.add_theme_font_override("font", UI.font("semibold"))
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		top.add_child(UI.label("agora", 12, "faint"))
		v.add_child(top)
		var b := UI.label(str(n.get("body", "")), 14, "dim")
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(b)
		h.add_child(v)
		UI._ignore_mouse(h)



# ================================================================= notification shade
var _shade: Control


func open_shade() -> void:
	if locked or not interactive or (_call_ui and _call_ui.visible):
		return
	if _shade and is_instance_valid(_shade):
		close_shade()
		return
	_shade = Control.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: close_shade())
	_shade.add_child(dim)
	var p := UI.glass(30, 16, 16, 16, 18, "thick")
	p.position = Vector2(8, STATUS_H + 2)
	p.size = Vector2(UI.SCREEN.x - 16, 0)
	p.custom_minimum_size = Vector2(UI.SCREEN.x - 16, 0)
	_shade.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	# quick toggles
	var qt := UI.hbox(8)
	qt.alignment = BoxContainer.ALIGNMENT_CENTER
	qt.add_child(_quick("wifi", "Wi-Fi", true, func(_on): toast("O Wi-Fi é gerido pela organização.")))
	qt.add_child(_quick("speaker", "Não incomodar", GameState.data.phone.get("dnd", false), func(on):
		GameState.data.phone.dnd = on
		Events.phone_state_changed.emit()
		Director.notify_player_action()))
	qt.add_child(_quick("torch", "Lanterna", GameState.data.phone.get("torch", false), func(on):
		GameState.data.phone.torch = on
		Events.phone_state_changed.emit()))
	qt.add_child(_quick("locate", "Localização", true, func(_on): toast("A localização é gerida pela organização.")))
	v.add_child(qt)
	var top := UI.hbox(8)
	var t := UI.label("Notificações", 17)
	t.add_theme_font_override("font", UI.font("semibold"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	if not GameState.data.shade.is_empty():
		top.add_child(UI.button("Limpar", func():
			GameState.data.shade.clear()
			close_shade(), 13, "accent"))
	v.add_child(top)
	if GameState.data.shade.is_empty():
		v.add_child(UI.label("Sem notificações.", 13, "faint"))
	var shown := 0
	for n in GameState.data.shade:
		if shown >= 7:
			break
		shown += 1
		v.add_child(_shade_card(n))
	screen.add_child(_shade)
	screen.move_child(status_bar, -1)
	if not Settings.get_value("reduce_motion", false):
		p.position.y = -320
		dim.modulate.a = 0.0
		var stw := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		stw.tween_property(p, "position:y", STATUS_H + 2.0, 0.45)
		stw.tween_property(dim, "modulate:a", 1.0, 0.25)
	GameState.set_var("opened_shade", true)


func close_shade() -> void:
	if _shade and is_instance_valid(_shade):
		_shade.queue_free()
	_shade = null


func _quick(glyph: String, label_text: String, on: bool, cb: Callable) -> Control:
	var vb := UI.vbox(4)
	var b := UI.icon_button(glyph, func(): pass, 58, "bg" if on else "text")
	b.toggle_mode = true
	b.button_pressed = on
	var off_box := UI.box(Color(1, 1, 1, 0.1), 29)
	b.add_theme_stylebox_override("normal", off_box)
	b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.15), 29))
	b.add_theme_stylebox_override("pressed", UI.box(UI.c("accent"), 29))
	b.add_theme_stylebox_override("hover_pressed", UI.box(UI.c("accent").lightened(0.1), 29))
	b.toggled.connect(func(state):
		var g: Glyph = b.get_child(0)
		g.color = UI.c("bg") if state else UI.c("text")
		cb.call(state))
	vb.add_child(b)
	var l := UI.label(label_text, 10, "dim")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(84, 0)
	vb.add_child(l)
	return vb


func _shade_card(n: Dictionary) -> Control:
	var info: Dictionary = APPS.get(n.get("app", ""), {"glyph": "dot", "color": "#444"})
	var h := UI.hbox(10)
	var ic := AppIcon.new()
	ic.glyph = info.glyph
	ic.bg = Color(info.color)
	ic.custom_minimum_size = Vector2(36, 36)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UI.label(str(n.get("title", "")), 14)
	t.add_theme_font_override("font", UI.font("semibold"))
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(t)
	var b := UI.label(str(n.get("body", "")), 13, "dim")
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(b)
	h.add_child(tv)
	h.add_child(UI.label(Clock.fmt_relative(float(n.get("t", 0))), 11, "faint"))
	var r := UI.row(h, func():
		close_shade()
		if APPS.has(n.get("app", "")):
			open_app(n.app, n), 62)
	r.add_theme_stylebox_override("normal", UI.box(Color(1, 1, 1, 0.06), 18))
	r.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.1), 18))
	r.add_theme_stylebox_override("pressed", UI.box(Color(1, 1, 1, 0.14), 18))
	return r
