class_name SlotsPanel
extends MenuPanel
## Save / load slot list.

var saving := false
var main: Node


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	make("Guardar jogo" if saving else "Carregar jogo", 620)
	var slots: Array = Saves.all_slots()
	for slot in slots:
		if saving and (slot == "auto" or slot == "quick"):
			continue
		var meta := Saves.slot_meta(slot)
		var h := UI.hbox(10)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name := "Gravação automática" if slot == "auto" else ("Gravação rápida" if slot == "quick" else "Espaço %s" % slot)
		v.add_child(UI.label(name, 16, "accent" if slot == "auto" else "text"))
		if meta.is_empty():
			v.add_child(UI.label("Vazio", 13, "faint"))
		else:
			var gt := float(meta.get("game_time", 0))
			var pt := int(meta.get("playtime", 0))
			v.add_child(UI.label("%s · %s %s" % [meta.get("chapter_title", ""), Clock.fmt_date_long(gt), Clock.fmt_time(gt)], 13, "dim"))
			v.add_child(UI.label("Tempo de jogo %dh%02d · guardado %s" % [pt / 3600, (pt / 60) % 60, str(meta.get("saved_at", "")).replace("T", " ")], 12, "faint"))
		h.add_child(v)
		if saving:
			h.add_child(UI.pill_button("Guardar", func(): _save(slot), "surf2", "text", 14))
		elif not meta.is_empty():
			h.add_child(UI.pill_button("Carregar", func(): _load(slot), "surf2", "text", 14))
		if not meta.is_empty() and slot != "auto":
			h.add_child(UI.pill_button("Apagar", func():
				Saves.delete_slot(slot)
				_rebuild(), "surf", "danger", 13))
		var p := UI.panel(Color("15181d"), 10, 14, 10, 14, 10)
		p.add_child(h)
		body.add_child(p)


func _save(slot: String) -> void:
	if Saves.save_to(slot):
		_rebuild()
	else:
		body.add_child(UI.label("Não foi possível guardar: " + Saves.last_error, 13, "danger"))


func _load(slot: String) -> void:
	if main and main.continue_game(slot):
		close()
	else:
		body.add_child(UI.label("Não foi possível carregar: " + Saves.last_error, 13, "danger"))
