extends PhoneApp
## Messages: conversation list and conversation view with reply choices.

const BUBBLE_MAX := 290.0

var _root: VBoxContainer
var _thread := ""
var _list_box: VBoxContainer
var _msgs_box: VBoxContainer
var _msgs_scroll: ScrollContainer
var _choice_box: VBoxContainer
var _input: Label
var _typing_row: Control
var _typing_who := {}     # thread -> who currently typing
var _last_day := -1
var _autotype_tween: Tween
var _fresh_id := ""   # message that just arrived: its bubble pops in


func build() -> void:
	_root = content_root()
	Events.message_added.connect(_on_message_added)
	Events.message_changed.connect(_on_message_changed)
	Events.thread_typing.connect(_on_typing)
	Events.choice_offered.connect(_on_choice_offered)
	Events.choice_offered.connect(func(_t): if _thread == "": _fill_list())
	Events.choice_cleared.connect(_on_choice_cleared)
	Events.autotype_requested.connect(_on_autotype)
	Events.content_changed.connect(func(k): if k == "threads" and _thread == "": _show_list())
	# a contact renamed while its conversation is open (the header shows the name)
	Events.content_changed.connect(func(k): if k == "contacts" and _thread != "": _open_thread(_thread))
	var th: String = params.get("thread", params.get("param", ""))
	if th != "" and GameState.data.threads.has(th):
		_open_thread(th)
	else:
		_show_list()


func reopen(p: Dictionary) -> void:
	params = p
	var th: String = p.get("thread", p.get("param", ""))
	if th != "" and GameState.data.threads.has(th):
		_open_thread(th)


func on_back() -> bool:
	if _thread != "":
		slide(false)
		_show_list()
		return true
	return false


func wants_banner(n: Dictionary) -> bool:
	return not (n.get("app", "") == "messages" and n.get("thread", "") == _thread and _thread != "")


# ================================================================ list
func _show_list() -> void:
	_thread = ""
	GameState.current_app = "messages"
	UI.clear(_root)
	_root.add_child(UI.header("Mensagens", Callable()))
	var sc := UI.scroll()
	_list_box = UI.vbox(0)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list_box)
	_root.add_child(sc)
	_fill_list()


func _fill_list() -> void:
	if _list_box == null or not is_instance_valid(_list_box):
		return
	UI.clear(_list_box)
	var shown := 0
	for th_id in GameState.data.thread_order:
		if GameState.data.hidden_threads.has(th_id):
			continue
		var th: Dictionary = GameState.data.threads.get(th_id, {})
		var msgs: Array = th.get("messages", [])
		if msgs.is_empty():
			continue
		_list_box.add_child(_thread_row(th_id, msgs[-1], int(th.unread)))
		shown += 1
	if shown == 0:
		_list_box.add_child(UI.empty_state("Sem conversas.", "messages"))


func _thread_row(th_id: String, last: Dictionary, unread: int) -> Control:
	var h := UI.hbox(12)
	h.add_child(UI.avatar(th_id, 46))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UI.hbox(6)
	var name := UI.label(GameState.contact_name(th_id), 16, "text")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(name)
	top.add_child(UI.label(Clock.fmt_relative(float(last.t)), 12, "accent" if unread > 0 else "faint"))
	v.add_child(top)
	var bottom := UI.hbox(6)
	var preview := ""
	if _typing_who.has(th_id):
		preview = "a escrever…"
	else:
		preview = _preview(last, th_id)
	var waiting: bool = GameState.data.choices.has(th_id) and not _typing_who.has(th_id)
	if waiting and unread == 0:
		preview = "À espera da tua resposta"
	var pl := UI.label(preview, 14, "accent" if (_typing_who.has(th_id) or (waiting and unread == 0)) else ("text" if unread > 0 else "dim"))
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bottom.add_child(pl)
	if unread > 0:
		var badge := UI.panel(UI.c("accent").darkened(0.15), 10, 7, 1, 7, 1)
		badge.add_child(UI.label(str(unread), 12, "bg"))
		bottom.add_child(badge)
	v.add_child(bottom)
	h.add_child(v)
	return UI.row(h, func(): slide(); _open_thread(th_id), 72)


