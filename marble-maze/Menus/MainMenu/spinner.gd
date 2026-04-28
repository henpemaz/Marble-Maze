extends Node3D


@export var speed := 0.2
func _process(delta: float) -> void:
	rotate_y(delta*speed)
