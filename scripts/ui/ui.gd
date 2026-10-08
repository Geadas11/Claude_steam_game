class_name UI
extends RefCounted
## UI construction helpers and the "Lumen OS" visual identity.

const SCREEN := Vector2(420, 880)

const PALETTE := {
	"bg": Color("0b0d10"),
	"surf": Color("15181d"),
	"surf2": Color("1e2228"),
	"line": Color("2a2f37"),
	"text": Color("e9e6e1"),
	"dim": Color("a3a9b0"),
	"faint": Color("858b93"),
	"accent": Color("d9b26f"),
	"me": Color("2c4255"),
	"them": Color("20242b"),
	"danger": Color("e06c6c"),
	"ok": Color("6fc59a"),
	"link": Color("8fb8de"),
}

const HC_PALETTE := {
	"bg": Color("000000"),
	"surf": Color("0d0d0d"),
	"surf2": Color("1a1a1a"),
	"line": Color("6a6a6a"),
	"text": Color("ffffff"),
	"dim": Color("cfcfcf"),
	"faint": Color("a0a0a0"),
	"accent": Color("ffcc66"),
	"me": Color("1f4f7a"),
	"them": Color("2a2a2a"),
	"danger": Color("ff7070"),
	"ok": Color("80ffb0"),
	"link": Color("a8d4ff"),
}


static func c(key: String) -> Color:
	if Settings.get_value("high_contrast", false):
		return HC_PALETTE.get(key, Color.MAGENTA)
	return PALETTE.get(key, Color.MAGENTA)


static func fs(base: int) -> int:
	return Settings.text_size(base)


# ------------------------------------------------------------------ type
## Inter (SIL OFL, assets/fonts) — the typeface of modern phone UIs. Glyphs it
## lacks (✓, arrows, symbols) fall back to Godot's default font.
static var _fonts := {}


static func font(weight := "regular") -> Font:
	if _fonts.is_empty():
		var files := {"regular": "inter-latin-400-normal", "medium": "inter-latin-500-normal",
			"semibold": "inter-latin-600-normal", "italic": "inter-latin-400-italic"}
		for k in files:
			var path: String = "res://assets/fonts/%s.woff2" % files[k]
			if ResourceLoader.exists(path):
				var f: FontFile = load(path)
				f.fallbacks = [ThemeDB.fallback_font]
				_fonts[k] = f
	return _fonts.get(weight, ThemeDB.fallback_font)


# ------------------------------------------------------------------ motion
## Shared timings (seconds). Everything that moves uses these so the whole
## phone feels like one system; "reduce_motion" turns them off.
const T_PRESS := 0.09      # finger down
const T_RELEASE := 0.16    # finger up (slightly slower, springy)
const T_SCREEN := 0.2      # app / screen in and out


static func motion_ok() -> bool:
	return not Settings.get_value("reduce_motion", false)


## Visible press feedback: the control shrinks a little under the finger and
## springs back on release. Scale only, so nothing around it moves.
static func press_fx(b: BaseButton, amount := 0.95) -> BaseButton:
	var tw_ref := [null]
	var to := func(s: float, t: float, trans: Tween.TransitionType) -> void:
		if not b.is_inside_tree():
			return
		if tw_ref[0]:
			tw_ref[0].kill()
		if not motion_ok():
			b.scale = Vector2.ONE
			return
		b.pivot_offset = b.size / 2
		var tw: Tween = b.create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2(s, s), t)
		tw_ref[0] = tw
	b.button_down.connect(func(): to.call(amount, T_PRESS, Tween.TRANS_CUBIC))
	b.button_up.connect(func(): to.call(1.0, T_RELEASE, Tween.TRANS_BACK))
	return b


