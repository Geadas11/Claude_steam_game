class_name Door
extends Node3D
## A hinged interior door. The node sits on the hinge; the leaf swings
## around Y. Opening never pushes through the player: the leaf is an
## AnimatableBody3D, so it shoves them aside like a real door would.

signal toggled(open: bool)

var leaf: AnimatableBody3D
var is_open := false
var locked := false
var locked_text := "Está trancada."
var open_angle := 95.0        # degrees, sign gives the direction
var width := 0.8
var _tw: Tween


## A door in a wall opening that starts at `hinge` and runs `width` metres
## along +X (axis "x") or +Z (axis "z"). swing_in flips which side it opens to.
static func make(parent: Node3D, hinge: Vector3, axis: String, w: float, h: float, material: Material, swing := 1.0) -> Door:
	var d := Door.new()
	d.width = w
	d.position = hinge
	d.rotation_degrees.y = 0.0 if axis == "x" else -90.0
	d.open_angle = 95.0 * swing
	parent.add_child(d)
	d.leaf = AnimatableBody3D.new()
	d.leaf.sync_to_physics = false
	d.add_child(d.leaf)
	var thick := 0.04
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w - 0.02, h - 0.01, thick)
	mi.mesh = bm
	mi.material_override = material
	mi.position = Vector3(w / 2.0, h / 2.0, 0)
	d.leaf.add_child(mi)
	# raised panels so it reads as a real door, not a slab
	for py in [h * 0.27, h * 0.68]:
		for side in [-1.0, 1.0]:
			var p := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(w * 0.62, h * (0.3 if py < h / 2 else 0.4), 0.012)
			p.mesh = pm
			p.material_override = material
			p.position = Vector3(w / 2.0, py, side * (thick / 2.0 + 0.004))
			d.leaf.add_child(p)
	# handle on both sides
	var metal := WB.flat(Color(0.62, 0.6, 0.55), 0.3, 0.9)
	for side in [-1.0, 1.0]:
		var hb := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(0.12, 0.02, 0.02)
		hb.mesh = hm
		hb.material_override = metal
		hb.position = Vector3(w - 0.12, 1.0, side * 0.05)
		d.leaf.add_child(hb)
		var rose := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.025
		rm.bottom_radius = 0.025
		rm.height = 0.03
		rose.mesh = rm
		rose.material_override = metal
		rose.rotation_degrees.x = 90
		rose.position = Vector3(w - 0.07, 1.0, side * 0.03)
		d.leaf.add_child(rose)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(w - 0.02, h - 0.01, thick + 0.04)
	cs.shape = sh
	cs.position = Vector3(w / 2.0, h / 2.0, 0)
	d.leaf.add_child(cs)
	d.leaf.collision_layer = 1 | (1 << (Hotspot.LAYER - 1))
	return d


func interact_prompt() -> String:
	return "Fechar a porta" if is_open else "Abrir a porta"


func interact(_player: Node) -> void:
	if locked and not is_open:
		_play("door_locked")
		if _player and _player.has_method("think"):
			_player.think(locked_text)
		return
	set_open(not is_open)


func set_open(o: bool, instant := false, speed := 1.0) -> void:
	if o == is_open and not instant:
		return
	is_open = o
	if _tw:
		_tw.kill()
	var target := open_angle if o else 0.0
	if instant:
		leaf.rotation_degrees.y = target
	else:
		_play("door_open" if o else "door_close", speed)
		_tw = create_tween()
		_tw.tween_property(leaf, "rotation_degrees:y", target, 0.9 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	toggled.emit(o)


func _play(sound: String, pitch := 1.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = Audio.stream(sound)
	p.bus = "SFX"
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.unit_size = 3.0
	p.position = Vector3(width / 2.0, 1.2, 0)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
