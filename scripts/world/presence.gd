class_name Presence
extends Node3D
## The thing (lore-forge/.../knowledge/rules.md R1–R11). Never named, never
## seen clearly: a darker dark at the edge of the eye, wet footprints, a door
## that was closed, steps that stop when he stops.
##
## What draws it (R4): the phone's lit screen in his hand, answering calls,
## the dark, the hour getting close to 03:17, noise (running, doors, talking).
## What keeps it off (R5): light, silence, hiding, the phone put away. There
## is nothing to fight it with. In day chapters it only changes things (R6);
## in night chapters it can catch him, and Main starts the chapter again (R7).
## Its form follows the chapter (R3, data/world/presence.json). Everything it
## changes makes a small sound where it happens (R11).

signal caught(at: Vector3)

enum State { AWAY, NEAR, STALK, HUNT, SEARCH }
const STATE_NAMES := ["away", "near", "stalk", "hunt", "search"]
const BODY_FORMS := ["observado", "substituido", "afogar", "fechado", "sozinho", "todas"]
const PRINT_FORMS := ["pegada", "afogar", "todas"]
const MIXED := ["pegada", "observado", "substituido", "vozes", "proprio", "afogar", "fechado", "sozinho"]
const SPEED := {State.AWAY: 0.0, State.NEAR: 0.9, State.STALK: 1.15, State.HUNT: 2.45, State.SEARCH: 0.8}
const REACH := 1.1

var world: GameWorld
var cfg := {}
var form := "nenhuma"
var attention := 0.0           # 0..100
var state := State.AWAY
var enabled := true
var screen_on := false         # Main: the phone's screen is lit in his hand
var pos := Vector3(0, -50, 0)  # where it is (on the navigation mesh)
var body: Node3D
var held := false              # after catching him, until the restart

var _cfg_all := {}
var _mat: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var _path := PackedVector3Array()
var _path_i := 0
var _goal := Vector3.ZERO
var _has_goal := false
var _repath := 0.0
var _pause := 0.0              # standing still (NEAR: watching from a doorway)
var _cue_t := 6.0
var _change_t := 30.0
var _step_acc := 0.0
var _foot_side := 1.0
var _seen := 0.0
var _lit := 0.0
var _wait := 0.0               # stopped at the edge of a light
var _linger := 0.0             # searching at a hiding place
var _heard := Vector3.ZERO
var _noise := 0.0
var _glitch_t := 0.0
var _beat_t := 0.0
var _flick_t := 0.0
var _dark_t := 0.0             # "sozinho": time since it last put a light out
var _player_moving := 0.0
var _echoed := true
var _forced := -1
var _forced_t := 0.0
var _fade := 0.0
var _mixed_form := "pegada"

static var _foot_tex: ImageTexture
static var _foot_orm: ImageTexture


func setup(w: GameWorld) -> void:
	world = w
	_rng.randomize()
	var f := FileAccess.get_file_as_string("res://data/world/presence.json")
	var parsed = JSON.parse_string(f)
	_cfg_all = parsed if parsed is Dictionary else {}
	_build_body()
	Events.call_started.connect(_on_call)
	Events.chapter_started.connect(func(ch): configure(ch))
	Events.state_loaded.connect(func(): configure(str(GameState.data.chapter)))
	configure(str(GameState.data.get("chapter", "")))


## This chapter's form, whether it can kill, how quickly it notices.
func configure(ch: String) -> void:
	cfg = _cfg_all.get("default", {}).duplicate()
	cfg.merge(_cfg_all.get(ch, {}), true)
	form = str(cfg.get("form", "todas"))
	attention = 0.0
	held = false
	_set_state(State.AWAY)
	body.scale = Vector3.ONE * (0.86 if form == "substituido" else 1.0)


## A new place: learn its floor, listen to its doors, start far away.
func bind(loc: Location) -> void:
	if loc.nav == null:
		loc.bake_navigation()
	for d in loc.doors.values():
		if d is Door and not d.toggled.is_connected(_on_door):
			d.toggled.connect(_on_door.bind(d))
	attention *= 0.5
	_path = PackedVector3Array()
	_has_goal = false
	pos = Vector3(0, -50, 0)
	_set_state(State.AWAY if attention < 25 else State.NEAR)


func threat_scale() -> float:
	match str(Settings.get_value("threat", "normal")):
		"reduzida": return 0.6
		"historia": return 0.6
	return 1.0


