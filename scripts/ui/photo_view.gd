class_name PhotoView
extends Control
## Renders a "photograph" from a data description (preset + layers).
## Photos are deterministic for a given (spec, variant), which lets the story
## change one detail between two viewings without the player being able to
## prove it.

const GRAIN_SHADER := """
shader_type canvas_item;
uniform float amount = 0.08;
uniform float seed = 1.0;
uniform float animate = 0.0;
uniform float vignette = 0.45;
uniform float mono = 0.0;
float rnd(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233)) + seed) * 43758.5453); }
void fragment(){
	vec2 px = floor(FRAGCOORD.xy / 1.5);
	float t = floor(TIME * 18.0) * animate;
	float n = rnd(px + vec2(t, t * 1.7));
	vec2 uv = UV - 0.5;
	float vig = smoothstep(0.3, 0.9, length(uv) * 1.25) * vignette;
	vec3 g = vec3(n);
	if (mono > 0.5) { g = vec3(n * 0.8); }
	float ga = amount;
	COLOR = vec4(mix(g, vec3(0.0), vig / (vig + ga + 0.0001)), clamp(ga + vig, 0.0, 1.0));
}
"""

static var _grain_shader: Shader

var photo_id := ""
var spec: Dictionary = {}
var variant := "base"
var live := false          # animated grain (camera viewfinder)
var shake := 0.0
var _layers: Array = []
var _grain: ColorRect
var _rng := RandomNumberGenerator.new()
var _t := 0.0


func _ready() -> void:
	clip_contents = true
	if _grain_shader == null:
		_grain_shader = Shader.new()
		_grain_shader.code = GRAIN_SHADER
	_grain = ColorRect.new()
	_grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _grain_shader
	_grain.material = mat
	add_child(_grain)
	_apply_grain()
	resized.connect(queue_redraw)


func set_photo(id: String, v := "") -> void:
	photo_id = id
	var d := Content.get_item("photos", id)
	spec = d.get("scene", {})
	variant = v if v != "" else GameState.photo_variant(id)
	_build()


func set_scene(s: Dictionary, v := "base") -> void:
	photo_id = ""
	spec = s
	variant = v
	_build()


func _build() -> void:
	_layers = PhotoPresets.build(spec, variant)
	_apply_grain()
	queue_redraw()


func _apply_grain() -> void:
	if _grain == null:
		return
	var mat: ShaderMaterial = _grain.material
	mat.set_shader_parameter("amount", float(spec.get("grain", 0.07)) * (1.0 if not Settings.get_value("reduce_effects", false) else 0.6))
	mat.set_shader_parameter("seed", float(hash(photo_id + variant) % 1000) / 10.0)
	mat.set_shader_parameter("animate", 1.0 if live else 0.0)
	mat.set_shader_parameter("vignette", float(spec.get("vignette", 0.45)))


func _process(delta: float) -> void:
	if live:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if live and shake > 0.0 and not Settings.get_value("reduce_motion", false):
		var off := Vector2(sin(_t * 1.3) * 3.0 + sin(_t * 3.1), cos(_t * 1.1) * 2.5) * shake
		r.position += off - Vector2(6, 6)
		r.size += Vector2(12, 12)
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	for L in _layers:
		_draw_layer(L, r)


# ---------------------------------------------------------------- drawing
func _P(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x * r.size.x, y * r.size.y)


func _col(v, alpha_mul := 1.0) -> Color:
	var c: Color
	if typeof(v) == TYPE_STRING:
		c = Color.html(v) if Color.html_is_valid(v) else Color.MAGENTA
	elif typeof(v) == TYPE_COLOR:
		c = v
	else:
		c = Color.MAGENTA
	c.a *= alpha_mul
	return c


func _pts(r: Rect2, arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, arr.size() - 1, 2):
		out.append(_P(r, float(arr[i]), float(arr[i + 1])))
	return out


