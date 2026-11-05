extends Node
## Walks the whole of a place on a 0.5 m grid from a spawn, the way the player
## can (steps up to 0.3 m, blocked by walls), and prints every spot where he
## could step off into nothing or down onto ground far below.
##   godot --headless res://tools/reach_probe.tscn -- caminho largo
const CELL := 0.5
const STEP := 0.3


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var loc: String = args[0] if args.size() > 0 else "caminho"
	var sp: String = args[1] if args.size() > 1 else "largo"
	GameState.in_game = true
	Audio.muted_for_tests = true
	var w := GameWorld.new()
	add_child(w)
	var hud := Control.new()
	add_child(hud)
	w.attach_hud(hud)
	w.set_active(true)
	w.go_to(loc, sp)
	for i in 5:
		await get_tree().physics_frame
	var space := w.get_world_3d().direct_space_state
	var excl := [w.player.get_rid()]
	var start: Vector3 = w.player.global_position
	var seen := {}
	var q: Array = []
	var k0 := Vector2i(roundi(start.x / CELL), roundi(start.z / CELL))
	var g0 := _ground(space, excl, start.x, start.z, start.y + 1.0)
	seen[k0] = g0
	q.append(k0)
	var holes := {}
	var n := 0
	while not q.is_empty():
		var k: Vector2i = q.pop_back()
		var h: float = seen[k]
		n += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nk: Vector2i = k + d
			if seen.has(nk):
				continue
			var a := Vector3(k.x * CELL, h, k.y * CELL)
			var b := Vector3(nk.x * CELL, h, nk.y * CELL)
			if _blocked(space, excl, a, b):
				continue
			var gh := _ground(space, excl, b.x, b.z, h + STEP + 0.05)
			if gh == INF:
				holes[nk] = "nothing below"
				continue
			if gh < h - 1.2:
				holes[nk] = "drop %.1f m to y %.1f" % [h - gh, gh]
				continue
			seen[nk] = gh
			q.append(nk)
	print("reachable cells: ", n)
	# a map, 2 m a character: . walkable, # a way to fall
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for c in seen:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var s := int(2.0 / CELL)
	print("map from x %.0f z %.0f, 2 m per char, x to the right, z down" % [lo.x * CELL, lo.y * CELL])
	for zz in range(lo.y, hi.y + s, s):
		var line := ""
		for xx in range(lo.x, hi.x + s, s):
			var ch := " "
			for dz in s:
				for dx in s:
					var c := Vector2i(xx + dx, zz + dz)
					if holes.has(c):
						ch = "#"
					elif ch == " " and seen.has(c):
						ch = "."
			line += ch
		print("|", line)
	var by_area := {}
	for hk in holes:
		var area := Vector2i(int(floor(hk.x * CELL / 4.0)), int(floor(hk.y * CELL / 4.0)))
		if not by_area.has(area):
			by_area[area] = [hk, holes[hk], 0]
		by_area[area][2] += 1
	for a in by_area:
		var e: Array = by_area[a]
		print("HOLE near (%.1f, %.1f) x%d: %s" % [e[0].x * CELL, e[0].y * CELL, e[2], e[1]])
	get_tree().quit()


func _ground(space: PhysicsDirectSpaceState3D, excl: Array, x: float, z: float, from_y: float) -> float:
	var r := PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, -60.0, z))
	r.exclude = excl
	var hit := space.intersect_ray(r)
	return INF if hit.is_empty() else (hit.position as Vector3).y


## Would his body (the capsule, lifted by a step) be stopped going a -> b?
func _blocked(space: PhysicsDirectSpaceState3D, excl: Array, a: Vector3, b: Vector3) -> bool:
	var cap := CapsuleShape3D.new()
	cap.radius = Player.RADIUS
	cap.height = Player.STAND_H - STEP
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.exclude = excl
	q.margin = 0.0
	q.transform = Transform3D(Basis(), a + Vector3(0, STEP + 0.02 + cap.height / 2, 0))
	q.motion = b - a
	var r := space.cast_motion(q)
	return r[0] < 1.0
