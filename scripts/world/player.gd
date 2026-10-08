class_name Player
extends CharacterBody3D
## First-person Daniel: walk (WASD), run (Shift), crouch (C / Ctrl),
## flashlight (F), use things (E). Slow and heavy on purpose: this is a
## small flat at night, not an arena.

signal used(target: Node)
signal thought(text: String)

const WALK := 1.55
const RUN := 3.1
const CROUCH := 0.8
const STAND_H := 1.72
const CROUCH_H := 1.05
const RADIUS := 0.26
const REACH := 2.1

var head: Node3D
var cam: Camera3D
var flashlight: SpotLight3D
var shape: CollisionShape3D
var look_enabled := true      # mouse look (the phone is down)
var move_enabled := true      # feet (not while typing or paused)
var crouching := false
var stamina := 1.0
var target: Node = null       # what the crosshair is on
var target_prompt := ""
var floor_kind: Callable      # func(pos) -> "wood" / "tile"

var _pitch := 0.0
var _yaw := 0.0
var _bob := 0.0
var _step_acc := 0.0
var _h := STAND_H
var _fl_rot := Vector3.ZERO
var _exhausted := false
var _shake := 0.0


func _ready() -> void:
	collision_layer = 1 << 2   # layer 3: the player (doors push it, rays skip it)
	collision_mask = 1
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50)
	shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = RADIUS
	cap.height = STAND_H
	shape.shape = cap
	shape.position.y = STAND_H / 2.0
	add_child(shape)
	head = Node3D.new()
	head.position.y = STAND_H - 0.1
	add_child(head)
	cam = Camera3D.new()
	cam.fov = float(Settings.get_value("fov", 75.0))
	cam.near = 0.05
	cam.far = 120.0
	head.add_child(cam)
	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(1.0, 0.94, 0.84)
	flashlight.light_energy = 3.2
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 26.0
	flashlight.spot_angle_attenuation = 0.6
	flashlight.spot_attenuation = 1.2
	flashlight.shadow_enabled = true
	flashlight.shadow_blur = 1.5
	flashlight.light_volumetric_fog_energy = 1.5
	flashlight.position = Vector3(0.18, -0.22, -0.1)
	flashlight.visible = false
	flashlight.top_level = true
	cam.add_child(flashlight)
	Events.settings_changed.connect(func(): cam.fov = float(Settings.get_value("fov", 75.0)))


func set_view(yaw_deg: float, pitch_deg := 0.0) -> void:
	_yaw = deg_to_rad(yaw_deg)
	_pitch = deg_to_rad(pitch_deg)
	rotation.y = _yaw
	head.rotation.x = _pitch


func yaw_deg() -> float:
	return rad_to_deg(_yaw)


func _unhandled_input(event: InputEvent) -> void:
	if not look_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := 0.0022 * float(Settings.get_value("mouse_sens", 1.0))
		var inv := -1.0 if Settings.get_value("invert_y", false) else 1.0
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens * inv, deg_to_rad(-85), deg_to_rad(85))
		rotation.y = _yaw
		head.rotation.x = _pitch
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		use_target()
		get_viewport().set_input_as_handled()


func toggle_flashlight(on := not flashlight.visible) -> void:
	if on == flashlight.visible:
		return
	flashlight.visible = on
	_fl_rot = cam.global_rotation
	Audio.play("flashlight", -10.0)


func use_target() -> void:
	if target and target.has_method("interact"):
		target.interact(self)
		used.emit(target)


