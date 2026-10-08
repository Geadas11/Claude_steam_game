class_name WorldHud
extends Control
## What sits on top of the 3D view: a small dot in the middle, what E does,
## Daniel's thoughts, and (with the phone of the game) a hint that the phone
## buzzed in his pocket.

var dot: Control
var prompt: Label
var thought: Label
var phone_hint: Control
var phone_label: Label
var stamina_bar: ColorRect
var show_phone_hint := true
var _thought_tw: Tween
var _hint_tw: Tween
var _dot_on := false
var _laid_out := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# vignette: the edges of the eye in the dark
	var vig := TextureRect.new()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.05, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0))
	gr.set_color(1, Color(0, 0, 0, 0.55))
	gr.add_point(0.55, Color(0, 0, 0, 0.0))
	g.gradient = gr
	g.width = 256
	g.height = 256
	vig.texture = g
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	dot = _Dot.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)

	prompt = UI.label("", 17, "text")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	prompt.add_theme_constant_override("shadow_offset_x", 0)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	prompt.add_theme_constant_override("shadow_outline_size", 6)
	add_child(prompt)

	thought = UI.label("", 21, "text", true)
	thought.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thought.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	thought.add_theme_constant_override("shadow_outline_size", 8)
	thought.modulate.a = 0.0
	add_child(thought)

	stamina_bar = ColorRect.new()
	stamina_bar.color = Color(1, 1, 1, 0.35)
	stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_bar.modulate.a = 0.0
	add_child(stamina_bar)

	phone_hint = UI.panel(Color(0.05, 0.06, 0.07, 0.78), 12, 14, 9, 14, 9)
	phone_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(10)
	h.add_child(UI.glyph("phone", 18, "dim"))
	phone_label = UI.label("", 14, "dim")
	h.add_child(phone_label)
	phone_hint.add_child(h)
	add_child(phone_hint)
	resized.connect(_layout)
	_layout()
	set_phone_idle()


func _layout() -> void:
	_laid_out = size
	dot.position = size / 2.0
	prompt.size = Vector2(700, 30)
	prompt.position = Vector2(size.x / 2.0 - 350, size.y / 2.0 + 26)
	thought.size = Vector2(minf(size.x - 80, 980), 0)
	thought.position = Vector2((size.x - thought.size.x) / 2.0, size.y - 170)
	stamina_bar.size = Vector2(160, 3)
	stamina_bar.position = Vector2(size.x / 2.0 - 80, size.y - 60)
	phone_hint.position = Vector2(size.x - 330, size.y - 70)


func update_from(player: Player) -> void:
	if size != _laid_out:
		_layout()
	var p := player.target_prompt if player.look_enabled else ""
	if p != "":
		prompt.text = "%s   %s" % [Settings.key_label("interact", true), p]
	else:
		prompt.text = ""
	if (p != "") != _dot_on:
		_dot_on = p != ""
		dot.set_meta("on", _dot_on)
		dot.queue_redraw()
	dot.visible = player.look_enabled
	stamina_bar.size.x = 160 * player.stamina
	stamina_bar.position.x = size.x / 2.0 - 80 * player.stamina
	stamina_bar.modulate.a = move_toward(stamina_bar.modulate.a, 0.0 if player.stamina >= 0.999 else 1.0, 0.05)


func show_thought(text: String) -> void:
	thought.text = text
	thought.size.y = 0
	if _thought_tw:
		_thought_tw.kill()
	_thought_tw = create_tween()
	_thought_tw.tween_property(thought, "modulate:a", 1.0, 0.35)
	_thought_tw.tween_interval(2.4 + text.length() * 0.045)
	_thought_tw.tween_property(thought, "modulate:a", 0.0, 0.8)


func set_phone_idle() -> void:
	phone_label.text = "%s   Telemóvel" % Settings.key_label("phone_toggle", true)
	phone_label.add_theme_color_override("font_color", UI.c("dim"))
	phone_hint.modulate.a = 0.55
	phone_hint.visible = show_phone_hint


## The phone buzzed while it was in the pocket.
func phone_ping(text: String, ringing := false) -> void:
	if not show_phone_hint:
		return
	phone_label.text = "%s   %s" % [Settings.key_label("phone_toggle", true), text]
	phone_label.add_theme_color_override("font_color", UI.c("text"))
	phone_hint.visible = true
	if _hint_tw:
		_hint_tw.kill()
	_hint_tw = create_tween()
	var loops := 6 if ringing else 2
	for i in loops:
		_hint_tw.tween_property(phone_hint, "modulate:a", 1.0, 0.25)
		_hint_tw.tween_property(phone_hint, "modulate:a", 0.7, 0.35)
	_hint_tw.tween_interval(3.0)
	_hint_tw.tween_callback(set_phone_idle)


class _Dot extends Control:
	func _draw() -> void:
		var on: bool = get_meta("on", false)
		if on:
			draw_arc(Vector2.ZERO, 7.0, 0, TAU, 24, Color(1, 1, 1, 0.75), 1.5, true)
			draw_circle(Vector2.ZERO, 1.8, Color(1, 1, 1, 0.9))
		else:
			draw_circle(Vector2.ZERO, 1.6, Color(1, 1, 1, 0.45))
