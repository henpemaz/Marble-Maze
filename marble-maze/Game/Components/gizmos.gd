extends Node3D

@export var puzzle:Node3D

# both this node and puzzle do interpolation so frame-positions match automagically
func _physics_process(_delta: float) -> void:
	global_transform = puzzle.global_transform
	force_update_transform()
