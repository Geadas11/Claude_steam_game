@tool
class_name Glyph
extends Control
## Vector pictograms drawn with canvas primitives (no font/icon assets).

@export var glyph := "dot":
	set(v):
		glyph = v
		queue_redraw()
@export var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()
@export var line_width := 0.0


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2.0
	draw_glyph(self, glyph, Rect2(o + Vector2(s, s) * 0.18, Vector2(s, s) * 0.64), color, line_width)


static func draw_glyph(ci: CanvasItem, name: String, r: Rect2, col: Color, lw := 0.0) -> void:
	var w := r.size.x
	var h := r.size.y
	var p := r.position
	var c := r.get_center()
	var t := lw if lw > 0.0 else maxf(1.5, w * 0.085)
	match name:
		"messages":
			_rrect(ci, Rect2(p + Vector2(0, h * 0.08), Vector2(w, h * 0.68)), w * 0.2, col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.2, h * 0.7), p + Vector2(w * 0.18, h * 0.98), p + Vector2(w * 0.48, h * 0.7)]), col)
		"phone", "call":
			# classic handset: arc body + two rounded ends
			var hc := p + Vector2(w * 0.78, h * 0.22)
			var pts := PackedVector2Array()
			for i in 15:
				var a := deg_to_rad(95.0 + i * 5.7)
				pts.append(hc + Vector2(cos(a), sin(a)) * w * 0.56)
			ci.draw_polyline(pts, col, w * 0.2, true)
			_rrect(ci, Rect2(pts[0] - Vector2(w * 0.02, h * 0.1), Vector2(w * 0.3, h * 0.2)), w * 0.08, col)
			_rrect(ci, Rect2(pts[-1] - Vector2(w * 0.1, h * 0.04), Vector2(w * 0.2, h * 0.3)), w * 0.08, col)
		"hangup":
			var pts2 := PackedVector2Array()
			for i in 13:
				var a2 := deg_to_rad(200.0 + i * 11.7)
				pts2.append(c + Vector2(cos(a2), sin(a2)) * w * 0.48 + Vector2(0, h * 0.35))
			ci.draw_polyline(pts2, col, t * 1.5, true)
			ci.draw_circle(pts2[0], t * 1.3, col)
			ci.draw_circle(pts2[-1], t * 1.3, col)
		"contacts", "person":
			ci.draw_circle(c - Vector2(0, h * 0.2), w * 0.2, col)
			_arc_fill(ci, c + Vector2(0, h * 0.5), w * 0.42, col)
		"gallery":
			_rrect_line(ci, r, w * 0.12, col, t)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.1, h * 0.85), p + Vector2(w * 0.4, h * 0.45), p + Vector2(w * 0.62, h * 0.85)]), col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.45, h * 0.85), p + Vector2(w * 0.67, h * 0.58), p + Vector2(w * 0.9, h * 0.85)]), col)
			ci.draw_circle(p + Vector2(w * 0.72, h * 0.28), w * 0.09, col)
		"camera":
			_rrect(ci, Rect2(p + Vector2(0, h * 0.22), Vector2(w, h * 0.68)), w * 0.12, col)
			_rrect(ci, Rect2(p + Vector2(w * 0.3, h * 0.08), Vector2(w * 0.4, h * 0.2)), w * 0.05, col)
			ci.draw_circle(c + Vector2(0, h * 0.06), w * 0.2, Color(0, 0, 0, 0.55))
			ci.draw_arc(c + Vector2(0, h * 0.06), w * 0.2, 0, TAU, 24, col, t * 0.6, true)
		"browser", "globe":
			ci.draw_arc(c, w * 0.48, 0, TAU, 40, col, t, true)
			_ellipse_line(ci, c, w * 0.2, h * 0.48, col, t * 0.8)
			ci.draw_line(c - Vector2(w * 0.48, 0), c + Vector2(w * 0.48, 0), col, t * 0.8, true)
			ci.draw_line(c - Vector2(w * 0.42, h * 0.22), c + Vector2(w * 0.42, -h * 0.22), col, t * 0.6, true)
			ci.draw_line(c - Vector2(w * 0.42, -h * 0.22), c + Vector2(w * 0.42, h * 0.22), col, t * 0.6, true)
		"maps", "pin":
			ci.draw_circle(c - Vector2(0, h * 0.14), w * 0.33, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.29, -h * 0.0), c + Vector2(w * 0.29, -h * 0.0), c + Vector2(0, h * 0.5)]), col)
			ci.draw_circle(c - Vector2(0, h * 0.14), w * 0.12, Color(0, 0, 0, 0.6))
		"email":
			_rrect_line(ci, Rect2(p + Vector2(0, h * 0.15), Vector2(w, h * 0.7)), w * 0.08, col, t)
			ci.draw_polyline(PackedVector2Array([p + Vector2(w * 0.05, h * 0.22), c + Vector2(0, h * 0.08), p + Vector2(w * 0.95, h * 0.22)]), col, t, true)
		"notes":
			_rrect_line(ci, Rect2(p + Vector2(w * 0.1, 0), Vector2(w * 0.8, h)), w * 0.08, col, t)
			for i in 4:
				var y := h * (0.25 + i * 0.17)
				ci.draw_line(p + Vector2(w * 0.25, y), p + Vector2(w * (0.75 if i < 3 else 0.55), y), col, t * 0.8, true)
		"files", "folder":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, h * 0.15), p + Vector2(w * 0.38, h * 0.15), p + Vector2(w * 0.48, h * 0.27), p + Vector2(w, h * 0.27), p + Vector2(w, h * 0.88), p + Vector2(0, h * 0.88)]), col)
		"settings", "gear":
			for i in 8:
				var a3 := i * TAU / 8.0
				var dir := Vector2(cos(a3), sin(a3))
				ci.draw_line(c + dir * w * 0.25, c + dir * w * 0.48, col, w * 0.16)
			ci.draw_circle(c, w * 0.34, col)
			ci.draw_circle(c, w * 0.13, Color(0, 0, 0, 0.6))
		"clock":
			ci.draw_arc(c, w * 0.47, 0, TAU, 40, col, t, true)
			ci.draw_line(c, c + Vector2(0, -h * 0.3), col, t, true)
			ci.draw_line(c, c + Vector2(w * 0.22, h * 0.08), col, t, true)
		"eco":
			ci.draw_arc(c, w * 0.48, 0, TAU, 40, col, t * 0.7, true)
			ci.draw_arc(c, w * 0.3, 0, TAU, 32, col, t * 0.7, true)
			ci.draw_circle(c, w * 0.12, col)
		"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(w * 0.12, -h * 0.32), c + Vector2(-w * 0.2, 0), c + Vector2(w * 0.12, h * 0.32)]), col, t, true)
		"forward", "chevron":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-w * 0.12, -h * 0.32), c + Vector2(w * 0.2, 0), c + Vector2(-w * 0.12, h * 0.32)]), col, t, true)
		"search":
			ci.draw_arc(c - Vector2(w * 0.08, h * 0.08), w * 0.3, 0, TAU, 32, col, t, true)
			ci.draw_line(c + Vector2(w * 0.14, h * 0.14), c + Vector2(w * 0.42, h * 0.42), col, t * 1.2, true)
		"send":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, h * 0.1), p + Vector2(w, h * 0.5), p + Vector2(0, h * 0.9), p + Vector2(w * 0.15, h * 0.5)]), col)
		"more":
			for i in 3:
				ci.draw_circle(c + Vector2(0, (i - 1) * h * 0.3), w * 0.08, col)
		"plus":
			ci.draw_line(c - Vector2(w * 0.4, 0), c + Vector2(w * 0.4, 0), col, t, true)
			ci.draw_line(c - Vector2(0, h * 0.4), c + Vector2(0, h * 0.4), col, t, true)
		"close":
			ci.draw_line(c - Vector2(w * 0.32, h * 0.32), c + Vector2(w * 0.32, h * 0.32), col, t, true)
			ci.draw_line(c - Vector2(w * 0.32, -h * 0.32), c + Vector2(w * 0.32, -h * 0.32), col, t, true)
		"info":
			ci.draw_arc(c, w * 0.46, 0, TAU, 40, col, t * 0.8, true)
			ci.draw_line(c - Vector2(0, h * 0.02), c + Vector2(0, h * 0.26), col, t * 1.1, true)
			ci.draw_circle(c - Vector2(0, h * 0.2), t * 0.75, col)
		"lock":
			_rrect(ci, Rect2(p + Vector2(w * 0.12, h * 0.42), Vector2(w * 0.76, h * 0.56)), w * 0.08, col)
			ci.draw_arc(c - Vector2(0, h * 0.08), w * 0.24, PI, TAU, 16, col, t, true)
			ci.draw_line(c + Vector2(-w * 0.24, -h * 0.08), c + Vector2(-w * 0.24, h * 0.0), col, t)
			ci.draw_line(c + Vector2(w * 0.24, -h * 0.08), c + Vector2(w * 0.24, h * 0.0), col, t)
		"mic":
			_rrect(ci, Rect2(c - Vector2(w * 0.15, h * 0.48), Vector2(w * 0.3, h * 0.6)), w * 0.15, col)
			ci.draw_arc(c, w * 0.3, 0.1, PI - 0.1, 16, col, t * 0.8, true)
			ci.draw_line(c + Vector2(0, h * 0.3), c + Vector2(0, h * 0.48), col, t * 0.8)
		"speaker":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, h * 0.35), p + Vector2(w * 0.25, h * 0.35), p + Vector2(w * 0.55, h * 0.08), p + Vector2(w * 0.55, h * 0.92), p + Vector2(w * 0.25, h * 0.65), p + Vector2(0, h * 0.65)]), col)
			ci.draw_arc(p + Vector2(w * 0.55, h * 0.5), w * 0.22, -0.9, 0.9, 10, col, t * 0.7, true)
			ci.draw_arc(p + Vector2(w * 0.55, h * 0.5), w * 0.4, -0.9, 0.9, 12, col, t * 0.7, true)
		"keypad":
			for i in 3:
				for j in 4:
					ci.draw_circle(p + Vector2(w * (0.18 + i * 0.32), h * (0.1 + j * 0.27)), w * 0.08, col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.2, h * 0.08), p + Vector2(w * 0.92, h * 0.5), p + Vector2(w * 0.2, h * 0.92)]), col)
		"pause":
			ci.draw_rect(Rect2(p + Vector2(w * 0.18, h * 0.1), Vector2(w * 0.22, h * 0.8)), col)
			ci.draw_rect(Rect2(p + Vector2(w * 0.6, h * 0.1), Vector2(w * 0.22, h * 0.8)), col)
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var a4 := -PI / 2 + i * PI / 5
				var rr := w * (0.5 if i % 2 == 0 else 0.22)
				sp.append(c + Vector2(cos(a4), sin(a4)) * rr)
			ci.draw_colored_polygon(sp, col)
		"trash":
			ci.draw_line(p + Vector2(w * 0.05, h * 0.18), p + Vector2(w * 0.95, h * 0.18), col, t)
			ci.draw_line(p + Vector2(w * 0.38, h * 0.05), p + Vector2(w * 0.62, h * 0.05), col, t)
			_rrect_line(ci, Rect2(p + Vector2(w * 0.17, h * 0.25), Vector2(w * 0.66, h * 0.72)), w * 0.06, col, t)
		"doc", "file":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.12, 0), p + Vector2(w * 0.62, 0), p + Vector2(w * 0.88, h * 0.26), p + Vector2(w * 0.88, h), p + Vector2(w * 0.12, h)]), col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.62, 0), p + Vector2(w * 0.62, h * 0.26), p + Vector2(w * 0.88, h * 0.26)]), Color(0, 0, 0, 0.35))
		"audio", "wave":
			for i in 7:
				var hh: float = h * [0.25, 0.55, 0.9, 0.6, 0.8, 0.4, 0.2][i]
				ci.draw_line(p + Vector2(w * (0.08 + i * 0.14), h * 0.5 - hh / 2), p + Vector2(w * (0.08 + i * 0.14), h * 0.5 + hh / 2), col, t, true)
		"image":
			_rrect(ci, r, w * 0.1, col)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.12, h * 0.82), p + Vector2(w * 0.42, h * 0.45), p + Vector2(w * 0.65, h * 0.82)]), Color(0, 0, 0, 0.45))
		"history":
			ci.draw_arc(c, w * 0.46, 0, TAU * 0.85, 36, col, t, true)
			ci.draw_line(c, c + Vector2(0, -h * 0.26), col, t)
			ci.draw_line(c, c + Vector2(w * 0.18, h * 0.12), col, t)
		"bookmark":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.2, 0), p + Vector2(w * 0.8, 0), p + Vector2(w * 0.8, h), c + Vector2(0, h * 0.22), p + Vector2(w * 0.2, h)]), col)
		"refresh":
			ci.draw_arc(c, w * 0.4, -PI * 0.2, PI * 1.5, 28, col, t, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.4, -h * 0.35), c + Vector2(w * 0.5, h * 0.0), c + Vector2(w * 0.15, -h * 0.08)]), col)
		"voicemail":
			ci.draw_arc(c - Vector2(w * 0.25, 0), w * 0.2, 0, TAU, 20, col, t, true)
			ci.draw_arc(c + Vector2(w * 0.25, 0), w * 0.2, 0, TAU, 20, col, t, true)
			ci.draw_line(c + Vector2(-w * 0.25, h * 0.2), c + Vector2(w * 0.25, h * 0.2), col, t)
		"missed":
			ci.draw_polyline(PackedVector2Array([p + Vector2(0, h * 0.2), c + Vector2(0, h * 0.2), p + Vector2(w, h * 0.0)]), col, t, true)
		"arrow_in":
			ci.draw_line(p + Vector2(w * 0.9, h * 0.1), p + Vector2(w * 0.15, h * 0.85), col, t, true)
			ci.draw_polyline(PackedVector2Array([p + Vector2(w * 0.15, h * 0.4), p + Vector2(w * 0.15, h * 0.85), p + Vector2(w * 0.6, h * 0.85)]), col, t, true)
		"arrow_out":
			ci.draw_line(p + Vector2(w * 0.1, h * 0.9), p + Vector2(w * 0.85, h * 0.15), col, t, true)
			ci.draw_polyline(PackedVector2Array([p + Vector2(w * 0.4, h * 0.15), p + Vector2(w * 0.85, h * 0.15), p + Vector2(w * 0.85, h * 0.6)]), col, t, true)
		"shutter":
			ci.draw_circle(c, w * 0.5, col)
			ci.draw_circle(c, w * 0.42, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, w * 0.38, col)
		"flip":
			ci.draw_arc(c, w * 0.38, 0.3, PI - 0.3, 16, col, t, true)
			ci.draw_arc(c, w * 0.38, PI + 0.3, TAU - 0.3, 16, col, t, true)
		"locate":
			ci.draw_arc(c, w * 0.3, 0, TAU, 28, col, t, true)
			ci.draw_circle(c, w * 0.1, col)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				ci.draw_line(c + d * w * 0.3, c + d * w * 0.48, col, t)
		"zoom_in":
			ci.draw_arc(c - Vector2(w * 0.08, h * 0.08), w * 0.3, 0, TAU, 32, col, t, true)
			ci.draw_line(c + Vector2(w * 0.14, h * 0.14), c + Vector2(w * 0.42, h * 0.42), col, t * 1.2, true)
			ci.draw_line(c - Vector2(w * 0.22, h * 0.08), c + Vector2(w * 0.06, -h * 0.08), col, t * 0.8)
			ci.draw_line(c - Vector2(w * 0.08, h * 0.22), c + Vector2(-w * 0.08, h * 0.06), col, t * 0.8)
		"edit":
			ci.draw_line(p + Vector2(w * 0.15, h * 0.85), p + Vector2(w * 0.85, h * 0.15), col, t * 1.6, true)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(w * 0.05, h * 0.95), p + Vector2(w * 0.1, h * 0.72), p + Vector2(w * 0.28, h * 0.9)]), col)
		"tag":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, h * 0.1), p + Vector2(w * 0.55, h * 0.1), p + Vector2(w, h * 0.5), p + Vector2(w * 0.55, h * 0.9), p + Vector2(0, h * 0.9)]), col)
			ci.draw_circle(p + Vector2(w * 0.2, h * 0.5), w * 0.08, Color(0, 0, 0, 0.5))
		"link":
			ci.draw_arc(c - Vector2(w * 0.18, -h * 0.18), w * 0.18, 0, TAU, 20, col, t, true)
			ci.draw_arc(c + Vector2(w * 0.18, -h * 0.18), w * 0.18, 0, TAU, 20, col, t, true)
		"wifi":
			for i in 3:
				ci.draw_arc(p + Vector2(w * 0.5, h * 0.92), w * (0.18 + i * 0.17), -PI * 0.75, -PI * 0.25, 12, col, t, true)
			ci.draw_circle(p + Vector2(w * 0.5, h * 0.88), t * 0.8, col)
		"dot":
			ci.draw_circle(c, w * 0.25, col)
		_:
			ci.draw_circle(c, w * 0.3, col)


static func _rrect(ci: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func _rrect_line(ci: CanvasItem, r: Rect2, rad: float, col: Color, w: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.draw_center = false
	sb.border_color = col
	sb.set_border_width_all(int(maxf(1.0, w)))
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func _arc_fill(ci: CanvasItem, center: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + i * PI / 20.0
		pts.append(center + Vector2(cos(a), sin(a) * 0.85) * rad)
	ci.draw_colored_polygon(pts, col)


static func _ellipse_line(ci: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := i * TAU / 32.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, w, true)
