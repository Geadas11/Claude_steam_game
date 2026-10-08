class_name ChoicesPanel
extends MenuPanel
## "Decisões": what you chose, chapter by chapter. Helps returning players and
## makes the weight of earlier choices visible.


func _ready() -> void:
	make("As tuas decisões", 640)
	var entries: Array = GameState.data.get("choice_log", [])
	if entries.is_empty():
		body.add_child(UI.label("Ainda não tomaste nenhuma decisão.", 15, "dim"))
		return
	var last_ch := ""
	for entry in entries:
		var ch := str(entry.get("chapter", ""))
		if ch != last_ch:
			last_ch = ch
			body.add_child(UI.spacer(6))
			body.add_child(UI.label(Content.chapter_title(ch).to_upper(), 13, "accent"))
		var t := str(entry.get("text", ""))
		var silent := t.begins_with("[") and t.ends_with("]")
		var line := ("— " + t.trim_prefix("[").trim_suffix("]")) if silent else "“%s”" % t
		body.add_child(UI.label(line, 15, "dim" if silent else "text", true))
