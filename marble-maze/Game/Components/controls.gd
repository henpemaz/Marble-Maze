extends Node3D

@export var puzzle: RigidBody3D
@export var camera_pivot: Node3D

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

var puzzle_goal:Basis
func _physics_process(delta: float) -> void:
	if puzzle_motion:
		var change := Basis()
		change = change.rotated(Vector3.RIGHT, puzzle_motion.y * puzzle_speed)
		change = change.rotated(Vector3.UP, puzzle_motion.x * puzzle_speed)
		puzzle_goal = camera_pivot.basis * change * camera_pivot.basis.inverse() * puzzle_goal
	elif gizmo_motion.y:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.y.normalized(), gizmo_motion.y)
	elif gizmo_motion.x:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.x.normalized(), gizmo_motion.x)
	elif gizmo_motion.z:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.z.normalized(), gizmo_motion.z)
	
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
	
	# Simpler method
	puzzle.apply_torque_impulse(-1.0 * puzzle.inertia * puzzle.angular_velocity)
	var q := (puzzle_goal * puzzle.basis.inverse()).get_rotation_quaternion()
	var qmotion := q.get_axis() * q.get_angle()
	if not qmotion.is_zero_approx():
		#puzzle.angular_velocity = qmotion / delta
		puzzle.apply_torque_impulse(puzzle.inertia * (qmotion / delta))
	else: # above lacks precision at low angles
		# bellow doesn't work at high angles
		#puzzle.angular_velocity = (puzzle_goal * puzzle.basis.inverse()).get_euler()/delta
		puzzle.apply_torque_impulse(puzzle.inertia * ((puzzle_goal * puzzle.basis.inverse()).get_euler()/delta))
	
	# Tap tap
	if Input.is_action_just_pressed("tap_puzzle"):
		print("tap")
		puzzle.apply_central_impulse(0.3 * puzzle.mass *(puzzle.basis*Vector3.UP))
	
	puzzle.apply_central_force((-0.5 / delta) * puzzle.mass * puzzle.linear_velocity)
	puzzle.apply_central_force((-20 / delta ) * puzzle.mass * puzzle.position)

var gizmo_motion:Vector3
func _on_gizmo_y_dragged(offset: float) -> void:
	gizmo_motion.y = offset

func _on_gizmo_x_dragged(offset: float) -> void:
	gizmo_motion.x = offset

func _on_gizmo_z_dragged(offset: float) -> void:
	gizmo_motion.z = offset

var gizmo_grabbed:bool
func _on_gizmo_grabbed() -> void:
	gizmo_grabbed = true

func _on_gizmo_released() -> void:
	gizmo_grabbed = false
