extends Node3D

@export var puzzle:RigidBody3D

# both this node and puzzle do interpolation
func _physics_process(delta: float) -> void:
	global_transform = puzzle.global_transform
