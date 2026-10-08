class_name RecapPanel
extends MenuPanel
## "Até agora": a short recap of every finished chapter, for players
## returning after a break. Only covers chapters already played.


func _ready() -> void:
	make("Até agora", 640)
	var order: Array = Content.db.get("chapters_meta", {}).get("order", [])
	var cur := order.find(GameState.data.chapter)
	var shown := 0
	for i in range(maxi(cur, 0)):
		var ch: String = order[i]
		var text := Content.chapter_recap(ch)
		if text == "":
			continue
		body.add_child(UI.spacer(4))
		body.add_child(UI.label("%d · %s" % [i + 1, Content.chapter_title(ch).to_upper()], 13, "accent"))
		body.add_child(UI.label(text, 15, "text", true))
		shown += 1
	if shown == 0:
		body.add_child(UI.label("Ainda estás no princípio.", 15, "dim"))