# ------------------------------------------------------------------ theme
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = fs(16)
	t.set_font("bold_font", "RichTextLabel", font("semibold"))
	t.set_font("italics_font", "RichTextLabel", font("italic"))
	var flat := StyleBoxEmpty.new()
	var hover := box(Color(1, 1, 1, 0.05), 10)
	var pressed := box(Color(1, 1, 1, 0.09), 10)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = c("accent").darkened(0.2)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(10)
	for st in ["normal", "disabled"]:
		t.set_stylebox(st, "Button", flat)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("hover_pressed", "Button", pressed)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", c("text"))
	t.set_color("font_hover_color", "Button", c("text"))
	t.set_color("font_pressed_color", "Button", c("accent"))
	t.set_color("font_focus_color", "Button", c("text"))
	t.set_color("font_disabled_color", "Button", c("faint"))
	t.set_color("font_color", "Label", c("text"))
	var le := box(c("surf2"), 18)
	le.content_margin_left = 14
	le.content_margin_right = 14
	le.content_margin_top = 8
	le.content_margin_bottom = 8
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = c("accent").darkened(0.3)
	lef.set_border_width_all(1)
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_color("font_color", "LineEdit", c("text"))
	t.set_color("font_placeholder_color", "LineEdit", c("faint"))
	t.set_color("caret_color", "LineEdit", c("accent"))
	t.set_stylebox("normal", "TextEdit", le)
	t.set_stylebox("focus", "TextEdit", lef)
	t.set_color("font_color", "TextEdit", c("text"))
	# thin scrollbars
	var grab := box(Color(1, 1, 1, 0.16), 3)
	grab.content_margin_left = 3
	grab.content_margin_right = 3
	var grab_h := box(Color(1, 1, 1, 0.3), 3)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 3
	empty.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", empty)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_h)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_h)
	t.set_stylebox("scroll", "HScrollBar", empty)
	t.set_stylebox("grabber", "HScrollBar", grab)
	t.set_stylebox("panel", "PanelContainer", empty)
	t.set_stylebox("panel", "Panel", empty)
	# rich text
	t.set_color("default_color", "RichTextLabel", c("text"))
	t.set_font_size("normal_font_size", "RichTextLabel", fs(16))
	t.set_font_size("bold_font_size", "RichTextLabel", fs(16))
	t.set_font_size("italics_font_size", "RichTextLabel", fs(16))
	# sliders / checkboxes in menus
	var slider := box(c("line"), 3)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", box(c("accent").darkened(0.2), 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(c("accent"), 3))
	return t


static func box(color: Color, radius := 0, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.anti_aliasing = true
	return s


static func pad(s: StyleBox, l: float, t: float, r: float, b: float) -> StyleBox:
	s.content_margin_left = l
	s.content_margin_top = t
	s.content_margin_right = r
	s.content_margin_bottom = b
	return s


# ------------------------------------------------------------------ nodes
static func label(text: String, size := 16, color_key := "text", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", c(color_key))
	# hierarchy by weight, like a phone OS: titles semibold, subheads medium
	if size >= 20:
		l.add_theme_font_override("font", font("semibold"))
	elif size >= 17:
		l.add_theme_font_override("font", font("medium"))
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func rich(bbcode: String, size := 16) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bbcode
	r.add_theme_font_size_override("normal_font_size", fs(size))
	r.add_theme_font_size_override("bold_font_size", fs(size))
	r.add_theme_font_size_override("italics_font_size", fs(size))
	r.add_theme_color_override("default_color", c("text"))
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func button(text: String, cb: Callable, size := 16, color_key := "text") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", fs(size))
	b.add_theme_color_override("font_color", c(color_key))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func():
		Audio.play("tap", -8.0)
		cb.call())
	press_fx(b, 0.96)
	return b


static func pill_button(text: String, cb: Callable, bg_key := "surf2", fg_key := "text", size := 15) -> Button:
	var b := button(text, cb, size, fg_key)
	var n := pad(box(c(bg_key), 18), 16, 8, 16, 8)
	var h := pad(box(c(bg_key).lightened(0.08), 18), 16, 8, 16, 8)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", pad(box(Color(0, 0, 0, 0), 18, c("accent"), 1), 16, 8, 16, 8))
	return b


static func icon_button(glyph: String, cb: Callable, size := 40, color_key := "text") -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var g := Glyph.new()
	g.glyph = glyph
	g.color = c(color_key)
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)
	b.pressed.connect(func():
		Audio.play("tap", -8.0)
		cb.call())
	press_fx(b, 0.88)
	return b


static func glyph(name: String, size := 20, color_key := "text") -> Glyph:
	var g := Glyph.new()
	g.glyph = name
	g.color = c(color_key)
	g.custom_minimum_size = Vector2(size, size)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