## R6: no deaths by day (the clinic is the exception); "história" never kills.
func can_kill() -> bool:
	if not cfg.get("kills", false) or str(Settings.get_value("threat", "normal")) == "historia":
		return false
	return world.daylight < 0.35 or cfg.get("day_kills", false)


## Day chapters (and "telemovel"): only changes, no walking presence.
func walks() -> bool:
	if form in ["nenhuma", "telemovel"] or float(cfg.get("aggr", 1.0)) <= 0.0:
		return false
	return world.daylight < 0.35 or cfg.get("day_kills", false)


func state_name() -> String:
	return STATE_NAMES[state]


func cur_form() -> String:
	return _mixed_form if form == "todas" else form


# ------------------------------------------------------------------ the loop
func _physics_process(delta: float) -> void:
	if world == null or not world.active or world.location == null or not GameState.in_game or held:
		return
	if not enabled or form == "nenhuma":
		_fade = 0.0
		_update_body(delta)
		_changes(delta)
		return
	_update_attention(delta)
	_update_state(delta)
	if walks():
		_walk(delta)
		_look_check(delta)
		_cues(delta)
	_phone_glitch(delta)
	_changes(delta)
	_update_body(delta)


func _player_light() -> float:
	var p := world.player
	var l := world.location.light_at(p.global_position + Vector3(0, 1.0, 0), world.daylight)
	if p.flashlight.visible:
		l = maxf(l, 0.5)
	return l


## Minutes to 03:17 as a 0..1 pull (strongest in the last three hours).
func _near_317() -> float:
	var hm := Clock.fmt_time(Clock.now()).split(":")
	var m := int(hm[0]) * 60 + int(hm[1])
	var target := 3 * 60 + 17
	if m > target + 60:
		m -= 24 * 60
	if m > target:
		return clampf(1.0 - float(m - target) / 60.0, 0.0, 1.0)
	return clampf(1.0 - float(target - m) / 180.0, 0.0, 1.0)


func _update_attention(delta: float) -> void:
	var p := world.player
	var dark := 1.0 - _player_light()
	var hs := Vector2(p.velocity.x, p.velocity.z).length()
	_player_moving = hs
	if hs > 2.2:
		_noise += 6.0 * delta
		_heard = p.global_position
	if Director.in_call:
		_noise += 3.0 * delta
		_heard = p.global_position
	_noise = clampf(_noise - delta * 2.0, 0.0, 10.0)
	var hidden := not world.hiding.is_empty()
	# the phone's glow matters in the dark; under a lamp it is just a phone
	var glow := (1.5 * (0.25 + 0.75 * dark)) if screen_on else 0.0
	var gain := 0.5 * dark + 1.6 * _near_317() + glow + _noise * 0.6
	if screen_on:
		_heard = p.global_position
	gain *= float(cfg.get("aggr", 1.0)) * threat_scale()
	var loss := 2.2 * (1.0 - dark) + (5.0 if hidden else 0.0)
	if hs < 0.1 and not screen_on and _noise < 0.5:
		loss += 0.8
	if not screen_on:
		loss += 0.4
	attention = clampf(attention + (gain - loss) * delta, 0.0, 100.0)


func _update_state(delta: float) -> void:
	var hidden := not world.hiding.is_empty()
	var s := state
	if _forced >= 0:
		_forced_t -= delta
		s = _forced
		if _forced_t <= 0.0:
			_forced = -1
	elif not walks():
		s = State.NEAR if attention >= 25 else State.AWAY
	elif hidden and state in [State.STALK, State.HUNT]:
		s = State.SEARCH
	elif state == State.SEARCH:
		if not hidden or _linger <= 0.0:
			if hidden:
				attention = minf(attention, 30.0)
			s = State.NEAR if attention >= 25 else State.AWAY
	elif attention >= 85:
		s = State.HUNT
	elif attention >= 55:
		s = State.HUNT if state == State.HUNT and attention > 70 else State.STALK
	elif attention >= 25 or (state != State.AWAY and attention >= 20):
		s = State.NEAR
	else:
		s = State.AWAY
	if s != state:
		_set_state(s)


