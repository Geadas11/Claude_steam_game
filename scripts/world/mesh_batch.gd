class_name MeshBatch
extends RefCounted
## Many small boxes merged into one mesh per material: a facade's sills,
## frames, shutters and bands become a handful of draw calls instead of
## hundreds. Materials must not need UVs (WB.mat / WB.flat are triplanar).

static var _unit: Array = []
var _parts := {}   # Material -> [PackedVector3Array verts, PackedVector3Array normals, PackedInt32Array indices]


func add(a: Vector3, b: Vector3, material: Material) -> void:
	if _unit.is_empty():
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE
		_unit = bm.get_mesh_arrays()
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var size := hi - lo
	var centre := (lo + hi) / 2.0
	if not _parts.has(material):
		_parts[material] = [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]
	var p: Array = _parts[material]
	var base: int = (p[0] as PackedVector3Array).size()
	var uv: PackedVector3Array = _unit[Mesh.ARRAY_VERTEX]
	var un: PackedVector3Array = _unit[Mesh.ARRAY_NORMAL]
	var ui: PackedInt32Array = _unit[Mesh.ARRAY_INDEX]
	for k in uv.size():
		p[0].append(uv[k] * size + centre)
		p[1].append(un[k])
	for i in ui:
		p[2].append(base + i)


## Builds the merged meshes under `parent` (no collision) and empties the batch.
func commit(parent: Node3D, cast_shadow := true) -> void:
	for material in _parts:
		var p: Array = _parts[material]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = p[0]
		arrays[Mesh.ARRAY_NORMAL] = p[1]
		arrays[Mesh.ARRAY_INDEX] = p[2]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
	_parts.clear()
