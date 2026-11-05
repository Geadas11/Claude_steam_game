class_name AppIcon
extends Control
## An app icon: a squircle with a gradient, a soft shadow and a hairline of
## light along the top, and a small drawing of the app in it. Everything is
## drawn, so it stays sharp at any size.

## [top colour, bottom colour] of each app's tile.
const TILES := {
	"messages": ["#4fdc93", "#119e5c"],
	"phone": ["#5fe0c9", "#11968a"],
	"contacts": ["#f6c37c", "#c47c2c"],
	"gallery": ["#ff9a8a", "#d8406a"],
	"camera": ["#9aa1ab", "#3a3f48"],
	"browser": ["#69b3ff", "#1d5fd8"],
	"maps": ["#a6e27a", "#3a9a46"],
	"email": ["#9c93ff", "#5440d2"],
	"notes": ["#ffe28e", "#f1b02c"],
	"files": ["#62d6ee", "#178fb8"],
	"settings": ["#b3b8c0", "#5b6069"],
	"clock": ["#30333b", "#0c0d10"],
	"eco": ["#1c1112", "#020202"],
}

var glyph := ""
var bg := Color.GRAY


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2.0
	var tile: Array = TILES.get(glyph, [bg.lightened(0.15).to_html(), bg.darkened(0.25).to_html()])
	var top := Color(tile[0])
	var bot := Color(tile[1])
	var pts := squircle(o, s)
	# shadow: the same shape, a little lower and fainter at each step
	if s >= 30:
		for k in 3:
			var sh := PackedVector2Array()
			for p in pts:
				sh.append(p + Vector2(0, s * (0.02 + k * 0.012)))
			draw_colored_polygon(sh, Color(0, 0, 0, 0.12 - k * 0.03))
	var cols := PackedColorArray()
	for p in pts:
		var t := clampf((p.y - o.y) / s, 0.0, 1.0)
		cols.append(top.lerp(bot, t))
	draw_polygon(pts, cols)
	# light along the upper rim
	var rim := PackedVector2Array()
	for i in pts.size():
		var p: Vector2 = pts[i]
		if p.y - o.y < s * 0.32:
			rim.append(p)
	if rim.size() > 2:
		draw_polyline(rim, Color(1, 1, 1, 0.22), maxf(1.0, s * 0.012), true)
	# the app's symbol from the icon set, white, with a faint shadow under it
	var ir := Rect2(o + Vector2(s, s) * 0.22, Vector2(s, s) * 0.56)
	if Icons.has("app_" + glyph):
		Icons.draw(self, "app_" + glyph, Rect2(ir.position + Vector2(0, s * 0.015), ir.size), Color(0, 0, 0, 0.18))
		Icons.draw(self, "app_" + glyph, ir, Color(1, 1, 1, 0.98) if glyph != "eco" else Color(0.95, 0.3, 0.3))
		return
	_art(Rect2(o, Vector2(s, s)), top, bot)


## A superellipse (n = 5): the soft square of modern icons.
static func squircle(o: Vector2, s: float, n := 5.0, steps := 72) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := o + Vector2(s, s) / 2.0
	var r := s / 2.0
	for i in steps:
		var a := TAU * i / steps
		var ca := cos(a)
		var sa := sin(a)
		var x := signf(ca) * pow(absf(ca), 2.0 / n)
		var y := signf(sa) * pow(absf(sa), 2.0 / n)
		pts.append(c + Vector2(x, y) * r)
	return pts