func _preview(m: Dictionary, th_id := "") -> String:
	if m.get("del", false):
		return "Esta mensagem foi apagada"
	var prefix := "Tu: " if m.get("from", "") == "me" else ""
	if prefix == "" and Content.character(th_id).get("group", false):
		prefix = GameState.contact_name(m.from) + ": "
	if m.has("att"):
		match m.att.type:
			"photo": return prefix + "Fotografia" + ("" if str(m.text) == "" else " · " + m.text)
			"audio": return prefix + "Mensagem de voz"
			"file": return prefix + "Ficheiro"
	return prefix + str(m.text).replace("\n", " ")


# ================================================================ thread
func _open_thread(th_id: String) -> void:
	_thread = th_id
	GameState.current_app = "messages:" + th_id
	GameState.mark_read(th_id)
	GameState.clear_notifications("messages")
	Events.thread_read.emit(th_id)
	UI.clear(_root)
	var c := GameState.contact(th_id)
	var call_b := UI.icon_button("call", func(): if not c.get("group", false): Director.player_call(th_id), 40, "dim")
	call_b.tooltip_text = "Ligar"
	call_b.visible = not c.get("group", false)
	var info_b := UI.icon_button("info", func(): phone.open_app("contacts", {"param": th_id}), 40, "dim")
	info_b.visible = c.get("saved", false) and not c.get("group", false)
	var sub_txt := ""
	if c.get("group", false):
		sub_txt = ", ".join(PackedStringArray(c.get("members", []).map(func(m): return GameState.contact_name(m))))
	elif c.get("saved", false):
		sub_txt = str(c.get("number", ""))
	var head := UI.header(GameState.contact_name(th_id), _show_list, [call_b, info_b], sub_txt)
	_root.add_child(head)
	_root.add_child(UI.separator())
	_msgs_scroll = UI.scroll()
	var m := UI.margin(10, 8, 10, 8)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msgs_box = UI.vbox(4)
	_msgs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(_msgs_box)
	_msgs_scroll.add_child(m)
	_root.add_child(_msgs_scroll)
	_choice_box = UI.vbox(6)
	var cm := UI.margin(10, 4, 10, 2)
	cm.add_child(_choice_box)
	_root.add_child(cm)
	_root.add_child(_input_bar())
	_render_messages()
	_render_choices()
	Director.notify_player_action()


func _input_bar() -> Control:
	var p := UI.panel(UI.c("bg"), 0, 10, 6, 10, 8)
	var h := UI.hbox(8)
	p.add_child(h)
	var field := UI.panel(UI.c("surf2"), 20, 16, 10, 16, 10)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input = UI.label("Mensagem", 15, "faint")
	_input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field.add_child(_input)
	h.add_child(field)
	var send := UI.icon_button("send", func():
		if not GameState.data.choices.has(_thread):
			phone.toast("Não sabes o que escrever."), 42, "accent")
	h.add_child(send)
	return p


func _render_messages() -> void:
	UI.clear(_msgs_box)
	_last_day = -1
	var th: Dictionary = GameState.data.threads.get(_thread, {})
	var msgs: Array = th.get("messages", [])
	var last_me := -1
	for i in msgs.size():
		if msgs[i].get("from", "") == "me":
			last_me = i
	var prev_from := ""
	for i in msgs.size():
		var msg: Dictionary = msgs[i]
		_add_day_separator(float(msg.t))
		var bub := _bubble(msg, msg.get("from", "") != prev_from)
		_msgs_box.add_child(bub)
		if _fresh_id != "" and str(msg.get("id", "")) == _fresh_id:
			_pop_in(bub, msg.get("from", "") == "me")
		prev_from = msg.get("from", "")
		if i == last_me and i == msgs.size() - 1:
			var status := str(msg.get("status", "Entregue"))
			if _thread == "unknown" and not msg.has("status"):
				# whatever reads these messages, it always reads them at the same time
				status = "Lida · 03:17"
			var st := UI.label(status, 11, "faint")
			st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_msgs_box.add_child(st)
	_typing_row = _typing_bubble()
	_typing_row.visible = _typing_who.has(_thread)
	_msgs_box.add_child(_typing_row)
	_scroll_to_end()


