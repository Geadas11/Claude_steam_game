class_name TitleMenu
extends Control
## Title screen. The phone lies on the desk, locked; the menu is to its left.

var main: Node
var _col: VBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open() -> void:
	visible = true
	UI.clear(self)
	var m := UI.margin(110, 0, 0, 0)
	m.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	m.offset_right = 620
	add_child(m)
	_col = UI.vbox(6)
	_col.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(_col)
	var t := UI.label("Ainda estás acordado?", 40)
	_col.add_child(t)
	var sub := UI.label("um thriller num telemóvel", 16, "faint")
	_col.add_child(sub)
	_col.add_child(UI.spacer(40))
	var latest := Saves.latest_slot()
	if latest != "":
		var b := MenuPanel.menu_button("Continuar", func(): main.continue_game(latest))
		_col.add_child(b)
		b.call_deferred("grab_focus")
		var sm := Saves.slot_meta(latest)
		if not sm.is_empty():
			var pt := int(sm.get("playtime", 0))
			var info := UI.label("%s · %s · %dh%02d de jogo" % [sm.get("chapter_title", ""), Clock.fmt_time(float(sm.get("game_time", 0))), pt / 3600, (pt / 60) % 60], 12, "faint")
			_col.add_child(info)
	var nb := MenuPanel.menu_button("Novo jogo", _new_game)
	_col.add_child(nb)
	if latest == "":
		nb.call_deferred("grab_focus")
	_col.add_child(MenuPanel.menu_button("Carregar", func():
		var p := SlotsPanel.new()
		p.main = main
		add_child(p)))
	_col.add_child(MenuPanel.menu_button("Definições", func(): add_child(SettingsPanel.new())))
	_col.add_child(MenuPanel.menu_button("Extras", func(): add_child(ExtrasPanel.new())))
	_col.add_child(MenuPanel.menu_button("Sair", func(): get_tree().quit()))
	_col.add_child(UI.spacer(60))
	var foot := UI.label("v%s · Este jogo não acede à tua câmara, microfone, ficheiros ou localização.\nTudo o que vês acontece apenas dentro do telemóvel do jogo." % ProjectSettings.get_setting("application/config/version", "0.1"), 12, "faint")
	_col.add_child(foot)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)


func _new_game() -> void:
	if Settings.get_value("seen_warning", false):
		_confirm_overwrite()
		return
	var w := MenuPanel.new()
	add_child(w)
	w.make("Antes de começares", 640, true)
	for line in [
		"Ainda Estás Acordado? é um jogo de terror psicológico.",
		"Aborda morte, luto, perda de memória, vigilância, manipulação e menções a suicídio. Contém sons súbitos, cintilação e interferências visuais (podes reduzi-los nas Definições).",
		"Se algum destes temas te toca de perto, há contactos de apoio em Extras → Créditos.",
		"Para a melhor experiência: joga à noite, com auscultadores, sem pressa.",
		"Nada neste jogo acede ao teu computador real. Se em algum momento parecer que sim — é o jogo a fazer o seu trabalho.",
	]:
		w.body.add_child(UI.label(line, 16, "text", true))
	var go := UI.pill_button("Compreendo", func():
		Settings.set_value("seen_warning", true)
		w.queue_free()
		_confirm_overwrite(), "surf2", "accent")
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	w.body.add_child(UI.spacer(8))
	w.body.add_child(go)
	go.call_deferred("grab_focus")


func _confirm_overwrite() -> void:
	if Saves.slot_meta("auto").is_empty():
		main.start_new_game()
		return
	var w := MenuPanel.new()
	add_child(w)
	w.make("Começar de novo?", 560, true)
	var m := Saves.slot_meta("auto")
	w.body.add_child(UI.label("A gravação automática (%s) será substituída. As gravações manuais e as conquistas mantêm-se." % m.get("chapter_title", ""), 16, "text", true))
	var h := UI.hbox(12)
	var yes := UI.pill_button("Começar jogo novo", func():
		w.queue_free()
		main.start_new_game(), "surf2", "accent")
	h.add_child(yes)
	h.add_child(UI.pill_button("Cancelar", w.close, "surf", "dim"))
	w.body.add_child(UI.spacer(8))
	w.body.add_child(h)
	yes.call_deferred("grab_focus")
