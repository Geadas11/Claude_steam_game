class_name PauseMenu
extends Control
## In-game pause menu (Esc). Pauses the clock and the narrative.

var main: Node


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP


func open() -> void:
	UI.clear(self)
	visible = true
	get_tree().paused = true
	Events.game_paused.emit(true)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var m := UI.margin(110, 0, 0, 0)
	m.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	m.offset_right = 600
	add_child(m)
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)
	v.add_child(UI.label("Pausa", 34))
	var info := "%s · %s %s" % [Content.chapter_title(GameState.data.chapter), Clock.fmt_date_long(Clock.now()), Clock.fmt_time(Clock.now())]
	if Coop.active:
		info += "\nJogo online · és " + ("o Daniel" if Coop.is_host else "a Sofia") + (" · o tempo para para os dois" if Coop.is_host else " · o tempo continua para o Daniel")
	v.add_child(UI.label(info, 14, "faint"))
	v.add_child(UI.spacer(30))
	var c := MenuPanel.menu_button("Continuar", close)
	v.add_child(c)
	c.call_deferred("grab_focus")
	# co-op: only the host keeps saves, and nobody loads mid-session
	if not Coop.active or Coop.is_host:
		v.add_child(MenuPanel.menu_button("Guardar", func():
			var p := SlotsPanel.new()
			p.saving = true
			p.main = main
			add_child(p)))
	if not Coop.active:
		v.add_child(MenuPanel.menu_button("Carregar", func():
			var p := SlotsPanel.new()
			p.main = main
			add_child(p)))
	v.add_child(MenuPanel.menu_button("Telemóvel real", func(): add_child(CompanionPanel.new())))
	v.add_child(MenuPanel.menu_button("Até agora", func(): add_child(RecapPanel.new())))
	v.add_child(MenuPanel.menu_button("Decisões", func(): add_child(ChoicesPanel.new())))
	v.add_child(MenuPanel.menu_button("Definições", func(): add_child(SettingsPanel.new())))
	v.add_child(MenuPanel.menu_button("Sair do jogo online" if Coop.active else "Menu principal", func():
		Saves.autosave()
		close()
		main.show_title()))
	v.add_child(MenuPanel.menu_button("Sair do jogo", func():
		Saves.autosave()
		get_tree().quit()))
	v.add_child(UI.spacer(30))
	v.add_child(UI.label("O progresso é guardado automaticamente no início de cada capítulo e em momentos importantes.", 12, "faint", true))


func close() -> void:
	visible = false
	UI.clear(self)
	get_tree().paused = false
	Events.game_paused.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause_menu"):
		# panels opened from here close themselves first
		for ch in get_children():
			if ch is MenuPanel:
				return
		close()
		get_viewport().set_input_as_handled()