func _set_state(s: int) -> void:
	var was := state
	state = s
	_has_goal = false
	_repath = 0.0
	_wait = 0.0
	if form == "todas" and s in [State.NEAR, State.STALK] and was == State.AWAY:
		_mixed_form = MIXED[_rng.randi() % MIXED.size()]
	match s:
		State.AWAY:
			if was != State.AWAY and world and world.location:
				_park()
		State.NEAR:
			if was == State.AWAY and world and world.location and walks():
				_appear_out_of_sight(6.0, 11.0)
		State.SEARCH:
			_linger = _rng.randf_range(7.0, 11.0)
			var spot: Dictionary = world.hiding
			_goal = _on_nav(spot.get("exit_pos", world.player.global_position))
			_has_goal = true
			_repath = 0.0
		State.HUNT:
			if pos.y < -40.0:
				_appear_out_of_sight(7.0, 12.0)
			Audio.play("sub", -12.0, 0.8)
	GameState.set_var("w_presence", STATE_NAMES[s])


# ------------------------------------------------------------------ moving
func _nav_map() -> RID:
	return get_world_3d().navigation_map


func _on_nav(p: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(_nav_map(), p)


## Somewhere r0..r1 metres from him, on the floor, where he isn't looking.
func _point_near_player(r0: float, r1: float, hidden_only := true) -> Vector3:
	var pp := world.player.global_position
	var best := Vector3(0, -50, 0)
	for i in 16:
		var a := _rng.randf() * TAU
		var c := _on_nav(pp + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(r0, r1))
		if c == Vector3.ZERO:
			continue
		var d := c.distance_to(pp)
		if d < r0 * 0.7 or absf(c.y - pp.y) > 0.35:
			continue   # not on top of the furniture
		var route := NavigationServer3D.map_get_path(_nav_map(), c, pp, true)
		if route.is_empty() or route[route.size() - 1].distance_to(pp) > 1.2:
			continue   # an island it couldn't walk out of
		if hidden_only and _in_view(c + Vector3(0, 1.0, 0)):
			continue
		if world.location.light_at(c + Vector3(0, 1.0, 0), world.daylight) > 0.45:
			continue
		return c
	return best


func _appear_out_of_sight(r0: float, r1: float) -> void:
	var c := _point_near_player(r0, r1)
	if c.y > -40.0:
		pos = c


func _park() -> void:
	pos = Vector3(0, -50, 0)
	_path = PackedVector3Array()
	_fade = 0.0


func _walk(delta: float) -> void:
	if state == State.AWAY or pos.y < -40.0:
		if state != State.AWAY and pos.y < -40.0:
			_appear_out_of_sight(6.0, 12.0)
		return
	var pp := world.player.global_position
	_repath -= delta
	match state:
		State.NEAR:
			if _pause > 0.0:
				_pause -= delta
				return
			if not _has_goal or _path_i >= _path.size():
				if _has_goal:
					_pause = _rng.randf_range(3.0, 8.0)
					_has_goal = false
					return
				var g := _point_near_player(4.0, 9.0)
				if g.y < -40.0:
					return
				_go(g)
		State.STALK:
			if pos.distance_to(pp) < 3.2 and world.hiding.is_empty():
				_face(pp)
				return
			if _repath <= 0.0:
				_go(_heard if _heard != Vector3.ZERO and _noise > 0.5 else pp)
				_repath = 2.0
		State.HUNT:
			if _repath <= 0.0:
				_go(pp)
				_repath = 0.4
		State.SEARCH:
			# it looks for him for a while, wherever it got to
			_linger -= delta * 0.5
			if pos.distance_to(_goal) < 1.6:
				_linger -= delta * 0.5
				_face(world.hiding.get("cam_pos", pp))
				if screen_on and pos.distance_to(world.hiding.get("cam_pos", pp)) < 3.5:
					_reach_him()
				return
			if _repath <= 0.0:
				_go(_goal)
				_repath = 1.5
	_advance(delta, SPEED[state] * (0.75 if threat_scale() < 1.0 and state == State.HUNT else 1.0))
	if state == State.HUNT and pos.distance_to(pp) < REACH and _los(pos + Vector3(0, 1.5, 0), world.player.cam.global_position):
		_reach_him()


func _go(target: Vector3) -> void:
	_path = NavigationServer3D.map_get_path(_nav_map(), pos, target, true)
	_path_i = 1 if _path.size() > 1 else 0
	_has_goal = true


func _advance(delta: float, speed: float) -> void:
	var step := speed * delta
	var moved := 0.0
	while step > 0.0 and _path_i < _path.size():
		var t: Vector3 = _path[_path_i]
		var d := pos.distance_to(t)
		var nxt := t if d <= step else pos + (t - pos) / d * step
		# light keeps it off (R5): it stops where the light starts
		if world.location.light_at(nxt + Vector3(0, 1.0, 0), world.daylight) > 0.45:
			_at_light_edge(delta, nxt)
			break
		_wait = 0.0
		if not _through_doors(nxt):
			break
		moved += pos.distance_to(nxt)
		if d <= step:
			step -= d
			_path_i += 1
		else:
			step = 0.0
		var dir := nxt - pos
		pos = nxt
		if dir.length() > 0.01:
			body.rotation.y = atan2(dir.x, dir.z)
	if moved > 0.0:
		_step_acc += moved
		var stride := 0.78 if state == State.HUNT else 0.62
		if _step_acc >= stride:
			_step_acc = 0.0
			_step()


func _at_light_edge(delta: float, nxt: Vector3) -> void:
	_wait += delta
	if cur_form() == "sozinho":
		_dark_t -= delta
		if _wait > 3.0 and _dark_t <= 0.0:
			_dark_t = 25.0
			world.location.kill_light_at(nxt)
			world.play_at("switch", nxt + Vector3(0, 1.4, 0), -12.0, 0.8)
			return
	_flick_t -= delta
	if _flick_t <= 0.0 and _wait > 0.5:
		_flick_t = _rng.randf_range(2.5, 4.5)
		var room := world.location.room_at(nxt)
		if room != "":
			world.location.flicker(room, 0.5)
	if _wait > 12.0:
		attention = maxf(0.0, attention - 30.0)
		_vanish()


## Closed doors on its way open by themselves (and are heard). Locked ones
## rattle and stop it.
func _through_doors(nxt: Vector3) -> bool:
	for d in world.location.doors.values():
		if not d is Door or d.is_open:
			continue
		var c: Vector3 = d.global_transform * Vector3(d.width / 2.0, 0.0, 0.0)
		if Vector2(c.x - nxt.x, c.z - nxt.z).length() < 0.75 and absf(c.y - nxt.y) < 1.5:
			if d.locked:
				# it tries the handle, then it is somewhere else
				d._play("door_locked", 0.8)
				_has_goal = false
				_path = PackedVector3Array()
				_pause = 2.0
				if not _in_view(pos + Vector3(0, 1.4, 0)):
					var c2 := _point_near_player(5.0, 10.0)
					if c2.y > -40.0:
						pos = c2
				return false
			d.set_open(true, false, 0.55)
			GameState.inc_var("w_doors_opened")
			return false
	return true


func _face(p: Vector3) -> void:
	var d := p - pos
	if Vector2(d.x, d.z).length() > 0.05:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(d.x, d.z), 0.1)


