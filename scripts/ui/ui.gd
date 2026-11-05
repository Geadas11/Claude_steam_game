class_name UI
extends RefCounted
## UI construction helpers and the "Lumen OS" visual identity.

const SCREEN := Vector2(420, 880)

## Graphite, frosted glass and one warm light (the "lumen"): champagne gold.
const PALETTE := {
	"bg": Color("09090b"),
	"surf": Color("141518"),
	"surf2": Color("1e1f23"),
	"line": Color("2a2b30"),
	"text": Color("f4f2ee"),
	"dim": Color("a4a6ad"),
	"faint": Color("7c7f87"),
	"accent": Color("e4bd7c"),
	"me": Color("8e6631"),
	"them": Color("1f2024"),
	"danger": Color("ff6b6b"),
	"ok": Color("5fd39b"),
	"link": Color("9ec4ff"),
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
		# the weights Inter has here, thinned or thickened: light for the big
		# clock, bold for large titles, and tight tracking for both
		if _fonts.has("regular") and _fonts.has("semibold"):
			_fonts["light"] = _variant(_fonts.regular, -0.45, -1)
			_fonts["display"] = _variant(_fonts.regular, -0.6, -3)
			_fonts["bold"] = _variant(_fonts.semibold, 0.3, -1)
	return _fonts.get(weight, ThemeDB.fallback_font)


static func _variant(base: Font, embolden: float, spacing: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_embolden = embolden
	v.spacing_glyph = spacing
	return v


# ------------------------------------------------------------------ motion
## Shared timings (seconds). Everything that moves uses these so the whole
## phone feels like one system; "reduce_motion" turns them off.
const T_PRESS := 0.09      # finger down
const T_RELEASE := 0.16    # finger up (slightly slower, springy)
const T_SCREEN := 0.2      # app / screen in and out
const T_OPEN := 0.42       # an app growing out of its icon (expo ease: fast, long soft tail)


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


# ------------------------------------------------------------------ glass
const R_CARD := 20         # cards, sheets, grouped lists
const R_CONTROL := 14      # inputs, small cards
const R_PILL := 999        # pill buttons, chips

static var _glass_mats := {}


## Glass is off when the player wants plain, high-contrast panels.
static func glass_ok() -> bool:
	return not Settings.get_value("high_contrast", false)


## A frosted-glass PanelContainer: what's behind it shows through, blurred.
## kind: "regular" (cards, dock), "thick" (sheets, banners), "thin" (bars).
static func glass(radius := R_CARD, l := 0, t := 0, r := 0, b := 0, kind := "regular") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", glass_box(radius, l, t, r, b, kind))
	if glass_ok():
		p.material = glass_material(kind)
	return p


static func glass_box(radius := R_CARD, l := 0, t := 0, r := 0, b := 0, kind := "regular") -> StyleBoxFlat:
	var tint := _glass_tint(kind)
	if not glass_ok():
		return pad(box(c("surf2"), radius, c("line"), 1), l, t, r, b) as StyleBoxFlat
	var s := box(Color(tint, 1.0), radius)
	# a hairline of light along the top edge, as on real glass
	s.border_color = Color(tint.r + 0.09, tint.g + 0.09, tint.b + 0.1)
	s.border_width_top = 1
	return pad(s, l, t, r, b) as StyleBoxFlat


static func _glass_tint(kind: String) -> Color:
	match kind:
		"thick": return Color(0.075, 0.078, 0.09)
		"heavy": return Color(0.04, 0.042, 0.05)
		"thin": return Color(0.06, 0.062, 0.07)
	return Color(0.11, 0.115, 0.13)


static func glass_material(kind := "regular") -> ShaderMaterial:
	if _glass_mats.has(kind):
		return _glass_mats[kind]
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/ui/glass.gdshader")
	m.set_shader_parameter("tint", _glass_tint(kind))
	m.set_shader_parameter("tint_amount", {"thick": 0.72, "thin": 0.6, "heavy": 0.62}.get(kind, 0.5))
	m.set_shader_parameter("blur", {"thick": 3.6, "thin": 3.0, "heavy": 5.0}.get(kind, 3.3))
	_glass_mats[kind] = m
	return m


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
	var le := box(c("surf2"), 20)
	le.content_margin_left = 16
	le.content_margin_right = 16
	le.content_margin_top = 10
	le.content_margin_bottom = 10
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = Color(c("accent"), 0.55)
	lef.set_border_width_all(1)
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_color("font_color", "LineEdit", c("text"))
	t.set_color("font_placeholder_color", "LineEdit", c("faint"))
	t.set_color("caret_color", "LineEdit", c("accent"))
	t.set_stylebox("normal", "TextEdit", le)
	t.set_stylebox("focus", "TextEdit", lef)
	t.set_color("font_color", "TextEdit", c("text"))
	# thin scrollbars
	var grab := box(Color(1, 1, 1, 0.14), 3)
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
	# switches: a pill track and a round knob, drawn once
	t.set_icon("checked", "CheckButton", _switch_tex(true))
	t.set_icon("unchecked", "CheckButton", _switch_tex(false))
	t.set_icon("checked_disabled", "CheckButton", _switch_tex(true))
	t.set_icon("unchecked_disabled", "CheckButton", _switch_tex(false))
	t.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "CheckButton", StyleBoxEmpty.new())
	# sliders / checkboxes in menus
	var slider := box(c("line"), 3)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", box(c("accent").darkened(0.2), 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(c("accent"), 3))
	return t


static var _switches := {}


static func _switch_tex(on: bool) -> Texture2D:
	if _switches.has(on):
		return _switches[on]
	var w := 52
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := c("ok") if on else Color(1, 1, 1, 0.16)
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			# distance to the pill's centre line, then to the knob
			var q := Vector2(clampf(p.x, h / 2.0, w - h / 2.0), h / 2.0)
			var dt := p.distance_to(q) - h / 2.0
			var dk := p.distance_to(Vector2(knob_x, h / 2.0)) - (h / 2.0 - 2.5)
			var col := Color(track, track.a * clampf(0.5 - dt, 0.0, 1.0))
			var ka := clampf(0.5 - dk, 0.0, 1.0)
			col = col.blend(Color(1, 1, 1, ka))
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_switches[on] = tex
	return tex


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
	# hierarchy by weight, like a phone OS: huge numbers light, large titles
	# bold, titles semibold, subheads medium
	if size >= 48:
		l.add_theme_font_override("font", font("display"))
	elif size >= 26:
		l.add_theme_font_override("font", font("bold"))
	elif size >= 20:
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
	var n := pad(box(c(bg_key), 22), 18, 10, 18, 10)
	var h := pad(box(c(bg_key).lightened(0.08), 22), 18, 10, 18, 10)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", pad(box(Color(0, 0, 0, 0), 22, c("accent"), 1), 18, 10, 18, 10))
	if bg_key == "accent":
		b.add_theme_color_override("font_color", c("bg"))
		b.add_theme_color_override("font_hover_color", c("bg"))
		b.add_theme_color_override("font_pressed_color", c("bg"))
		b.add_theme_font_override("font", font("semibold"))
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
	r.color = Color(1, 1, 1, 0.07) if glass_ok() else c("line")
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A rounded inset card for grouped lists (settings, details): returns the
## VBox to add rows to; the card is added to `parent` with page margins.
static func group(parent: Control, title := "") -> VBoxContainer:
	if title != "":
		var tm := margin(30, 6, 30, 6)
		var tl := label(title.to_upper(), 12, "faint")
		tl.add_theme_font_override("font", font("medium"))
		tm.add_child(tl)
		parent.add_child(tm)
	var card := panel(c("surf"), R_CARD, 0, 4, 0, 4)
	var v := vbox(0)
	card.add_child(v)
	var m := margin(16, 0, 16, 18)
	m.add_child(card)
	parent.add_child(m)
	return v


## A glyph on a small coloured rounded tile (settings rows, file types).
static func tile_glyph(name: String, col: Color, size := 32) -> Control:
	var p := panel(col, int(size * 0.28))
	p.custom_minimum_size = Vector2(size, size)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := glyph(name, int(size * 0.92), "text")
	g.color = Color.WHITE
	p.add_child(g)
	return p


## A round tile with the first letters of a name, its colour taken from
## the name (mail senders, files: people who aren't contacts).
static func initials(who: String, size := 40) -> Control:
	var words := who.replace("—", " ").replace("·", " ").split(" ", false)
	var txt := ""
	for w in words:
		if txt.length() < 2 and w.length() > 0 and w[0] == w[0].to_upper() and w[0] != w[0].to_lower():
			txt += w[0]
	if txt == "":
		txt = who.left(1).to_upper()
	var hues := [0.02, 0.08, 0.13, 0.36, 0.5, 0.58, 0.66, 0.75, 0.88]
	var col := Color.from_hsv(hues[absi(who.hash()) % hues.size()], 0.45, 0.62)
	var p := panel(col, int(size / 2.0))
	p.custom_minimum_size = Vector2(size, size)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := label(txt, int(size * 0.36))
	l.add_theme_font_override("font", font("semibold"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


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
## The top level of an app (no back button) gets a large bold title, as on
## modern phones; screens inside it get a compact one next to the chevron.
static func header(title: String, back_cb: Callable, extra: Array = [], subtitle := "") -> Control:
	var large := not back_cb.is_valid() and subtitle == ""
	var bar := panel(c("bg"), 0, 6, 8 if large else 4, 10, 4)
	bar.custom_minimum_size = Vector2(0, 64 if large else 56)
	var h := hbox(4)
	bar.add_child(h)
	if back_cb.is_valid():
		var bb := icon_button("back", back_cb, 44, "accent")
		h.add_child(bb)
	else:
		h.add_child(spacer(0, 12))
	var tv := vbox(0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := label(title, 30 if large else (19 if subtitle == "" else 17))
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


## A segmented control: a pill track with the chosen segment raised.
static func tabs(names: Array, current: int, cb: Callable) -> Control:
	var track := panel(c("surf2"), 12, 3, 3, 3, 3)
	var h := hbox(2)
	track.add_child(h)
	for i in names.size():
		var b := button(names[i], func(): cb.call(i), 14, "text" if i == current else "dim")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		if i == current:
			var on := box(Color("3a3b41"), 10)
			on.shadow_color = Color(0, 0, 0, 0.35)
			on.shadow_size = 4
			b.add_theme_stylebox_override("normal", on)
			b.add_theme_stylebox_override("hover", on)
			b.add_theme_font_override("font", font("semibold"))
		h.add_child(b)
	var m := margin(14, 6, 14, 6)
	m.add_child(track)
	return m


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