static func vbox(sep := 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margin(l := 0, t := 0, r := 0, b := 0) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m


static func panel(color: Color, radius := 0, l := 0, t := 0, r := 0, b := 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", pad(box(color, radius), l, t, r, b))
	return p


static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.follow_focus = true
	return s


static func spacer(h := 0, w := 0) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func expand() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func separator() -> Control:
	var r := ColorRect.new()
	r.color = c("line")
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func avatar(contact_id: String, size := 44) -> Avatar:
	var a := Avatar.new()
	a.contact_id = contact_id
	a.custom_minimum_size = Vector2(size, size)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


## A focusable full-width row: Button with arbitrary content laid over it.
static func row(content: Control, cb: Callable, height := 64) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.04), 0))
	b.add_theme_stylebox_override("pressed", box(Color(1, 1, 1, 0.08), 0))
	b.add_theme_stylebox_override("focus", box(Color(1, 1, 1, 0.04), 0, c("accent").darkened(0.4), 1))
	var m := margin(16, 6, 16, 6)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_mouse(content)
	m.add_child(content)
	b.add_child(m)
	b.pressed.connect(func():
		Audio.play("tap", -10.0)
		cb.call())
	press_fx(b, 0.985)
	return b


static func _ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in n.get_children():
		_ignore_mouse(ch)


## Button whose text wraps to a fixed width (Button.autowrap sizes badly in containers).
static func wrap_button(text: String, cb: Callable, width: float, size := 15, bg_key := "surf2", fg_key := "text", border := false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var font := ThemeDB.fallback_font
	var inner_w := width - 32.0
	var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, inner_w, fs(size)).y
	b.custom_minimum_size = Vector2(width, h + 18.0)
	var n := box(c(bg_key), 18)
	if border:
		n = box(Color(0, 0, 0, 0), 18, c("line"), 1)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", box(c(bg_key).lightened(0.08), 18))
	b.add_theme_stylebox_override("pressed", box(c(bg_key).lightened(0.12), 18))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 18, c("accent"), 1))
	var l := label(text, size, fg_key, true)
	l.position = Vector2(16, 9)
	l.size = Vector2(inner_w, h)
	b.add_child(l)
	b.pressed.connect(func():
		Audio.play("tap", -8.0)
		cb.call())
	press_fx(b, 0.97)
	return b


## Standard app header: [back] Title ........ [extra]
static func header(title: String, back_cb: Callable, extra: Array = [], subtitle := "") -> Control:
	var bar := panel(c("bg"), 0, 6, 4, 10, 4)
	bar.custom_minimum_size = Vector2(0, 56)
	var h := hbox(4)
	bar.add_child(h)
	if back_cb.is_valid():
		h.add_child(icon_button("back", back_cb, 44))
	else:
		h.add_child(spacer(0, 10))
	var tv := vbox(0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := label(title, 20 if subtitle == "" else 18)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.name = "Title"
	tv.add_child(t)
	if subtitle != "":
		var st := label(subtitle, 12, "faint")
		st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tv.add_child(st)
	h.add_child(tv)
	for e in extra:
		h.add_child(e)
	return bar


static func tabs(names: Array, current: int, cb: Callable) -> Control:
	var h := hbox(0)
	for i in names.size():
		var b := button(names[i], func(): cb.call(i), 14, "accent" if i == current else "dim")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		if i == current:
			var under := StyleBoxFlat.new()
			under.bg_color = Color(0, 0, 0, 0)
			under.border_color = c("accent")
			under.border_width_bottom = 2
			b.add_theme_stylebox_override("normal", under)
		h.add_child(b)
	return h


static func empty_state(text: String, glyph_name := "") -> Control:
	var v := vbox(12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if glyph_name != "":
		var g := glyph(glyph_name, 48, "faint")
		g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(g)
	var l := label(text, 15, "faint", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return v


## Lowercase, strip accents and punctuation: for search, sorting and passwords.
static func norm(s: String, strip_spaces := false) -> String:
	var t := s.to_lower().strip_edges()
	var rep := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c", "\"": "", "?": "", "!": "", ",": " ", ".": " "}
	for k in rep:
		t = t.replace(k, rep[k])
	if strip_spaces:
		for k in [" ", "-", "/"]:
			t = t.replace(k, "")
		return t
	while t.contains("  "):
		t = t.replace("  ", " ")
	return t.strip_edges()


static func clear(n: Node) -> void:
	for ch in n.get_children():
		n.remove_child(ch)
		ch.queue_free()


## Last-resort help after many wrong passwords: length and first letter.
static func password_nudge(pw: String) -> String:
	if pw == "":
		return ""
	return "(%d caracteres, começa por \"%s\")" % [pw.length(), pw.substr(0, 1)]