func _vanish() -> void:
	world.play_at("sub", pos + Vector3(0, 1.2, 0), -14.0, 0.7)
	GameState.inc_var("w_glimpses")
	_seen = 0.0
	_lit = 0.0
	_has_goal = false
	_path = PackedVector3Array()
	if state in [State.HUNT, State.STALK]:
		attention = minf(attention, 50.0)
	var c := _point_near_player(9.0, 16.0)
	pos = c
	_fade = 0.0


func _reach_him() -> void:
	if can_kill():
		held = true
		GameState.inc_var("w_caught")
		caught.emit(pos)
	else:
		# night but no deaths in this chapter: right there, then gone
		world.player.shake(0.8)
		Audio.play("glitch_short", -6.0)
		Audio.play("sub", -4.0, 0.7)
		attention = 10.0
		_vanish()
		_set_state(State.AWAY)


# ------------------------------------------------------------------ being looked at (R2)
func _los(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	q.exclude = [world.player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or (hit.position as Vector3).distance_to(b) < 0.35


func _in_view(p: Vector3) -> bool:
	var cam := world.player.cam
	if not world.hiding.is_empty():
		cam = world._hide_cam
	if not cam.is_position_in_frustum(p):
		return false
	return _los(cam.global_position, p)


## Angle (degrees) between where he looks and the thing's chest; 180 if hidden.
func _view_angle() -> float:
	if pos.y < -40.0:
		return 180.0
	var chest := pos + Vector3(0, 1.4, 0)
	if not _in_view(chest):
		return 180.0
	var cam := world.player.cam
	var dir := (chest - cam.global_position).normalized()
	return rad_to_deg(acos(clampf(dir.dot(-cam.global_transform.basis.z), -1.0, 1.0)))


func _look_check(delta: float) -> void:
	if pos.y < -40.0 or state == State.AWAY:
		return
	# a light comes on where it stands: it was never there
	if world.location.light_at(pos + Vector3(0, 1.0, 0), world.daylight) > 0.6:
		_vanish()
		return
	var ang := _view_angle()
	var p := world.player
	# looked at straight on, it is not there (except when it comes for him)
	if ang < 14.0 and state != State.HUNT:
		_seen += delta
		if _seen > 0.35:
			_vanish()
			return
	else:
		_seen = maxf(0.0, _seen - delta)
	# the torch on it: it goes (R5)
	if p.flashlight.visible and ang < 16.0 and pos.distance_to(p.global_position) < 10.0:
		_lit += delta
		if _lit > 0.45:
			attention = maxf(0.0, attention - 20.0)
			_vanish()
	else:
		_lit = 0.0


# ------------------------------------------------------------------ sounds and signs
func _step() -> void:
	var f := cur_form()
	var at := pos + Vector3(0, 0.05, 0)
	if f in PRINT_FORMS or (state == State.NEAR and _rng.randf() < 0.25):
		_footprint(pos, body.rotation.y)
	if f == "pegada" and state == State.NEAR:
		if _rng.randf() < 0.3:
			world.play_at("drop", at, -24.0, 1.6)
		return
	if f == "vozes" and state != State.HUNT:
		return
	var kind := "wood"
	if world.location.has_method("floor_kind"):
		kind = world.location.floor_kind(pos)
	var vol := -16.0 if state == State.NEAR else (-11.0 if state == State.STALK else -6.0)
	var pitch := 0.78 if f != "substituido" else 1.0
	world.play_at("step_tile" if kind == "tile" else "step", at, vol, pitch * _rng.randf_range(0.95, 1.05))
	if f == "afogar":
		world.play_at("water", at, vol - 8.0, 1.4)


func _cues(delta: float) -> void:
	var p := world.player
	# "proprio": his own steps go on for two more after he stops
	if cur_form() == "proprio" and state != State.AWAY:
		if _player_moving > 0.6:
			_echoed = false
		elif not _echoed and _player_moving < 0.1:
			_echoed = true
			var behind := p.global_position + p.global_transform.basis.z * 2.2
			_echo_steps(behind)
	# heartbeat when it is close and coming
	if state == State.HUNT and pos.distance_to(p.global_position) < 9.0:
		_beat_t -= delta
		if _beat_t <= 0.0:
			_beat_t = 0.9
			Audio.play("heartbeat", -9.0)
	if state == State.AWAY or pos.y < -40.0:
		return
	_cue_t -= delta
	if _cue_t > 0.0:
		return
	_cue_t = _rng.randf_range(7.0, 15.0) if state == State.NEAR else _rng.randf_range(4.0, 8.0)
	var at := pos + Vector3(0, 1.5, 0)
	match cur_form():
		"vozes":
			world.play_at("whisper" if _rng.randf() < 0.6 else "voice_low", at, -12.0, _rng.randf_range(0.85, 1.05))
		"substituido", "afogar":
			world.play_at("breath", at, -14.0, 0.72 if cur_form() == "afogar" else 1.0)
		"observado":
			world.play_at("door", at, -20.0, 0.9)
		"fechado":
			_close_behind()
		"pegada":
			world.play_at("water", pos + Vector3(0, 0.1, 0), -22.0, 1.3)
		"sozinho":
			_dark_t -= 6.0


func _echo_steps(at: Vector3) -> void:
	var kind := "wood"
	if world.location.has_method("floor_kind"):
		kind = world.location.floor_kind(at)
	for i in 2:
		await get_tree().create_timer(0.45 + i * 0.55).timeout
		if world and world.location:
			world.play_at("step_tile" if kind == "tile" else "step", at + Vector3(0, 0.05, 0), -12.0, 0.97)


## "fechado": an open door near him, out of his sight, shuts.
func _close_behind() -> void:
	var pp := world.player.global_position
	for d in world.location.doors.values():
		if d is Door and d.is_open:
			var c: Vector3 = d.global_transform * Vector3(d.width / 2.0, 1.2, 0.0)
			if c.distance_to(pp) < 7.0 and c.distance_to(pp) > 1.5 and not _in_view(c):
				d.set_open(false, false, 1.6)
				GameState.inc_var("w_doors_closed")
				return


## The phone notices first: the screen in his hand glitches when it is near.
func _phone_glitch(delta: float) -> void:
	_glitch_t -= delta
	if not screen_on or _glitch_t > 0.0:
		return
	var near := attention > 50.0 or (form == "telemovel" and attention > 30.0)
	if near:
		_glitch_t = _rng.randf_range(6.0, 12.0)
		Events.glitch_requested.emit(0.25 if form != "telemovel" else 0.45, 0.35)


# ------------------------------------------------------------------ the place changes (R10, R11)
func _changes(delta: float) -> void:
	var mult := float(cfg.get("changes", 1.0))
	if mult <= 0.0 or world.location.changeables.is_empty():
		return
	_change_t -= delta * mult * (1.0 + attention / 50.0)
	if _change_t > 0.0:
		return
	_change_t = _rng.randf_range(35.0, 70.0)
	if not change_one():
		_change_t = 5.0


## Change one thing he isn't looking at, with its sound where it happens.
func change_one(silent := false) -> bool:
	var pp := world.player.global_position
	var options: Array = []
	for c in world.location.changeables:
		if c.get("done", false):
			continue
		var cp: Vector3 = c.pos
		if cp.distance_to(pp) < 2.5 or _in_view(cp):
			continue
		options.append(c)
	if options.is_empty():
		return false
	var c: Dictionary = options[_rng.randi() % options.size()]
	c.done = true
	c.apply.call()
	GameState.inc_var("w_changes")
	if not silent:
		world.play_at(str(c.sound), c.pos, float(c.volume))
	return true


## After a restart (R8): something is not where it was. Heard faintly in the dark.
func leave_marks(n: int) -> void:
	mark_death_spot()
	for i in clampi(n, 1, 3):
		var pp := world.player.global_position
		var options := world.location.changeables.filter(func(c): return not c.get("done", false) and (c.pos as Vector3).distance_to(pp) > 1.5)
		if options.is_empty():
			return
		var c: Dictionary = options[_rng.randi() % options.size()]
		c.done = true
		c.apply.call()
		world.play_at(str(c.sound), c.pos, float(c.volume) - 6.0)


# ------------------------------------------------------------------ story
## "world presence <cmd>": off, on, calm, near, stalk, hunt [secs], form <f>, attention <n>
func story_cmd(args: Array) -> void:
	if args.is_empty():
		return
	match str(args[0]):
		"off":
			enabled = false
			_set_state(State.AWAY)
		"on":
			enabled = true
		"calm":
			attention = 0.0
			_forced = -1
			_set_state(State.AWAY)
		"near", "stalk", "hunt":
			enabled = true
			_forced = ["near", "stalk", "hunt"].find(str(args[0])) + 1
			_forced_t = float(args[1]) if args.size() > 1 else 20.0
			attention = maxf(attention, [30.0, 60.0, 90.0][_forced - 1])
		"form":
			if args.size() > 1:
				form = str(args[1])
		"attention":
			if args.size() > 1:
				attention = clampf(float(args[1]), 0.0, 100.0)


func _on_call(_call: Dictionary) -> void:
	if world and world.active:
		attention = minf(100.0, attention + 12.0 * float(cfg.get("aggr", 1.0)) * threat_scale())
		_heard = world.player.global_position


func _on_door(open: bool, d: Door) -> void:
	if world == null or world.player == null:
		return
	var c: Vector3 = d.global_transform * Vector3(d.width / 2.0, 1.0, 0.0)
	if c.distance_to(world.player.global_position) < 3.0:
		_noise += 2.5 if open else 3.5
		_heard = world.player.global_position


# ------------------------------------------------------------------ what there is to see
func _build_body() -> void:
	body = Node3D.new()
	body.top_level = true
	add_child(body)
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
uniform float fade = 0.0;
uniform vec3 tint : source_color = vec3(0.002, 0.002, 0.003);
uniform sampler2D smoke : repeat_enable;
varying vec3 wp;
varying float hgt;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = texture(smoke, w.xy * 0.6 + vec2(TIME * 0.05, -TIME * 0.13)).r;
	float m = texture(smoke, w.zy * 0.9 - vec2(TIME * 0.07, TIME * 0.05)).r;
	VERTEX += NORMAL * ((n - 0.5) * 0.16 + (m - 0.5) * 0.08);
	wp = w;
	hgt = VERTEX.y;
}
void fragment() {
	// one smoky shape, never a clean outline (R2): hashed alpha so the
	// parts melt together, frayed edges, feet lost in the floor
	float n = texture(smoke, wp.xy * 1.6 + wp.zx * 0.7 + vec2(-TIME * 0.05, TIME * 0.12)).r;
	float facing = abs(dot(NORMAL, VIEW));
	float edge = smoothstep(0.0, 0.4, facing);
	float feet = smoothstep(0.0, 0.5, hgt);
	ALBEDO = tint;
	ALPHA = clamp(fade * 1.3 * edge * feet * smoothstep(0.05, 0.45, n + 0.25), 0.0, 1.0);
	ALPHA_HASH_SCALE = 1.0;
}"""

	_mat = ShaderMaterial.new()
	_mat.shader = sh
	var nt := NoiseTexture2D.new()
	nt.seamless = true
	nt.width = 128
	nt.height = 128
	var fn := FastNoiseLite.new()
	fn.frequency = 0.035
	fn.fractal_octaves = 3
	nt.noise = fn
	_mat.set_shader_parameter("smoke", nt)
	# tall, thin, hunched; arms too long; the head forward and tilted
	_part(_capsule(0.2, 0.95), Vector3(0, 1.36, 0.02), Vector3(12, 0, 0))
	_part(_capsule(0.16, 0.5), Vector3(0, 1.72, 0.1), Vector3(28, 0, 0))
	_part(_sphere(0.13), Vector3(0.05, 1.93, 0.2), Vector3(0, 0, 18))
	for s2 in [-1.0, 1.0]:
		_part(_capsule(0.06, 1.25), Vector3(0.27 * s2, 1.08, 0.08), Vector3(8, 0, 5 * s2))
		_part(_capsule(0.085, 1.0), Vector3(0.11 * s2, 0.5, 0), Vector3(0, 0, 2 * s2))
	body.visible = false


func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 12
	m.rings = 4
	return m


func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.3
	m.radial_segments = 12
	m.rings = 6
	return m


func _part(mesh: Mesh, at: Vector3, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat
	mi.position = at
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)


func _update_body(delta: float) -> void:
	var show := walks() and enabled and pos.y > -40.0 and state != State.AWAY
	var f := cur_form()
	if not (f in BODY_FORMS or state == State.HUNT):
		show = false
	var target := 0.0
	if show:
		var ang := _view_angle()
		# clearest at the edge of the eye, a smear when looked at (R2)
		target = clampf((ang - 5.0) / 30.0, 0.2, 0.92)
		if state == State.HUNT:
			target = maxf(target, 0.55)
	_fade = move_toward(_fade, target, delta * 2.5)
	body.visible = _fade > 0.01
	body.global_position = pos
	_mat.set_shader_parameter("fade", _fade)


## Visual QA: hold it at a spot, facing him, with this much of it showing.
func show_at(p: Vector3, fade: float, prints := false) -> void:
	held = true
	pos = _on_nav(p)
	_face(world.player.global_position)
	body.rotation.y = atan2(world.player.global_position.x - pos.x, world.player.global_position.z - pos.z)
	if prints:
		var back := Vector3(sin(body.rotation.y), 0, cos(body.rotation.y))
		for i in 8:
			_footprint(pos + back * (i * 0.33 + 0.6), body.rotation.y)
	_fade = fade
	body.visible = true
	body.global_position = pos
	_mat.set_shader_parameter("fade", fade)


## The glimpse when it reaches him: right in front, still not clear.
func glimpse(at_player: Vector3, facing: Vector3) -> void:
	pos = at_player + facing * 0.85
	pos.y = at_player.y
	body.rotation.y = atan2(-facing.x, -facing.z)
	_fade = 0.75
	body.visible = true
	body.global_position = pos
	_mat.set_shader_parameter("fade", _fade)


# ------------------------------------------------------------------ someone far off (story)
## A still figure at `p` (on the floor), facing him: "red" is a red coat in
## the rain, "dark" is him, soaked, coming the other way. It is never there
## when he gets close or stares at it (R2).
func figure(p: Vector3, kind := "dark") -> Node3D:
	var f := body.duplicate() as Node3D
	var m := _mat.duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", (Color(0.5, 0.03, 0.04) if kind == "red" else Color(0.2, 0.012, 0.018)) if kind in ["red", "ines"] else Color(0.004, 0.004, 0.005))
	m.set_shader_parameter("fade", 0.0)
	for c in f.get_children():
		(c as MeshInstance3D).material_override = m
	f.set_meta("mat", m)
	f.set_meta("seen", 0.0)
	f.set_meta("kind", kind)
	f.scale = Vector3.ONE * (0.82 if kind in ["red", "ines"] else 0.86)
	add_child(f)
	f.global_position = _on_nav(p)
	var pp := world.player.global_position
	f.rotation.y = atan2(pp.x - f.global_position.x, pp.z - f.global_position.z)
	f.visible = true
	return f


## Fades a figure in, and out for good when he is close or looks too long.
## Returns true when it is gone.
func figure_check(f: Node3D, delta: float) -> bool:
	var m: ShaderMaterial = f.get_meta("mat")
	var a: float = m.get_shader_parameter("fade")
	var d := f.global_position.distance_to(world.player.global_position)
	var cam := world.player.cam
	var chest := f.global_position + Vector3(0, 1.4, 0)
	var dir := (chest - cam.global_position).normalized()
	var straight := cam.is_position_in_frustum(chest) and dir.dot(-cam.global_transform.basis.z) > 0.985
	var seen: float = f.get_meta("seen") + (delta if straight else 0.0)
	f.set_meta("seen", seen)
	if f.get_meta("kind", "") == "ines" and not f.get_meta("going", false):
		# a memory of her: she stays, back to the sea, never clear
		m.set_shader_parameter("fade", move_toward(a, 0.95, delta * 0.8))
		return false
	if d < 14.0 or seen > 3.5 or f.get_meta("going", false):
		f.set_meta("going", true)
		a = move_toward(a, 0.0, delta * 1.5)
		m.set_shader_parameter("fade", a)
		if a <= 0.0:
			world.play_at("sub", chest, -20.0, 0.7)
			f.queue_free()
			return true
		return false
	m.set_shader_parameter("fade", move_toward(a, 0.85, delta * 0.8))
	return false


## Wet footprints from `p` towards `yaw`, n steps.
func trail(p: Vector3, yaw: float, n: int) -> void:
	var dir := Vector3(sin(yaw), 0, cos(yaw))
	for i in n:
		_footprint(_on_nav(p + dir * (i * 0.36)), yaw)


## After a restart (R8): his own wet footprint where it reached him.
func mark_death_spot() -> void:
	var dp = GameState.get_var("last_death_pos", [])
	if dp is Array and dp.size() == 3 and str(GameState.get_var("last_death_loc", "")) == world.location.loc_id:
		var at := Vector3(float(dp[0]), float(dp[1]), float(dp[2]))
		_footprint(at, _rng.randf() * TAU)
		_footprint(at + Vector3(0.25, 0, 0.1), _rng.randf() * TAU)


# ------------------------------------------------------------------ wet footprints
func _footprint(at: Vector3, yaw: float) -> void:
	if _foot_tex == null:
		_make_foot_textures()
	_foot_side = -_foot_side
	var d := Decal.new()
	d.size = Vector3(0.13, 0.7, 0.31)
	d.texture_albedo = _foot_tex
	d.texture_orm = _foot_orm
	d.modulate = Color(0.5, 0.55, 0.58, 1.0)
	d.albedo_mix = 0.85
	d.upper_fade = 0.1
	d.lower_fade = 0.1
	var side := Vector3(cos(yaw), 0, -sin(yaw)) * 0.11 * _foot_side
	world.location.add_child(d)
	d.global_position = at + side + Vector3(0, 0.05, 0)
	d.rotation.y = yaw + PI   # the toes of the texture point to -Z
	var tw := d.create_tween()
	tw.tween_interval(40.0)
	tw.tween_property(d, "modulate:a", 0.0, 50.0)
	tw.tween_callback(d.queue_free)
	GameState.set_var("w_footprints", true)


static func _make_foot_textures() -> void:
	var w := 32
	var h := 80
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var orm := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u := (x + 0.5) / w * 2.0 - 1.0
			var v := (y + 0.5) / h
			var a := 0.0
			# heel, sole (narrow arch), ball and five toes
			a = maxf(a, 1.0 - ((u * u) / 0.42 + pow((v - 0.84) / 0.13, 2.0)))
			a = maxf(a, 1.0 - (pow((u + 0.1) / 0.58, 2.0) + pow((v - 0.6) / 0.26, 2.0)))
			a = maxf(a, 1.0 - (pow((u - 0.02) / 0.78, 2.0) + pow((v - 0.33) / 0.13, 2.0)))
			var toes := [[-0.48, 0.13, 0.17], [-0.17, 0.1, 0.13], [0.1, 0.11, 0.12], [0.34, 0.13, 0.11], [0.56, 0.16, 0.1]]
			for t in toes:
				a = maxf(a, 1.0 - (pow((u - t[0]) / t[2], 2.0) + pow((v - t[1]) / (t[2] * 0.42), 2.0)))
			a = clampf(a * 2.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.03, 0.035, 0.04, a * 0.95))
			orm.set_pixel(x, y, Color(1.0, 0.08, 0.0, a))
	_foot_tex = ImageTexture.create_from_image(img)
	_foot_orm = ImageTexture.create_from_image(orm)