func _draw_layer(L: Dictionary, r: Rect2) -> void:
	var a: float = float(L.get("a", 1.0))
	match L.get("t", ""):
		"grad":
			var cs: Array = L.c
			var y0: float = float(L.get("y0", 0.0))
			var y1: float = float(L.get("y1", 1.0))
			var n := cs.size()
			for i in n - 1:
				var ya := lerpf(y0, y1, float(i) / (n - 1))
				var yb := lerpf(y0, y1, float(i + 1) / (n - 1))
				var ca := _col(cs[i], a)
				var cb := _col(cs[i + 1], a)
				draw_polygon(PackedVector2Array([_P(r, 0, ya), _P(r, 1, ya), _P(r, 1, yb), _P(r, 0, yb)]), PackedColorArray([ca, ca, cb, cb]))
		"rect":
			var rr: Array = L.r
			var p0 := _P(r, rr[0], rr[1])
			var p1 := _P(r, float(rr[0]) + float(rr[2]), float(rr[1]) + float(rr[3]))
			if L.has("c2"):
				var c1 := _col(L.c, a)
				var c2 := _col(L.c2, a)
				draw_polygon(PackedVector2Array([p0, Vector2(p1.x, p0.y), p1, Vector2(p0.x, p1.y)]), PackedColorArray([c1, c1, c2, c2]))
			else:
				draw_rect(Rect2(p0, p1 - p0), _col(L.c, a))
		"poly":
			var pts := _pts(r, L.pts)
			if pts.size() >= 3:
				draw_colored_polygon(pts, _col(L.c, a))
		"line":
			draw_polyline(_pts(r, L.pts), _col(L.c, a), maxf(1.0, float(L.get("w", 0.004)) * r.size.x), true)
		"circle":
			var p: Array = L.p
			draw_circle(_P(r, p[0], p[1]), float(L.r) * r.size.x, _col(L.c, a))
		"ellipse":
			var pe: Array = L.p
			_ellipse(_P(r, pe[0], pe[1]), float(L.rx) * r.size.x, float(L.ry) * r.size.y, _col(L.c, a), float(L.get("rot", 0.0)))
		"glow":
			var pg: Array = L.p
			var center := _P(r, pg[0], pg[1])
			var rad: float = float(L.r) * r.size.x
			var gc := _col(L.c, a)
			var steps := 14
			for i in steps:
				var f := 1.0 - float(i) / steps
				var cc := gc
				cc.a = gc.a * (1.0 / steps) * 1.6 * (1.0 - f * 0.4)
				draw_circle(center, rad * f, cc)
		"figure":
			_figure(L, r, a)
		"face":
			_face(L, r, a)
		"text":
			var pt: Array = L.p
			var fsz := int(float(L.get("s", 0.03)) * r.size.y)
			draw_string(get_theme_default_font(), _P(r, pt[0], pt[1]), str(L.v), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(fsz, 6), _col(L.get("c", "#ffffff"), a))
		"windows":
			_windows(L, r, a)
		"stars":
			_rng.seed = int(L.get("seed", 7))
			var reg: Array = L.get("region", [0, 0, 1, 0.4])
			for i in int(L.get("n", 40)):
				var sx := float(reg[0]) + _rng.randf() * float(reg[2])
				var sy := float(reg[1]) + _rng.randf() * float(reg[3])
				draw_circle(_P(r, sx, sy), _rng.randf_range(0.4, 1.3), Color(1, 1, 1, _rng.randf_range(0.2, 0.8) * a))
		"sea":
			_sea(L, r, a)
		"rain":
			_rng.seed = int(L.get("seed", 3))
			var rc := _col(L.get("c", "#9fb3c8"), a * 0.35)
			for i in int(L.get("n", 120)):
				var x := _rng.randf()
				var y := _rng.randf()
				var p1 := _P(r, x, y)
				draw_line(p1, p1 + Vector2(-2, 12) * (r.size.y / 600.0), rc, 1.0)
		"books":
			_books(L, r, a)
		"lines":
			# document text lines
			_rng.seed = int(L.get("seed", 5))
			var lr: Array = L.r
			var lc := _col(L.get("c", "#2b2b2b"), a)
			var y := float(lr[1])
			var step: float = float(L.get("step", 0.03))
			while y < float(lr[1]) + float(lr[3]):
				var wl := float(lr[2]) * _rng.randf_range(0.55, 1.0)
				draw_rect(Rect2(_P(r, lr[0], y), Vector2(wl * r.size.x, maxf(1.5, step * 0.32 * r.size.y))), lc)
				y += step
		"blur":
			# smear over a region (used to "erase" someone)
			var pb: Array = L.p
			var bc := _col(L.c, a)
			_rng.seed = int(L.get("seed", 9))
			for i in 30:
				var off := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * float(L.r) * r.size.x * 0.6
				var cc2 := bc
				cc2.a = bc.a * 0.12
				draw_circle(_P(r, pb[0], pb[1]) + off, float(L.r) * r.size.x * _rng.randf_range(0.4, 1.0), cc2)
		"scanlines":
			var sc := _col(L.get("c", "#000000"), float(L.get("a", 0.25)))
			var yy := 0.0
			while yy < r.size.y:
				draw_line(Vector2(r.position.x, r.position.y + yy), Vector2(r.position.x + r.size.x, r.position.y + yy), sc, 1.0)
				yy += 3.0
		"tint":
			draw_rect(r, _col(L.c, a))


