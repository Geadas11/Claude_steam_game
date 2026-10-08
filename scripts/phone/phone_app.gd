class_name PhoneApp
extends Control
## Base class for every app. Apps build their UI in code inside `build()`.

var phone: Phone
var app_id := ""
var params: Dictionary = {}


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
	return v


func close_app() -> void:
	phone.go_home()
