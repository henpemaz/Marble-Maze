extends Node3D

@export var puzzle: RigidBody3D
@export var camera_pivot: Node3D

@export var cam_speed := 0.02
@export var puzzle_speed := 0.02

@export_range(-90, 0, 0.1, "radians_as_degrees") var cam_pitch_min := -80.0
@export_range(0, 90, 0.1, "radians_as_degrees") var cam_pitch_max := 70.0

var puzzle_motion:Vector2
var camera_motion:Vector2

func _ready() -> void:
	# ain't godot just stupid
	puzzle.inertia = PhysicsServer3D.body_get_direct_state(puzzle.get_rid()).inverse_inertia.inverse()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pan_puzzle") && event.is_pressed():
		# manually ray-pick me
		var mouse_position := get_viewport().get_mouse_position()
		var camera := get_viewport().get_camera_3d()
		var ray_origin := camera.project_ray_origin(mouse_position)
		var ray_normal := camera.project_ray_normal(mouse_position)
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal)
		query.collide_with_areas = true
		
		var result = space_state.intersect_ray(query)
		if result && result["collider"] is Gizmo:
			result["collider"].input_picked(mouse_position)
	
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
	
	puzzle.apply_torque_impulse(-1.0 * puzzle.inertia * puzzle.angular_velocity)
	if Input.is_action_just_pressed("tap_puzzle"):
		print(puzzle.angular_velocity)
	
	var change2 := (puzzle_goal * puzzle.basis.inverse())
	var q := change2.get_rotation_quaternion()
	var qmotion := q.get_axis() * q.get_angle()
	if not qmotion.is_zero_approx():
		puzzle.apply_torque_impulse(puzzle.inertia * (qmotion / delta))
	else: # above lacks precision at low angles
		# bellow doesn't work at high angles
		puzzle.apply_torque_impulse(puzzle.inertia * (change2.get_euler()/delta))
	
	# Tap tap
	#if Input.is_action_just_pressed("tap_puzzle"):
		#print("tap")
		#puzzle.apply_central_impulse(0.3 * puzzle.mass *(puzzle.basis*Vector3.UP))
	
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
