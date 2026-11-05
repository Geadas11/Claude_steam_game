class_name Icons
extends RefCounted
## The phone's icon set (Tabler Icons, MIT — data/icons.json, built by
## tools/build_icons.py). Each icon is an SVG, rasterised on demand at the
## size it is really shown at on screen, so it is sharp at any scale.

static var _svgs := {}
static var _cache := {}


static func has(name: String) -> bool:
	_load()
	return _svgs.has(name)


static func _load() -> void:
	if not _svgs.is_empty():
		return
	var f := FileAccess.open("res://data/icons.json", FileAccess.READ)
	if f == null:
		_svgs = {"_": ""}
		return
	var d = JSON.parse_string(f.get_as_text())
	_svgs = d if d is Dictionary else {"_": ""}


## The icon as a white texture about `px` pixels wide (rounded up a little,
## so nearby sizes share one texture).
static func texture(name: String, px: float) -> Texture2D:
	_load()
	var size := clampi(int(ceil(px / 8.0)) * 8, 16, 512)
	var key := "%s@%d" % [name, size]
	if _cache.has(key):
		return _cache[key]
	var img := Image.new()
	if img.load_svg_from_string(str(_svgs.get(name, "")), size / 24.0) != OK:
		_cache[key] = null
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Draw an icon into `r` on any canvas item, tinted `col`. Returns false when
## there is no such icon (the caller draws its own).
static func draw(ci: CanvasItem, name: String, r: Rect2, col: Color) -> bool:
	if not has(name):
		return false
	# how many real pixels the rect covers (window stretch, phone scale...)
	var k := (ci.get_viewport().get_final_transform() * ci.get_global_transform_with_canvas()).get_scale().x if ci.is_inside_tree() else 1.0
	var tex := texture(name, r.size.x * absf(k))
	if tex == null:
		return false
	if name == "hangup":
		# the handset turned down, as on the red button of a call
		var c := r.get_center()
		ci.draw_set_transform(c, deg_to_rad(135.0), Vector2.ONE)
		ci.draw_texture_rect(tex, Rect2(-r.size / 2.0, r.size), false, col)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return true
	ci.draw_texture_rect(tex, r, false, col)
	return true
