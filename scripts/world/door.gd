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
## With `vision` (x0, y0, x1, y1 in metres on the leaf) the door gets a small
## glass window — hospital doors — and no raised panels.
static func make(parent: Node3D, hinge: Vector3, axis: String, w: float, h: float, material: Material, swing := 1.0, vision := Rect2()) -> Door:
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
	if vision.size != Vector2.ZERO:
		# the leaf around the window, the glass, a thin frame
		var x0 := vision.position.x
		var y0 := vision.position.y
		var x1 := vision.end.x
		var y1 := vision.end.y
		var lw := w - 0.02
		var lh := h - 0.01
		for r in [[0.01, 0.0, lw + 0.01, y0], [0.01, y1, lw + 0.01, lh], [0.01, y0, x0, y1], [x1, y0, lw + 0.01, y1]]:
			WB.box(d.leaf, Vector3(r[0], r[1], -thick / 2), Vector3(r[2], r[3], thick / 2), material, false)
		WB.box(d.leaf, Vector3(x0, y0, -0.004), Vector3(x1, y1, 0.004), WB.glass(), false)
		var frame := WB.flat(Color(0.6, 0.62, 0.6), 0.3, 0.8)
		for side in [-1.0, 1.0]:
			for r2 in [[x0 - 0.02, y0 - 0.02, x1 + 0.02, y0], [x0 - 0.02, y1, x1 + 0.02, y1 + 0.02], [x0 - 0.02, y0, x0, y1], [x1, y0, x1 + 0.02, y1]]:
				WB.box(d.leaf, Vector3(r2[0], r2[1], side * thick / 2), Vector3(r2[2], r2[3], side * (thick / 2 + 0.006)), frame, false)
	else:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w - 0.02, h - 0.01, thick)
		mi.mesh = bm
		mi.material_override = material
		mi.position = Vector3(w / 2.0, h / 2.0, 0)
		d.leaf.add_child(mi)
	# raised panels so it reads as a real door, not a slab
	for py in ([] if vision.size != Vector2.ZERO else [h * 0.27, h * 0.68]):
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
