extends Node
## Test builds sent in several downloads carry the 3D house in extra packs
## (AindaEstasAcordado_3d_1.pck, ...) next to the game. Load them before
## anything needs them. A Steam build is a single pack and skips this.


func _init() -> void:
	if OS.has_feature("editor"):
		return
	var dir := OS.get_executable_path().get_base_dir()
	var files := Array(DirAccess.get_files_at(dir))
	files.sort()
	for f in files:
		if f.begins_with("AindaEstasAcordado_") and f.ends_with(".pck"):
			if not ProjectSettings.load_resource_pack(dir.path_join(f), false):
				push_error("could not load " + f)