func think(text: String) -> void:
	thought.emit(text)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _physics_process(delta: float) -> void:
	# --- feet
	var input := Vector2.ZERO
	if move_enabled:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var want_crouch := move_enabled and Input.is_action_pressed("crouch")
	if want_crouch != crouching:
		if want_crouch or _can_stand():
			crouching = want_crouch
	var running := move_enabled and Input.is_action_pressed("sprint") and input.y < -0.2 and not crouching and not _exhausted
	if running:
		stamina = maxf(0.0, stamina - delta / 4.5)
		if stamina <= 0.0:
			_exhausted = true
	else:
		stamina = minf(1.0, stamina + delta / 6.0)
		if _exhausted and stamina > 0.35:
			_exhausted = false
	var speed := CROUCH if crouching else (RUN if running else WALK)
	var dir := (transform.basis * Vector3(input.x, 0, input.y))
	dir.y = 0
	dir = dir.normalized() * minf(1.0, input.length())
	var accel := 10.0 if dir.length() > 0.01 else 12.0
	velocity.x = lerpf(velocity.x, dir.x * speed, clampf(accel * delta, 0, 1))
	velocity.z = lerpf(velocity.z, dir.z * speed, clampf(accel * delta, 0, 1))
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	# --- body height (crouch)
	var target_h := CROUCH_H if crouching else STAND_H
	_h = lerpf(_h, target_h, clampf(delta * 9.0, 0, 1))
	(shape.shape as CapsuleShape3D).height = _h
	shape.position.y = _h / 2.0
	# --- head bob and footsteps
	var hs := Vector2(velocity.x, velocity.z).length()
	var calm: bool = Settings.get_value("reduce_motion", false)
	if hs > 0.2 and is_on_floor():
		_bob += delta * hs * 2.6
		_step_acc += delta * hs
		var stride := 0.62 if not running else 0.85
		if _step_acc >= stride:
			_step_acc = 0.0
			_footstep(running)
	else:
		_bob = lerpf(_bob, roundf(_bob / PI) * PI, clampf(delta * 6.0, 0, 1))
	var bob_amp := 0.0 if calm else (0.035 if running else 0.018)
	head.position.y = _h - 0.1 + sin(_bob * 2.0) * bob_amp
	head.position.x = cos(_bob) * bob_amp * 0.6
	# --- camera shake (scares)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.0)
		var s := 0.0 if calm else _shake
		cam.h_offset = randf_range(-1, 1) * s * 0.02
		cam.v_offset = randf_range(-1, 1) * s * 0.02
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
	# --- flashlight follows the view with a little lag, like a hand
	if flashlight.visible:
		var goal := cam.global_transform.basis.get_rotation_quaternion()
		var cur := Quaternion.from_euler(_fl_rot)
		var q := cur.slerp(goal, clampf(delta * 14.0, 0, 1))
		_fl_rot = q.get_euler()
		flashlight.global_transform = Transform3D(Basis(q), cam.global_transform * Vector3(0.18, -0.22, -0.1))
	# --- what am I looking at?
	_aim()


func _can_stand() -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, CROUCH_H, 0), global_position + Vector3(0, STAND_H + 0.05, 0), 1)
	q.exclude = [get_rid()]
	return space.intersect_ray(q).is_empty()


func _aim() -> void:
	var space := get_world_3d().direct_space_state
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * REACH
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | (1 << (Hotspot.LAYER - 1)))
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	var found: Node = null
	if not hit.is_empty():
		var n: Node = hit.collider
		while n and not n.has_method("interact_prompt"):
			n = n.get_parent()
			if n is GameWorld or n is Window:
				n = null
				break
		found = n
	target = found
	target_prompt = found.interact_prompt() if found else ""
	if target_prompt == "":
		target = null


func _footstep(running: bool) -> void:
	var kind := "wood"
	if floor_kind.is_valid():
		kind = floor_kind.call(global_position)
	var p := AudioStreamPlayer3D.new()
	p.stream = Audio.stream("step_tile" if kind == "tile" else "step")
	p.bus = "SFX"
	p.volume_db = (-14.0 if crouching else (-4.0 if running else -9.0))
	p.pitch_scale = randf_range(0.88, 1.1)
	p.unit_size = 2.0
	p.position = Vector3(0, 0.05, 0)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
