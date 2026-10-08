class_name Avatar
extends Control
## Circular contact avatar with initials (or a "?" for unknown numbers).

var contact_id := "":
	set(v):
		contact_id = v
		queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) / 2.0
	var c := size / 2.0
	var info := GameState.contact(contact_id) if contact_id != "" else {}
	var col := Color(info.get("color", "#3a3f47"))
	var saved: bool = info.get("saved", false)
	if not saved:
		col = Color("2a2e35")
	draw_circle(c, r, col)
	var font := get_theme_default_font()
	var txt: String = info.get("initials", "?") if saved else ""
	if info.get("group", false):
		txt = info.get("initials", "G")
	if txt == "":
		Glyph.draw_glyph(self, "person", Rect2(c - Vector2(r, r) * 0.55, Vector2(r, r) * 1.1), Color(1, 1, 1, 0.45))
		return
	var fsz := int(r * 0.8)
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	draw_string(font, c + Vector2(-ts.x / 2.0, fsz * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(1, 1, 1, 0.92))