func _pop_in(bub: Control, mine: bool) -> void:
	if not UI.motion_ok():
		return
	bub.modulate.a = 0.0
	var tw := bub.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bub, "modulate:a", 1.0, UI.T_SCREEN * 0.8)
	tw.tween_method(func(k: float):
		bub.pivot_offset = Vector2(bub.size.x if mine else 0.0, bub.size.y)
		bub.scale = Vector2.ONE * lerpf(0.92, 1.0, k), 0.0, 1.0, UI.T_SCREEN)


func _add_day_separator(t: float) -> void:
	var day := floori(t / 86400.0)
	if day == _last_day:
		return
	_last_day = day
	var now_day := floori(Clock.now() / 86400.0)
	var txt := ""
	if day == now_day:
		txt = "Hoje"
	elif day == now_day - 1:
		txt = "Ontem"
	elif day > now_day:
		txt = Clock.fmt_date_long(t)
	else:
		txt = Clock.fmt_date_long(t)
	var l := UI.label(txt, 12, "faint")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m := UI.margin(0, 10, 0, 6)
	m.add_child(l)
	_msgs_box.add_child(m)


func _bubble(msg: Dictionary, first_of_group: bool) -> Control:
	var me: bool = msg.get("from", "") == "me"
	var row := UI.hbox(0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if me:
		row.add_child(UI.expand())
	var col := UI.vbox(2)
	var is_group: bool = Content.character(_thread).get("group", false)
	if is_group and not me and first_of_group:
		var nm := UI.label(GameState.contact_name(msg.from), 12, "accent")
		col.add_child(nm)
	var deleted: bool = msg.get("del", false)
	var bg := UI.c("me") if me else UI.c("them")
	if deleted:
		bg = Color(0, 0, 0, 0)
	var p := PanelContainer.new()
	var sb := UI.box(bg, 16)
	if deleted:
		sb.border_color = UI.c("line")
		sb.set_border_width_all(1)
	if me:
		sb.corner_radius_bottom_right = 4
	else:
		sb.corner_radius_bottom_left = 4
	p.add_theme_stylebox_override("panel", UI.pad(sb, 12, 8, 12, 6))
	var inner := UI.vbox(4)
	p.add_child(inner)
	if deleted:
		var dl := UI.label("Esta mensagem foi apagada", 14, "faint")
		inner.add_child(dl)
	else:
		if msg.has("att"):
			inner.add_child(_attachment(msg.att))
		if str(msg.text) != "":
			inner.add_child(_text_label(str(msg.text)))
	var tl := UI.label(Clock.fmt_time(float(msg.t)), 10, "faint")
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(tl)
	col.add_child(p)
	row.add_child(col)
	if not me:
		row.add_child(UI.expand())
	var m := UI.margin(0, 4 if first_of_group else 0, 0, 0)
	m.add_child(row)
	return m


func _text_label(text: String) -> Label:
	var l := UI.label(text, 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font := ThemeDB.fallback_font
	var fsz := UI.fs(16)
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x)
	l.custom_minimum_size.x = minf(w + 4.0, BUBBLE_MAX)
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	return l


func _attachment(att: Dictionary) -> Control:
	match att.get("type", ""):
		"photo":
			var holder := Button.new()
			holder.custom_minimum_size = Vector2(210, 270)
			holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var pv := PhotoView.new()
			pv.set_anchors_preset(Control.PRESET_FULL_RECT)
			pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(pv)
			pv.set_photo(att.id)
			holder.pressed.connect(func(): phone.open_app("gallery", {"photo": att.id, "from_thread": _thread}))
			UI.press_fx(holder, 0.97)
			return holder
		"audio":
			var vm := Content.get_item("voicemails", att.id)
			var h := UI.hbox(10)
			var play := UI.icon_button("play", func(): _play_audio(att.id), 36, "text")
			h.add_child(play)
			h.add_child(UI.glyph("wave", 80, "dim"))
			h.add_child(UI.label(str(vm.get("duration", "0:07")), 12, "dim"))
			return h
		"link":
			var page := Content.get_item("pages", att.id)
			var card := UI.vbox(2)
			card.add_child(UI.label(str(page.get("title", att.id)), 14, "link"))
			card.add_child(UI.label(str(page.get("url", "")), 11, "faint"))
			var b := UI.row(card, func(): phone.open_app("browser", {"page": att.id}), 52)
			b.add_theme_stylebox_override("normal", UI.box(Color(0, 0, 0, 0.18), 10))
			b.custom_minimum_size.x = 240
			return b
		"file":
			var f := Content.get_item("files", att.id)
			var fh := UI.hbox(10)
			fh.add_child(UI.glyph("doc", 26, "dim"))
			var fv := UI.vbox(0)
			fv.add_child(UI.label(str(f.get("name", att.id)), 14))
			fv.add_child(UI.label(str(f.get("size", "")), 11, "faint"))
			fh.add_child(fv)
			var fb := UI.row(fh, func():
				if not GameState.data.files.has(att.id):
					GameState.data.files.append(att.id)
					Events.content_changed.emit("files")
				phone.open_app("files", {"file": att.id}), 52)
			fb.custom_minimum_size.x = 240
			fb.add_theme_stylebox_override("normal", UI.box(Color(0, 0, 0, 0.18), 10))
			return fb
	return UI.label("[anexo]", 13, "faint")


func _play_audio(vm_id: String) -> void:
	var vm := Content.get_item("voicemails", vm_id)
	var sheet := AudioSheet.new()
	sheet.setup(vm_id, vm)
	add_child(sheet)


func _typing_bubble() -> Control:
	var row := UI.hbox(0)
	var p := UI.panel(UI.c("them"), 16, 14, 10, 14, 10)
	var dots := TypingDots.new()
	dots.custom_minimum_size = Vector2(40, 14)
	p.add_child(dots)
	row.add_child(p)
	row.add_child(UI.expand())
	return row


func _scroll_to_end() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_msgs_scroll):
		_msgs_scroll.scroll_vertical = int(_msgs_scroll.get_v_scroll_bar().max_value)


