extends Node3D

@export var puzzle: StaticBody3D
@export var pebble: RigidBody3D
@export var camera_pivot: Node3D

@export var cam_pan_speed := 0.003
@export var puzzle_pan_speed := 0.003

@export_range(-90, 0, 0.1, "radians_as_degrees") var cam_pitch_min := -80.0
@export_range(0, 90, 0.1, "radians_as_degrees") var cam_pitch_max := 70.0

@export var puzzle_damping := 30.0
@export var puzzle_spring_force := 1000.0
@export var puzzle_tap_amount := 0.5

var puzzle_motion:Vector2
var camera_motion:Vector2

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

func _process(_delta: float) -> void:
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x + camera_motion.y * cam_pan_speed, cam_pitch_min,cam_pitch_max)
	camera_pivot.rotation.y += camera_motion.x * cam_pan_speed
	camera_motion = Vector2.ZERO

var puzzle_goal:Basis
var puzzle_offset:Vector3
var puzzle_velocity:Vector3
func _physics_process(delta: float) -> void:
	if puzzle_motion:
		var change := Basis()
		change = change.rotated(Vector3.RIGHT, puzzle_motion.y * puzzle_pan_speed)
		change = change.rotated(Vector3.UP, puzzle_motion.x * puzzle_pan_speed)
		puzzle_goal = camera_pivot.basis * change * camera_pivot.basis.inverse() * puzzle_goal
	elif gizmo_motion.y:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.y.normalized(), gizmo_motion.y)
	elif gizmo_motion.x:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.x.normalized(), gizmo_motion.x)
	elif gizmo_motion.z:
		puzzle_goal = puzzle_goal.rotated(puzzle_goal.z.normalized(), gizmo_motion.z)
	
	puzzle_motion = Vector2.ZERO
	gizmo_motion = Vector3.ZERO
	
	## Tap tap
	if Input.is_action_just_pressed("tap_puzzle"):
		print("tap")
		puzzle_velocity += puzzle.basis.y * puzzle_tap_amount
		pebble.apply_impulse(puzzle.basis.y * (pebble.mass * pebble.gravity_scale * puzzle_tap_amount))
	
	puzzle_velocity *= (1 - (puzzle_damping * delta))
	puzzle_velocity -= puzzle_offset * (puzzle_spring_force * delta)
	puzzle_offset += puzzle_velocity * delta
	
	# godot moment: AnimatableBody3D's transform can only be assigned once per tick
	puzzle.transform = Transform3D(puzzle_goal, puzzle_offset)

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
