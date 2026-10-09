extends SceneTree
## Splits an exported ZIP pack into UNKNOWN.pck (everything but the
## 3D assets) and UNKNOWN_3d_N.pck parts under a size limit, so a
## test build fits in downloads with a per-file limit.
##   godot --headless --script res://tools/split_pack.gd -- full.zip outdir 26

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var src: String = args[0]
	var out: String = args[1]
	var limit := int(args[2]) * 1000000 if args.size() > 2 else 26000000
	var zr := ZIPReader.new()
	if zr.open(src) != OK:
		printerr("cannot open ", src)
		quit(1)
		return
	var tmp := out.path_join("_tmp")
	DirAccess.make_dir_recursive_absolute(tmp)
	var files := zr.get_files()
	# which imported files belong to assets/3d (from their .import remaps)
	var heavy := {}
	for f in files:
		if f.begins_with("assets/3d/") and f.ends_with(".import"):
			var txt := zr.read_file(f).get_string_from_utf8()
			for line in txt.split("\n"):
				if line.begins_with("path") and line.contains("res://.godot/imported/"):
					heavy[line.split("\"")[1].trim_prefix("res://")] = true
	var base: Array = []
	var parts: Array = [[]]
	var sizes: Array = [0]
	for f in files:
		if f.ends_with("/"):
			continue
		var data := zr.read_file(f)
		var local := tmp.path_join(f.replace("/", "__"))
		var fa := FileAccess.open(local, FileAccess.WRITE)
		fa.store_buffer(data)
		fa.close()
		if heavy.has(f):
			if sizes[-1] + data.size() > limit and not parts[-1].is_empty():
				parts.append([])
				sizes.append(0)
			parts[-1].append([f, local])
			sizes[-1] += data.size()
		else:
			base.append([f, local])
	_pack(out.path_join("UNKNOWN.pck"), base)
	for i in parts.size():
		_pack(out.path_join("UNKNOWN_3d_%d.pck" % (i + 1)), parts[i])
	for e in base + parts.reduce(func(a, b): return a + b, []):
		DirAccess.remove_absolute(e[1])
	DirAccess.remove_absolute(tmp)
	print("split: base %d files, %d 3D parts" % [base.size(), parts.size()])
	quit(0)


func _pack(path: String, entries: Array) -> void:
	var p := PCKPacker.new()
	p.pck_start(path)
	for e in entries:
		p.add_file("res://" + e[0], e[1])
	p.flush()