func _art(r: Rect2, top: Color, bot: Color) -> void:
	var s := r.size.x
	var c := r.get_center()
	var W := Color(1, 1, 1, 0.97)
	var u := s / 100.0      # one unit: the tile is 100 units wide
	match glyph:
		"messages":
			_ellipse(c + Vector2(0, -3) * u, 32 * u, 26 * u, W)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 10) * u, c + Vector2(-30, 28) * u, c + Vector2(-4, 18) * u]), W)
			for i in 3:
				draw_circle(c + Vector2((i - 1) * 13, -3) * u, 4.2 * u, bot.lerp(top, 0.3))
		"phone":
			Glyph.draw_glyph(self, "phone", Rect2(c - Vector2(26, 26) * u, Vector2(52, 52) * u), W)
		"contacts":
			draw_circle(c, 33 * u, W)
			draw_circle(c + Vector2(0, -9) * u, 11 * u, bot)
			var body := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				body.append(c + Vector2(cos(a) * 20, 24 + sin(a) * 16) * u)
			draw_colored_polygon(body, bot)
		"gallery":
			var fr := Rect2(c - Vector2(30, 24) * u, Vector2(60, 48) * u)
			Glyph._rrect(self, fr, 8 * u, W)
			draw_circle(c + Vector2(13, -8) * u, 6 * u, Color("ffc94d"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-24, 18) * u, c + Vector2(-6, -6) * u, c + Vector2(10, 18) * u]), bot)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, 18) * u, c + Vector2(12, 2) * u, c + Vector2(25, 18) * u]), top.darkened(0.1))
		"camera":
			Glyph._rrect(self, Rect2(c - Vector2(32, 18) * u, Vector2(64, 42) * u), 10 * u, W)
			Glyph._rrect(self, Rect2(c + Vector2(-12, -25) * u, Vector2(24, 10) * u), 4 * u, W)
			draw_circle(c + Vector2(0, 3) * u, 15 * u, Color("1b1d22"))
			draw_circle(c + Vector2(0, 3) * u, 10 * u, Color("3a5a8c"))
			draw_circle(c + Vector2(0, 3) * u, 5 * u, Color("0b0c10"))
			draw_circle(c + Vector2(-3, 0) * u, 2.4 * u, Color(1, 1, 1, 0.7))
			draw_circle(c + Vector2(22, -10) * u, 2.6 * u, Color("ffc94d"))
		"browser":
			draw_circle(c, 32 * u, W)
			draw_arc(c, 27 * u, 0, TAU, 48, top.lerp(bot, 0.5), 1.5 * u, true)
			for i in 12:
				var a := TAU * i / 12.0
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * 23 * u, c + d * 27 * u, bot, 1.2 * u, true)
			var nd := Vector2(1, -1).normalized()
			var side := Vector2(nd.y, -nd.x)
			draw_colored_polygon(PackedVector2Array([c + nd * 21 * u, c + side * 5 * u, c - side * 5 * u]), Color("ff4d4d"))
			draw_colored_polygon(PackedVector2Array([c - nd * 21 * u, c + side * 5 * u, c - side * 5 * u]), Color("d9dde3"))
			draw_circle(c, 2.5 * u, Color("2a2d33"))
		"maps":
			var xs := [-30.0, -10.0, 10.0, 30.0]
			for i in 3:
				var col := W if i != 1 else Color(1, 1, 1, 0.72)
				var y0 := -22.0 + (4.0 if i == 1 else 0.0)
				var y1 := -22.0 + (0.0 if i == 1 else 4.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(xs[i], y0) * u, c + Vector2(xs[i + 1], y1) * u,
					c + Vector2(xs[i + 1], y1 + 44) * u, c + Vector2(xs[i], y0 + 44) * u]), col)
			draw_line(c + Vector2(-26, 12) * u, c + Vector2(24, -4) * u, Color("ffc94d"), 3 * u, true)
			draw_circle(c + Vector2(4, -10) * u, 9 * u, Color("ff4d4d"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4.5, -6) * u, c + Vector2(12.5, -6) * u, c + Vector2(4, 6) * u]), Color("ff4d4d"))
			draw_circle(c + Vector2(4, -10) * u, 3.5 * u, W)
		"email":
			var er := Rect2(c - Vector2(32, 22) * u, Vector2(64, 44) * u)
			Glyph._rrect(self, er, 7 * u, W)
			draw_polyline(PackedVector2Array([er.position + Vector2(4, 4) * u, c + Vector2(0, 3) * u, er.position + Vector2(60, 4) * u]), bot, 3.2 * u, true)
		"notes":
			var page := Rect2(c + Vector2(-30, -16) * u, Vector2(60, 46) * u)
			Glyph._rrect(self, page, 6 * u, W)
			draw_rect(Rect2(c + Vector2(-30, -30) * u, Vector2(60, 12) * u), Color(1, 1, 1, 0.25))
			for i in 4:
				var y := -6.0 + i * 10.0
				draw_line(c + Vector2(-22, y) * u, c + Vector2(22 if i < 3 else 6, y) * u, Color("c9c4b8"), 2 * u, true)
		"files":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-32, -22) * u, c + Vector2(-8, -22) * u, c + Vector2(-2, -15) * u,
				c + Vector2(32, -15) * u, c + Vector2(32, 22) * u, c + Vector2(-32, 22) * u]), Color(1, 1, 1, 0.6))
			Glyph._rrect(self, Rect2(c + Vector2(-32, -9) * u, Vector2(64, 33) * u), 6 * u, W)
		"settings":
			var teeth := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48.0
				var k := i % 4
				var rr := 31.0 if k == 1 or k == 2 else 25.0
				teeth.append(c + Vector2(cos(a), sin(a)) * rr * u)
			draw_colored_polygon(teeth, Color("eef0f3"))
			draw_circle(c, 18 * u, Color("c9cdd3"))
			draw_circle(c, 9 * u, bot.darkened(0.2))
		"clock":
			draw_circle(c, 34 * u, W)
			for i in 12:
				var a := TAU * i / 12.0
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * (26 if i % 3 else 23) * u, c + d * 30 * u, Color("1b1d22"), (2.6 if i % 3 == 0 else 1.4) * u, true)
			draw_line(c, c + Vector2(0, -19) * u, Color("1b1d22"), 3.2 * u, true)
			draw_line(c, c + Vector2(14, 6) * u, Color("1b1d22"), 3.2 * u, true)
			draw_line(c + Vector2(-5, 9) * u, c + Vector2(13, -22) * u, Color("e4a33a"), 1.4 * u, true)
			draw_circle(c, 2.6 * u, Color("e4a33a"))
		"eco":
			for i in 3:
				draw_arc(c, (10 + i * 10) * u, 0, TAU, 48, Color(0.9, 0.2, 0.22, 0.75 - i * 0.2), 1.6 * u, true)
			draw_circle(c, 5 * u, Color(0.95, 0.25, 0.25))
		_:
			Glyph.draw_glyph(self, glyph, Rect2(c - Vector2(26, 26) * u, Vector2(52, 52) * u), W)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
