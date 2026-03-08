extends Node3D

@onready var puzzle: RigidBody3D = $Puzzle
@onready var camera_pivot: Node3D = $CameraPivot

@export var cam_speed := 0.02
@export var puzzle_speed := 0.02

@export_range(-90, 0, 0.1, "radians_as_degrees") var cam_pitch_min := -80.0
@export_range(0, 90, 0.1, "radians_as_degrees") var cam_pitch_max := 70.0

var puzzle_motion:Vector2
var camera_motion:Vector2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("pan_camera"):
			camera_motion -= event.screen_relative
		if Input.is_action_pressed("pan_puzzle") && not gizmo_grabbed:
			puzzle_motion += event.screen_relative

func _process(delta: float) -> void:
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x + camera_motion.y * cam_speed, cam_pitch_min,cam_pitch_max)
	camera_pivot.rotation.y += camera_motion.x * cam_speed
	camera_motion = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var change := Basis()
	if puzzle_motion:
		change = change.rotated(Vector3.RIGHT, puzzle_motion.y * puzzle_speed)
		change = change.rotated(Vector3.UP, puzzle_motion.x * puzzle_speed)
		change = camera_pivot.basis * change * camera_pivot.basis.inverse()
	elif gizmo_motion.y:
		change = change.rotated(puzzle.basis.y, gizmo_motion.y)
	elif gizmo_motion.x:
		change = change.rotated(puzzle.basis.x, gizmo_motion.x)
	elif gizmo_motion.z:
		change = change.rotated(puzzle.basis.z, gizmo_motion.z)
	
	puzzle_motion = Vector2.ZERO
	gizmo_motion = Vector3.ZERO
	
	# puzzle.angular_velocity = change.get_euler()/delta # not so simple huh
	# this has errors at high speed, moves other axis
	
	# Actually maybe our rotation matrix is the tensor already
	#puzzle.angular_velocity.x = change.y.z/delta
	#puzzle.angular_velocity.y = change.z.x/delta
	#puzzle.angular_velocity.z = change.x.y/delta
	# nope, rotational tensor also only works for ||w|| << 1 since we are a rotating frame
	
	# Solve by du = w*u https://physics.stackexchange.com/questions/511227/a-question-about-the-angular-velocity-vector
	#var b = puzzle.basis
	#var nb = change * b
	#var db = Basis(nb.x-b.x,nb.y-b.y,nb.z-b.z)
	#puzzle.angular_velocity = 0.5*(b.x.cross(db.x) + b.y.cross(db.y) + b.z.cross(db.z))/delta
	
	# Simpler method?
	var q = change.get_rotation_quaternion()
	puzzle.angular_velocity = q.get_axis() * q.get_angle() / delta

var gizmo_motion:Vector3
func _on_gizmo_y_dragged(offset: float) -> void:
	gizmo_motion.y += offset

func _on_gizmo_x_dragged(offset: float) -> void:
	gizmo_motion.x += offset

func _on_gizmo_z_dragged(offset: float) -> void:
	gizmo_motion.z += offset

var gizmo_grabbed:bool
func _on_gizmo_grabbed() -> void:
	gizmo_grabbed = true

func _on_gizmo_released() -> void:
	gizmo_grabbed = false
