extends Node3D

@onready var puzzle: AnimatableBody3D = $Puzzle
@onready var camera_pivot: Node3D = $CameraPivot

@export var cam_speed := 0.02
@export var puzzle_speed := 0.02

@export_range(-90, 0, 0.1, "radians_as_degrees") var cam_pitch_min := 0.0
@export_range(0, 90, 0.1, "radians_as_degrees") var cam_pitch_max := 0.0

var puzzle_motion:Vector2
var camera_motion:Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("pan_camera"):
			camera_motion -= event.screen_relative
		if Input.is_action_pressed("pan_puzzle"):
			puzzle_motion += event.screen_relative

func _process(delta: float) -> void:
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x + camera_motion.y * cam_speed, cam_pitch_min,cam_pitch_max)
	camera_pivot.rotation.y += camera_motion.x * cam_speed
	camera_motion = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var change := Basis()
	change = change.rotated(Vector3.RIGHT, puzzle_motion.y * puzzle_speed)
	change = change.rotated(Vector3.UP, puzzle_motion.x * puzzle_speed)
	change = camera_pivot.transform.basis * change * camera_pivot.transform.basis.inverse()
	puzzle.transform.basis = change * puzzle.transform.basis
	puzzle_motion = Vector2.ZERO