func _ellipse(center: Vector2, rx: float, ry: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var ang := i * TAU / 28.0
		var v := Vector2(cos(ang) * rx, sin(ang) * ry).rotated(rot)
		pts.append(center + v)
	draw_colored_polygon(pts, col)


func _figure(L: Dictionary, r: Rect2, a: float) -> void:
	var p: Array = L.p
	var feet := _P(r, p[0], p[1])
	var h: float = float(L.get("h", 0.3)) * r.size.y
	var col := _col(L.get("c", "#050506"), a)
	var pose: String = L.get("pose", "stand")
	var head_r := h * 0.075
	var head := feet + Vector2(0, -h + head_r)
	var sw := h * (0.13 if pose != "side" else 0.08)
	var shoulder_y := head.y + head_r * 1.9
	var hip_y := feet.y - h * 0.46
	if pose == "sit":
		hip_y = feet.y - h * 0.25
	# head + neck
	draw_circle(head, head_r, col)
	if pose == "hood":
		_ellipse(head + Vector2(0, head_r * 0.2), head_r * 1.35, head_r * 1.45, col)
	draw_rect(Rect2(head.x - head_r * 0.4, head.y, head_r * 0.8, head_r * 1.6), col)
	# torso
	var torso := PackedVector2Array([
		Vector2(head.x - sw, shoulder_y + head_r * 0.3),
		Vector2(head.x - sw * 0.82, shoulder_y - head_r * 0.15),
		Vector2(head.x + sw * 0.82, shoulder_y - head_r * 0.15),
		Vector2(head.x + sw, shoulder_y + head_r * 0.3),
		Vector2(head.x + sw * 0.78, hip_y),
		Vector2(head.x - sw * 0.78, hip_y),
	])
	draw_colored_polygon(torso, col)
	# arms
	var arm_w := sw * 0.32
	var hand_y := hip_y + h * 0.05
	if pose == "phone":
		draw_line(Vector2(head.x - sw * 0.9, shoulder_y), Vector2(head.x - sw * 0.2, shoulder_y + h * 0.16), col, arm_w)
		draw_line(Vector2(head.x - sw * 0.2, shoulder_y + h * 0.16), Vector2(head.x - sw * 0.1, shoulder_y + h * 0.05), col, arm_w)
		draw_rect(Rect2(head.x - sw * 0.25, shoulder_y + h * 0.0, sw * 0.35, h * 0.07), Color(0.75, 0.85, 1.0, 0.85 * a))
	else:
		draw_line(Vector2(head.x - sw * 0.92, shoulder_y + head_r * 0.2), Vector2(head.x - sw * 1.0, hand_y), col, arm_w)
	draw_line(Vector2(head.x + sw * 0.92, shoulder_y + head_r * 0.2), Vector2(head.x + sw * 1.0, hand_y), col, arm_w)
	# legs
	if pose == "sit":
		draw_line(Vector2(head.x - sw * 0.4, hip_y), Vector2(head.x - sw * 0.4 + h * 0.18, hip_y), col, sw * 0.6)
		draw_line(Vector2(head.x - sw * 0.4 + h * 0.18, hip_y), Vector2(head.x - sw * 0.4 + h * 0.18, feet.y), col, sw * 0.5)
	else:
		var lw := sw * 0.42
		draw_colored_polygon(PackedVector2Array([Vector2(head.x - sw * 0.78, hip_y), Vector2(head.x - sw * 0.05, hip_y), Vector2(head.x - sw * 0.15, feet.y), Vector2(head.x - sw * 0.15 - lw, feet.y)]), col)
		draw_colored_polygon(PackedVector2Array([Vector2(head.x + sw * 0.05, hip_y), Vector2(head.x + sw * 0.78, hip_y), Vector2(head.x + sw * 0.15 + lw, feet.y), Vector2(head.x + sw * 0.15, feet.y)]), col)
	if L.get("eyes", false):
		var ec := Color(0.95, 0.95, 0.9, 0.85 * a)
		draw_circle(head + Vector2(-head_r * 0.35, -head_r * 0.05), maxf(0.8, head_r * 0.1), ec)
		draw_circle(head + Vector2(head_r * 0.35, -head_r * 0.05), maxf(0.8, head_r * 0.1), ec)


func _face(L: Dictionary, r: Rect2, a: float) -> void:
	var p: Array = L.p
	var c := _P(r, p[0], p[1])
	var rad: float = float(L.get("r", 0.12)) * r.size.x
	var skin := _col(L.get("skin", "#c99a7a"), a)
	var hair := _col(L.get("hair", "#2a1d17"), a)
	var cloth := _col(L.get("cloth", "#2d3b4a"), a)
	var style: String = L.get("style", "short")
	var shade := Color(0, 0, 0, 0.18 * a)
	# shoulders
	_ellipse(c + Vector2(0, rad * 2.3), rad * 1.9, rad * 1.1, cloth)
	draw_rect(Rect2(c.x - rad * 0.35, c.y + rad * 0.7, rad * 0.7, rad * 0.8), skin.darkened(0.12))
	# hair back
	if style == "long":
		_ellipse(c + Vector2(0, rad * 0.35), rad * 1.18, rad * 1.45, hair)
		draw_rect(Rect2(c.x - rad * 1.15, c.y, rad * 2.3, rad * 1.5), hair)
	elif style == "bun":
		draw_circle(c + Vector2(0, -rad * 1.2), rad * 0.45, hair)
	# face
	_ellipse(c, rad * 0.86, rad * 1.05, skin)
	_ellipse(c + Vector2(rad * 0.3, rad * 0.1), rad * 0.5, rad * 0.9, shade)
	# hair top
	var top := PackedVector2Array()
	for i in 17:
		var ang := PI + i * PI / 16.0
		top.append(c + Vector2(cos(ang) * rad * 0.95, sin(ang) * rad * 1.15 - rad * 0.05))
	if style == "short" or style == "long" or style == "bun":
		top.append(c + Vector2(rad * 0.9, -rad * 0.25))
		top.append(c + Vector2(-rad * 0.6, -rad * 0.45))
		top.append(c + Vector2(-rad * 0.92, -rad * 0.1))
	elif style == "buzz":
		top = PackedVector2Array()
		for i in 17:
			var ang2 := PI + i * PI / 16.0
			top.append(c + Vector2(cos(ang2) * rad * 0.88, sin(ang2) * rad * 1.08))
	draw_colored_polygon(top, hair)
	if style == "beard":
		# lower half-ellipse, starting just below the cheekbones
		var beard := PackedVector2Array()
		for i in 17:
			var ang3 := i * PI / 16.0
			beard.append(c + Vector2(cos(ang3) * rad * 0.86, rad * 0.12 + sin(ang3) * rad * 0.93))
		draw_colored_polygon(beard, hair.darkened(0.1))
	# features
	if not L.get("noface", false):
		var eye := Color(0.08, 0.06, 0.05, a)
		var ey := c.y - rad * 0.08
		if L.get("closed", false):
			draw_line(Vector2(c.x - rad * 0.45, ey), Vector2(c.x - rad * 0.2, ey), eye, maxf(1.0, rad * 0.06))
			draw_line(Vector2(c.x + rad * 0.2, ey), Vector2(c.x + rad * 0.45, ey), eye, maxf(1.0, rad * 0.06))
		else:
			_ellipse(Vector2(c.x - rad * 0.33, ey), rad * 0.09, rad * 0.07, eye)
			_ellipse(Vector2(c.x + rad * 0.33, ey), rad * 0.09, rad * 0.07, eye)
		draw_line(Vector2(c.x - rad * 0.5, ey - rad * 0.2), Vector2(c.x - rad * 0.18, ey - rad * 0.23), hair, maxf(1.0, rad * 0.06))
		draw_line(Vector2(c.x + rad * 0.18, ey - rad * 0.23), Vector2(c.x + rad * 0.5, ey - rad * 0.2), hair, maxf(1.0, rad * 0.06))
		var mouth := Color(0.45, 0.2, 0.2, 0.8 * a)
		if L.get("smile", true):
			draw_arc(c + Vector2(0, rad * 0.32), rad * 0.25, 0.3, PI - 0.3, 10, mouth, maxf(1.0, rad * 0.06), true)
		else:
			draw_line(c + Vector2(-rad * 0.18, rad * 0.5), c + Vector2(rad * 0.18, rad * 0.5), mouth, maxf(1.0, rad * 0.05))


func _windows(L: Dictionary, r: Rect2, a: float) -> void:
	_rng.seed = int(L.get("seed", 11))
	var wr: Array = L.r
	var cols := int(L.get("cols", 4))
	var rows := int(L.get("rows", 5))
	var lit := float(L.get("lit", 0.3))
	var cw := float(wr[2]) / cols
	var rh := float(wr[3]) / rows
	for i in cols:
		for j in rows:
			var on := _rng.randf() < lit
			var col := _col(L.get("c", "#e8c37a") if on else L.get("off", "#141820"), a)
			var x := float(wr[0]) + i * cw + cw * 0.2
			var y := float(wr[1]) + j * rh + rh * 0.2
			draw_rect(Rect2(_P(r, x, y), Vector2(cw * 0.6 * r.size.x, rh * 0.55 * r.size.y)), col)


func _sea(L: Dictionary, r: Rect2, a: float) -> void:
	var y0: float = float(L.get("y", 0.6))
	var cs: Array = L.get("c", ["#0b1622", "#04080d"])
	var c0 := _col(cs[0], a)
	var c1 := _col(cs[1], a)
	draw_polygon(PackedVector2Array([_P(r, 0, y0), _P(r, 1, y0), _P(r, 1, 1), _P(r, 0, 1)]), PackedColorArray([c0, c0, c1, c1]))
	_rng.seed = int(L.get("seed", 4))
	var hl := _col(L.get("hl", "#8aa4bf"), a * float(L.get("hla", 0.18)))
	for i in int(L.get("waves", 30)):
		var yy := y0 + pow(_rng.randf(), 1.6) * (1.0 - y0)
		var xx := _rng.randf()
		var ww := (0.02 + (yy - y0) * 0.25) * _rng.randf_range(0.5, 1.5)
		draw_line(_P(r, xx, yy), _P(r, xx + ww, yy), hl, 1.0 + (yy - y0) * 3.0)


func _books(L: Dictionary, r: Rect2, a: float) -> void:
	_rng.seed = int(L.get("seed", 21))
	var br: Array = L.r
	var shelves := int(L.get("shelves", 4))
	var palette := ["#7a2e2e", "#2e4a7a", "#3f6b4a", "#b08a3e", "#5a3e6b", "#c9c2b0", "#2b2b2b", "#8a5a3c", "#3c6e78"]
	var sh := float(br[3]) / shelves
	for s in shelves:
		var y := float(br[1]) + s * sh
		draw_rect(Rect2(_P(r, br[0], y + sh * 0.92), Vector2(float(br[2]) * r.size.x, sh * 0.08 * r.size.y)), _col("#3a2a1d", a))
		var x := float(br[0]) + 0.005
		while x < float(br[0]) + float(br[2]) - 0.02:
			var bw := _rng.randf_range(0.015, 0.035)
			var bh := sh * _rng.randf_range(0.6, 0.88)
			var col := _col(palette[_rng.randi() % palette.size()], a)
			draw_rect(Rect2(_P(r, x, y + sh * 0.92 - bh), Vector2(bw * r.size.x, bh * r.size.y)), col.darkened(_rng.randf_range(0.0, 0.35)))
			x += bw + 0.002
