extends SceneTree
## Writes QR PNGs for the texts given after "--" (tests/QR verification).
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	for i in range(1, args.size()):
		var m := QR.encode(args[i])
		var n := m.size()
		var scale := 8
		var img := Image.create((n + 8) * scale, (n + 8) * scale, false, Image.FORMAT_L8)
		img.fill(Color.WHITE)
		for y in n:
			for x in n:
				if m[y][x]:
					img.fill_rect(Rect2i((x + 4) * scale, (y + 4) * scale, scale, scale), Color.BLACK)
		img.save_png("%s/qr_%d.png" % [out_dir, i])
		print("QR ", i, " size=", n)
	quit()