# ================================================================ choices
func _render_choices() -> void:
	if _choice_box == null or not is_instance_valid(_choice_box):
		return
	UI.clear(_choice_box)
	var pending: Dictionary = GameState.data.choices.get(_thread, {})
	if pending.is_empty():
		_input.text = "Mensagem"
		_input.add_theme_color_override("font_color", UI.c("faint"))
		return
	for opt in pending.options:
		var text: String = opt.text
		var silent := text.begins_with("[") and text.ends_with("]")
		var b := UI.wrap_button(text.substr(1, text.length() - 2) if silent else text, func(): _choose(opt.index), UI.SCREEN.x - 20, 15, "surf2", "dim" if silent else "text", silent)
		_choice_box.add_child(b)
	_input.text = "Escolhe uma resposta"
	_input.add_theme_color_override("font_color", UI.c("faint"))
	if _choice_box.get_child_count() > 0:
		_choice_box.get_child(0).call_deferred("grab_focus")


func _choose(index: int) -> void:
	UI.clear(_choice_box)
	Clock.notify_activity()
	Director.pick_choice(_thread, index)


func _on_choice_offered(th: String) -> void:
	if th == _thread:
		_render_choices()
		_scroll_to_end()


func _on_choice_cleared(th: String) -> void:
	if th == _thread:
		_render_choices()


