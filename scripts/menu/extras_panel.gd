class_name ExtrasPanel
extends MenuPanel
## Achievements and endings found.


func _ready() -> void:
	make("Extras", 660)
	body.add_child(UI.label("FINAIS", 13, "accent"))
	var ends: Dictionary = Content.all("endings")
	for id in ends:
		var e: Dictionary = ends[id]
		var seen := Achievements.ending_seen(id)
		var h := UI.hbox(10)
		h.add_child(UI.label(id, 18, "accent" if seen else "faint"))
		var v := UI.vbox(0)
		v.add_child(UI.label(e.get("name", id) if seen else "???", 16, "text" if seen else "faint"))
		if seen:
			v.add_child(UI.label(e.get("summary", ""), 13, "dim", true))
		elif not Achievements.endings.is_empty() and e.get("how", "") != "":
			# after the first ending, unseen ones get a gentle pointer
			v.add_child(UI.label("Pista: " + str(e.how), 12, "faint", true))
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		body.add_child(h)
	body.add_child(UI.spacer(10))
	var ach: Dictionary = Content.all("achievements")
	var got := 0
	for id in ach:
		if Achievements.is_unlocked(id):
			got += 1
	body.add_child(UI.label("CONQUISTAS  %d / %d" % [got, ach.size()], 13, "accent"))
	for id in ach:
		var a: Dictionary = ach[id]
		var un := Achievements.is_unlocked(id)
		var secret: bool = a.get("secret", false)
		var h2 := UI.hbox(12)
		h2.add_child(UI.glyph("star", 22, "accent" if un else "faint"))
		var v2 := UI.vbox(0)
		v2.add_child(UI.label(a.name if (un or not secret) else "Conquista secreta", 15, "text" if un else "dim"))
		v2.add_child(UI.label(a.desc if (un or not secret) else "Continua a procurar.", 12, "faint", true))
		v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h2.add_child(v2)
		body.add_child(h2)
	_stats()
	_credits()


func _stats() -> void:
	var s: Dictionary = Achievements.stats
	var total_endings := 0
	for k in Achievements.endings:
		total_endings += int(Achievements.endings[k])
	body.add_child(UI.spacer(14))
	body.add_child(UI.label("ESTATÍSTICAS", 13, "accent"))
	for line in [
		"Jogos começados: %d" % int(s.get("games", 0)),
		"Finais vistos: %d (%d diferentes de %d)" % [total_endings, Achievements.endings.size(), Content.all("endings").size()],
		"Pistas encontradas em todas as noites: %d / %d" % [s.get("clues_ever", {}).size(), Content.all("clues").size()],
	]:
		body.add_child(UI.label(line, 14, "dim"))


func _credits() -> void:
	body.add_child(UI.spacer(14))
	body.add_child(UI.label("CRÉDITOS", 13, "accent"))
	for line in [
		"UNKNOWN — terror psicológico na primeira pessoa.",
		"Feito com Godot Engine (godotengine.org, licença MIT). Tipo de letra predefinido do Godot.",
		"Todos os sons e fotografias são gerados em tempo real pelo jogo.",
		"Epígrafes dos capítulos: Fernando Pessoa, Ricardo Reis e Álvaro de Campos (domínio público).",
		"Salgueira, a Lumen Systems, a Clínica Atlântico e todas as pessoas desta história são fictícias.",
		"Se estás a passar por um momento difícil, fala com alguém. Em Portugal: SNS 24 (808 24 24 24) · SOS Voz Amiga (213 544 545).",
	]:
		body.add_child(UI.label(line, 13, "faint", true))
