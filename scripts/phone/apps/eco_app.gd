extends PhoneApp
## ECO console: the hidden app. A terminal view over the "eco" thread.

var _box: VBoxContainer
var _scroll: ScrollContainer
var _choices: VBoxContainer
var _cursor: Label
var _t := 0.0


func build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("020303")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := content_root()
	var head := UI.label("  eco.console  ·  sim #047  ·  ligação local", 12, "ok")
	head.custom_minimum_size = Vector2(0, 34)
	head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(head)
	v.add_child(UI.separator())
	_scroll = UI.scroll()
	var m := UI.margin(14, 10, 14, 10)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box = UI.vbox(8)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(_box)
	_scroll.add_child(m)
	v.add_child(_scroll)
	_choices = UI.vbox(6)
	var cm := UI.margin(12, 6, 12, 10)
	cm.add_child(_choices)
	v.add_child(cm)
	Events.message_added.connect(func(th, _m): if th == "eco": _render())
	Events.choice_offered.connect(func(th): if th == "eco": _render())
	Events.choice_cleared.connect(func(th): if th == "eco": _render())
	Events.thread_typing.connect(func(th, _w, on): if th == "eco" and _cursor: _cursor.text = "> a processar…" if on else "> _")
	GameState.ensure_thread("eco")
	GameState.mark_read("eco")
	GameState.set_var("opened_eco", true)
	Director.notify_player_action()
	_render()


func _render() -> void:
	UI.clear(_box)
	for msg in GameState.data.threads.get("eco", {}).get("messages", []):
		var me: bool = msg.get("from", "") == "me"
		var l := UI.label(("> " if me else "") + str(msg.text), 14, "dim" if me else "ok", true)
		_box.add_child(l)
	_cursor = UI.label("> _", 14, "ok")
	_box.add_child(_cursor)
	GameState.mark_read("eco")
	UI.clear(_choices)
	var pending: Dictionary = GameState.data.choices.get("eco", {})
	for opt in pending.get("options", []):
		var t: String = opt.text
		var b := UI.wrap_button("> " + t.trim_prefix("[").trim_suffix("]"), func():
			UI.clear(_choices)
			Director.pick_choice("eco", opt.index), UI.SCREEN.x - 24, 14, "bg", "ok", true)
		_choices.add_child(b)
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _process(d: float) -> void:
	_t += d
	if _cursor and is_instance_valid(_cursor) and (_cursor.text == "> _" or _cursor.text == "> "):
		_cursor.text = "> _" if fmod(_t, 1.0) < 0.5 else "> "


func wants_banner(n: Dictionary) -> bool:
	return n.get("thread", "") != "eco"
