extends PhoneApp
## Camera: a live viewfinder of the room. Story events can be "armed" so that
## the next time the camera opens something is there — briefly.

const BACK_SCENE := "CAM_VIEW"
const FRONT_SCENE := "CAM_FRONT"

var _pv: PhotoView
var _front := false
var _variant := "base"
var _event := ""
var _event_timer: SceneTreeTimer
var _flash: ColorRect
var _hint: Label


func build() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_pv = PhotoView.new()
	_pv.live = true
	_pv.shake = 1.0
	_pv.position = Vector2(0, 70)
	_pv.size = Vector2(UI.SCREEN.x, UI.SCREEN.x / 0.75)
	_pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pv)
	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	var top := UI.hbox(10)
	top.position = Vector2(16, Phone.STATUS_H + 4)
	top.size = Vector2(UI.SCREEN.x - 32, 36)
	var mode := UI.label("FOTO", 13, "accent")
	top.add_child(mode)
	top.add_child(UI.expand())
	_hint = UI.label("", 12, "faint")
	top.add_child(_hint)
	add_child(top)
	var bottom := UI.hbox(0)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 70)
	bottom.position = Vector2(0, UI.SCREEN.y - Phone.NAV_H - 120)
	bottom.size = Vector2(UI.SCREEN.x, 100)
	var gal := UI.icon_button("gallery", func(): phone.open_app("gallery"), 50, "text")
	bottom.add_child(gal)
	var shutter := UI.icon_button("shutter", _take, 78, "text")
	shutter.tooltip_text = "Tirar fotografia (Espaço)"
	bottom.add_child(shutter)
	var flip := UI.icon_button("flip", _flip, 50, "text")
	flip.tooltip_text = "Trocar câmara"
	bottom.add_child(flip)
	add_child(bottom)
	_event = str(GameState.data.camera.get("armed", ""))
	_update_view()
	if _event != "":
		_start_event()


func _scene_id() -> String:
	return FRONT_SCENE if _front else BACK_SCENE


func _update_view() -> void:
	var d := Content.get_item("photos", _scene_id())
	_pv.set_scene(d.get("scene", {}), _variant)
	_pv.live = true
	_pv.set_process(true)


func _flip() -> void:
	_front = not _front
	_variant = "base"
	Audio.play("tap", -8.0)
	_update_view()
	if _event != "" and _event_matches_side():
		_start_event()


func _event_matches_side() -> bool:
	var ev := _event_def()
	return bool(ev.get("front", false)) == _front


func _event_def() -> Dictionary:
	var d := Content.get_item("photos", _scene_id())
	return d.get("events", {}).get(_event, {})


func _start_event() -> void:
	## Event definition lives on the camera scene's "events": {delay, variant, hold, sound, flag}
	var ev := _event_def()
	if ev.is_empty():
		return
	var delay: float = float(ev.get("delay", 2.0))
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or _event == "":
		return
	_variant = str(ev.get("variant", "base"))
	_update_view()
	if ev.get("sound", "") != "":
		Audio.play(ev.sound, -6.0)
	GameState.set_var("cam_" + _event + "_seen", true)
	GameState.data.camera.armed = ""
	var ev_name := _event
	_event = ""
	Director.notify_player_action()
	var hold: float = float(ev.get("hold", 0.0))
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
		if not is_inside_tree():
			return
		if ev.get("glitch_out", true):
			phone.glitch(0.5, 0.35)
		_variant = "base"
		_update_view()
	GameState.set_var("cam_" + ev_name + "_done", true)


func _take() -> void:
	Audio.play("shutter")
	var tw := create_tween()
	_flash.modulate.a = 0.8
	tw.tween_property(_flash, "modulate:a", 0.0, 0.25)
	GameState.data.camera.shots = int(GameState.data.camera.get("shots", 0)) + 1
	var n := 7000 + int(GameState.data.camera.shots)
	var pid := "IMG_%d" % n
	GameState.data.photos[pid] = {"variant": "base", "added": Clock.now(), "album": "Câmara", "new": true,
		"dyn": {"scene_id": _scene_id(), "variant": _variant, "file": pid + ".jpg", "date": _now_str(), "place": _place()}}
	GameState.data.photo_order.push_front(pid)
	if _variant != "base":
		GameState.set_var("photographed_" + _variant, true)
	Events.content_changed.emit("photos")
	Director.notify_player_action()


func _now_str() -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(Clock.now()))
	return "%04d-%02d-%02d %02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute]


func _place() -> String:
	var loc = Content.all("map").get("locations", {}).get(GameState.data.location, {})
	return str(loc.get("address", "Salgueira"))


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_take()
		get_viewport().set_input_as_handled()
