class_name RainParticles
extends GPUParticles3D
## The rain over Daniel's head. It follows where he walks but not where he
## looks: a child of the player would turn with the camera, and the slant
## of the rain would swing round every time he turned his head.

var target: Node3D
const HEIGHT := 10.0


func _ready() -> void:
	top_level = true
	_follow()


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	if target and is_instance_valid(target):
		global_transform = Transform3D(Basis.IDENTITY, target.global_position + Vector3(0, HEIGHT, 0))
