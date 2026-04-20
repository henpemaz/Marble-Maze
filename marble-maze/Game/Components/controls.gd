extends Node3D

@export var puzzle: StaticBody3D
@export var pebble: RigidBody3D
@export var camera_pivot: Node3D
@export var sphere_gizmo: Area3D
@export var gizmos_root: Node3D
var gizmos:Array[Gizmo]

@export var cam_pan_speed := 0.003
@export var puzzle_pan_speed := 0.003

@export_range(-90, 0, 0.1, "radians_as_degrees") var cam_pitch_min := -80.0
@export_range(0, 90, 0.1, "radians_as_degrees") var cam_pitch_max := 70.0

@export var puzzle_damping := 30.0
@export var puzzle_spring_force := 1000.0
@export var puzzle_tap_amount := 0.5

enum InputMode{
	CAMERA_RELATIVE,
	SPHERE_RELATIVE_WORLD_UP,
	SPHERE_RELATIVE_PUZZLE_UP,
	SPHERE_RELATIVE_CAM_UP,
	SPHERE_RELATIVE_LOCAL_UP,
	
}
@export var input_mode:InputMode = InputMode.CAMERA_RELATIVE

var puzzle_motion:Vector2
var camera_motion:Vector2

func _ready() -> void:
	gizmos.assign(gizmos_root.find_children("*", "Gizmo", false, true))

func _raycast_for_area(mask:int):
	# manual ray-pick
	var mouse_position := get_viewport().get_mouse_position()
	var camera := get_viewport().get_camera_3d()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal, mask)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	# TODO filter with mask
	
	return space_state.intersect_ray(query)

var click_sphere_basis:Basis

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pan_puzzle"):
		if event.is_pressed():
			click_sphere_basis = Basis.IDENTITY
			var result = _raycast_for_area(LayerNames.PHYSICS_3D.GIZMO_BIT)
			if result:
				if result["collider"] is Gizmo:
					result["collider"].input_picked()
				if result["collider"] == sphere_gizmo:
					click_sphere_basis = Basis.looking_at(-result["normal"])
					_on_sphere_grabbed()
	
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("pan_puzzle"):
			if not gizmo_grabbed:
				puzzle_motion += event.screen_relative * puzzle_pan_speed
		elif Input.is_action_pressed("pan_camera"):
			camera_motion -= event.screen_relative * cam_pan_speed

func _process(_delta: float) -> void:
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x + camera_motion.y, cam_pitch_min, cam_pitch_max)
	camera_pivot.rotation.y += camera_motion.x
	camera_motion = Vector2.ZERO

var puzzle_goal:Basis
var puzzle_offset:Vector3
var puzzle_velocity:Vector3
func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("pan_puzzle") && sphere_grabbed:
		_on_sphere_released()
	
	if puzzle_motion:
		var frame_of_reference:Basis
		# TODO scale
		match input_mode:
			InputMode.CAMERA_RELATIVE:
				frame_of_reference = get_viewport().get_camera_3d().global_basis
			InputMode.SPHERE_RELATIVE_WORLD_UP,InputMode.SPHERE_RELATIVE_PUZZLE_UP,InputMode.SPHERE_RELATIVE_CAM_UP, InputMode.SPHERE_RELATIVE_LOCAL_UP:
				var result = _raycast_for_area(LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT if sphere_grabbed else LayerNames.PHYSICS_3D.GIZMO_BIT)
				if result && result["collider"] == sphere_gizmo:
					match input_mode:
						InputMode.SPHERE_RELATIVE_WORLD_UP:
							frame_of_reference = Basis.looking_at(-result["normal"], Vector3.UP)
						InputMode.SPHERE_RELATIVE_PUZZLE_UP:
							frame_of_reference = Basis.looking_at(-result["normal"], puzzle.global_basis.y)
						InputMode.SPHERE_RELATIVE_CAM_UP:
							frame_of_reference = Basis.looking_at(-result["normal"], get_viewport().get_camera_3d().global_basis.y)
						InputMode.SPHERE_RELATIVE_LOCAL_UP:
							frame_of_reference = Basis.looking_at(-result["normal"], click_sphere_basis.y)
				else:
					frame_of_reference = get_viewport().get_camera_3d().global_basis
				
			
		var change := Basis()
		change = change.rotated(Vector3.RIGHT, puzzle_motion.y)
		change = change.rotated(Vector3.UP, puzzle_motion.x)
		puzzle_goal = frame_of_reference * change * frame_of_reference.inverse() * puzzle_goal
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

var sphere_grabbed:bool
func _on_sphere_grabbed()->void:
	print("sphere grabbed")
	sphere_grabbed = true
	sphere_gizmo.collision_layer |= LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT
	_lock_all_gizmos()
	
func _on_sphere_released()->void:
	sphere_grabbed = false
	sphere_gizmo.collision_layer &= ~LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT
	_unlock_all_gizmos()

var gizmo_grabbed:bool
func _on_gizmo_grabbed() -> void:
	gizmo_grabbed = true
	_lock_all_gizmos()

func _on_gizmo_released() -> void:
	gizmo_grabbed = false
	_unlock_all_gizmos()

func _lock_all_gizmos():
	for g in gizmos:
		g.locked = true
		
func _unlock_all_gizmos():
	for g in gizmos:
		g.locked = false
