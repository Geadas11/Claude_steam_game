class_name Room
extends Control
## The dark room around the phone: a desk at night, a lamp, occasional car
## headlights sweeping across the ceiling. Purely atmospheric.

var mood := "night"
var _t := 0.0
var _sweep := -1.0
var _next_sweep := 25.0
var _flicker := 1.0
var _radial: GradientTexture2D


func _ready() -> void:
	_radial = GradientTexture2D.new()
	_radial.fill = GradientTexture2D.FILL_RADIAL
	_radial.fill_from = Vector2(0.5, 0.5)
	_radial.fill_to = Vector2(1.0, 0.5)
	_radial.width = 256
	_radial.height = 256
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gr.add_point(0.45, Color(1, 1, 1, 0.35))
	_radial.gradient = gr


func set_mood(m: String) -> void:
	mood = m
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_next_sweep -= delta
	if _next_sweep <= 0.0 and not Settings.get_value("reduce_motion", false):
		_sweep = 0.0
		_next_sweep = randf_range(40.0, 110.0)
		if GameState.in_game and randf() < 0.5:
			Audio.play("click_far", -18.0, 0.6)
	if _sweep >= 0.0:
		_sweep += delta / 4.5
		if _sweep > 1.0:
			_sweep = -1.0
	_flicker = 1.0
	if not Settings.get_value("reduce_effects", false) and fmod(_t, 13.0) < 0.12:
		_flicker = 0.85
	queue_redraw()


func _draw() -> void:
	var s := size
	var base := Color("050506")
	draw_rect(Rect2(Vector2.ZERO, s), base)
	# wall
	_vgrad(Rect2(0, 0, s.x, s.y * 0.42), Color("0b0c0e"), Color("08090a"))
	# desk surface
	var desk := Rect2(0, s.y * 0.42, s.x, s.y * 0.58)
	_vgrad(desk, Color("17120d"), Color("0a0806"))
	# wood grain
	for i in 26:
		var y := desk.position.y + 8.0 + i * (desk.size.y / 26.0)
		var a := 0.025 + 0.015 * sin(i * 1.7)
		draw_line(Vector2(0, y), Vector2(s.x, y + sin(i * 0.9) * 6.0), Color(0, 0, 0, a), 2.0)
	# lamp pool of light (warm) — top left
	var lamp_c := Vector2(s.x * 0.12, s.y * 0.62)
	var lr := s.y * 0.9
	var lamp_k := 0.16 if mood == "title" else 0.11
	draw_texture_rect(_radial, Rect2(lamp_c - Vector2(lr, lr * 0.75), Vector2(lr * 2, lr * 1.5)), false, Color(0.95, 0.66, 0.34, lamp_k * _flicker))
	# the phone's own light on the desk
	var pc := s / 2.0 + Vector2(0, s.y * 0.12)
	var pr := s.y * 0.55
	draw_texture_rect(_radial, Rect2(pc - Vector2(pr, pr * 0.6), Vector2(pr * 2, pr * 1.2)), false, Color(0.55, 0.68, 0.9, 0.06))
	# phone torch: a cold circle of light on the ceiling
	if GameState.in_game and GameState.data.phone.get("torch", false):
		var tr := s.y * 0.35
		draw_texture_rect(_radial, Rect2(Vector2(s.x / 2 - tr * 1.2, -tr * 0.6), Vector2(tr * 2.4, tr * 1.4)), false, Color(1, 0.97, 0.9, 0.12))
	# objects: a mug and a closed book, as silhouettes
	var mug := Vector2(s.x * 0.78, s.y * 0.7)
	draw_rect(Rect2(mug, Vector2(70, 84)), Color("0d0c0b"))
	draw_arc(mug + Vector2(76, 40), 20, -PI / 2, PI / 2, 12, Color("0d0c0b"), 9)
	draw_line(mug + Vector2(4, 4), mug + Vector2(66, 4), Color(1, 1, 1, 0.03), 2)
	var book := PackedVector2Array([Vector2(s.x * 0.62, s.y * 0.86), Vector2(s.x * 0.71, s.y * 0.83), Vector2(s.x * 0.73, s.y * 0.9), Vector2(s.x * 0.64, s.y * 0.93)])
	draw_colored_polygon(book, Color("0f0c0a"))
	# car headlights sweeping the ceiling
	if _sweep >= 0.0:
		var x := lerpf(-s.x * 0.3, s.x * 1.3, _sweep)
		var alpha := sin(_sweep * PI) * 0.05
		var poly := PackedVector2Array([Vector2(x - 140, 0), Vector2(x + 60, 0), Vector2(x + 260, s.y * 0.42), Vector2(x - 60, s.y * 0.42)])
		draw_colored_polygon(poly, Color(0.9, 0.85, 0.7, alpha))
	# vignette
	for i in 10:
		var w := 30.0 + i * 26.0
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.05), false, w)


func _vgrad(r: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([top, top, bottom, bottom]))