func _on_autotype(th: String, text: String) -> void:
	if th != _thread or _input == null or not is_instance_valid(_input):
		return
	if _autotype_tween:
		_autotype_tween.kill()
	_input.add_theme_color_override("font_color", UI.c("text"))
	_input.text = ""
	var total := minf(0.4 + text.length() * 0.03, 2.2) / clampf(float(Settings.get_value("text_speed", 1.0)), 0.25, 4.0)
	_autotype_tween = create_tween()
	_autotype_tween.tween_method(func(v: float):
		var n := int(v)
		if n > _input.text.length():
			Audio.key_click()
		_input.text = text.substr(0, n), 0.0, float(text.length()), total * 0.9)


# ================================================================ live updates
func _on_message_added(th: String, msg: Dictionary) -> void:
	if _thread == "":
		_fill_list()
		return
	if th != _thread:
		return
	GameState.mark_read(th)
	Events.thread_read.emit(th)
	if msg.get("from", "") == "me" and _input and is_instance_valid(_input):
		_input.text = "Mensagem"
		_input.add_theme_color_override("font_color", UI.c("faint"))
	# backdated inserts need a full re-render to keep chronology
	_fresh_id = str(msg.get("id", ""))
	_render_messages()
	_fresh_id = ""
	if msg.get("from", "") != "me":
		Audio.play("msg", -14.0)


func _on_message_changed(th: String, _id: String) -> void:
	if th == _thread:
		_render_messages()
	elif _thread == "":
		_fill_list()


func _on_typing(th: String, who: String, typing: bool) -> void:
	if typing:
		_typing_who[th] = who
	else:
		_typing_who.erase(th)
	if _thread == "":
		_fill_list()
	elif th == _thread and is_instance_valid(_typing_row):
		_typing_row.visible = typing
		if typing:
			_scroll_to_end()


class TypingDots extends Control:
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var a := 0.3 + 0.7 * maxf(0.0, sin(_t * 5.0 - i * 0.9))
			draw_circle(Vector2(8 + i * 12, size.y / 2), 4, Color(1, 1, 1, a))


class AudioSheet extends Control:
	## Bottom sheet that "plays" a voice message with a transcript.
	func setup(vm_id: String, vm: Dictionary) -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.6)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: queue_free())
		add_child(dim)
		var p := UI.panel(UI.c("surf"), 18, 20, 18, 20, 30)
		p.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		p.offset_top = -340
		add_child(p)
		var v := UI.vbox(10)
		p.add_child(v)
		v.add_child(UI.label(str(vm.get("title", "Mensagem de voz")), 17))
		var sc := UI.scroll()
		var lines := UI.vbox(8)
		lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(lines)
		v.add_child(sc)
		v.add_child(UI.pill_button("Fechar", queue_free, "surf2"))
		_play(vm_id, vm, lines)

	func _play(vm_id: String, vm: Dictionary, box: VBoxContainer) -> void:
		GameState.data.files_opened["vm_" + vm_id] = true
		Director.notify_player_action()
		for sfx in vm.get("sfx", []):
			Audio.play(sfx, -6.0)
		for line in vm.get("lines", []):
			if not is_inside_tree():
				return
			var l := UI.label(str(line), 15, "text", true)
			if str(line).begins_with("["):
				l.add_theme_color_override("font_color", UI.c("faint"))
				if not Settings.get_value("sound_captions", false) and not Settings.get_value("subtitles", true):
					continue
			box.add_child(l)
			await get_tree().create_timer(1.0 + str(line).length() * 0.045).timeout
		for c in vm.get("clues", []):
			Director.add_clue(c)
