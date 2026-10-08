extends Node
func _ready() -> void:
	for pid in Content.all("photos"):
		var spec: Dictionary = Content.get_item("photos", pid).get("scene", {})
		var variants: Array = ["base"] + spec.get("variants", {}).keys()
		for v in variants:
			var pv := PhotoView.new()
			pv.size = Vector2(300, 400)
			add_child(pv)
			pv.set_scene(spec, v)
			print("PHOTO ", pid, " ", v)
			await get_tree().process_frame
			await get_tree().process_frame
			pv.queue_free()
	for g in ["messages","phone","contacts","gallery","camera","browser","maps","email","notes","files","settings","clock","eco","back","search","send","more","plus","close","info","lock","mic","speaker","keypad","play","pause","star","trash","doc","audio","image","history","bookmark","refresh","voicemail","missed","arrow_in","arrow_out","shutter","flip","locate","zoom_in","edit","tag","link","wifi","dot","person","pin","folder","gear","globe","call","hangup","chevron","forward","wave","file"]:
		var gl := Glyph.new()
		gl.glyph = g
		gl.size = Vector2(40, 40)
		add_child(gl)
		print("GLYPH ", g)
		await get_tree().process_frame
		await get_tree().process_frame
		gl.queue_free()
	get_tree().quit()
