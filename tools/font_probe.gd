extends Control
func _ready() -> void:
	var l := Label.new()
	l.text = "— … · • € ° → ↔ ✓ ⚠ “aspas” ‘x’ ½ º ª ç ã õ é ê"
	l.add_theme_font_size_override("font_size", 40)
	l.position = Vector2(20, 20)
	add_child(l)
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/claude-0/font.png")
	get_tree().quit()
