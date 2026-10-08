class_name PhoneApp
extends Control
## Base class for every app. Apps build their UI in code inside `build()`.

var phone: Phone
var app_id := ""
var params: Dictionary = {}
var _content: Control
var _slide_tw: Tween


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(p_phone: Phone, p_params: Dictionary) -> void:
	phone = p_phone
	params = p_params
	var bg := ColorRect.new()
	bg.color = UI.c("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	build()


## Override: construct UI.
func build() -> void:
	pass


## Override: return true if the app handled "back" internally.
func on_back() -> bool:
	return false


## Override: the app was asked to open again with new params while visible.
func reopen(p_params: Dictionary) -> void:
	params = p_params


## Override: suppress the banner for notifications the app is already showing.
func wants_banner(_n: Dictionary) -> bool:
	return true


## Content area below the status bar.
func content_root() -> VBoxContainer:
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = Phone.STATUS_H
	v.offset_bottom = -Phone.NAV_H
	add_child(v)
	_content = v
	return v


## Screen change inside the app: the new screen slides in from the right when
## going deeper (list -> item) and from the left when going back.
func slide(forward := true) -> void:
	if _content == null or not UI.motion_ok():
		return
	if _slide_tw:
		_slide_tw.kill()
	_content.position.x = 28.0 if forward else -28.0
	_content.modulate.a = 0.0
	_slide_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_slide_tw.tween_property(_content, "position:x", 0.0, UI.T_SCREEN)
	_slide_tw.tween_property(_content, "modulate:a", 1.0, UI.T_SCREEN * 0.8)


func close_app() -> void:
	phone.go_home()
