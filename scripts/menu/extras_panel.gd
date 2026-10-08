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
