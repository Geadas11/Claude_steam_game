class_name Hotspot
extends Area3D
## Something in the house the player can look at or use: aim at it and press
## E. The area is a little bigger than the object so the aim ray finds it
## before the object's own collider.

const LAYER := 2

var prompt := "Examinar"
var on_use: Callable          # func(player: Player)
var enabled := true
var dynamic_prompt: Callable  # optional: func() -> String


static func add(parent: Node3D, center: Vector3, size: Vector3, prompt_text: String, use: Callable) -> Hotspot:
	var h := Hotspot.new()
	h.prompt = prompt_text
	h.on_use = use
	h.position = center
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size + Vector3(0.04, 0.04, 0.04)
	cs.shape = sh
	h.add_child(cs)
	parent.add_child(h)
	return h


func _ready() -> void:
	collision_layer = 1 << (LAYER - 1)
	collision_mask = 0
	monitoring = false
	monitorable = false


func interact_prompt() -> String:
	if not enabled:
		return ""
	if dynamic_prompt.is_valid():
		return dynamic_prompt.call()
	return prompt


func interact(player: Node) -> void:
	if enabled and on_use.is_valid():
		on_use.call(player)
