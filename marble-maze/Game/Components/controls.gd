extends Node3D

@export var puzzle: StaticBody3D
@export var pebble: RigidBody3D
@export var camera_pivot: Node3D
@export var gizmos_root: Node3D
var gizmos:Array[Gizmo]
@export var trackball_area: Area3D

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
	ARCBALL,
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
var click_puzzle_basis:Basis

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("pan_puzzle"):
		if event.is_pressed():
			click_sphere_basis = Basis.IDENTITY
			var result = _raycast_for_area(LayerNames.PHYSICS_3D.GIZMO_BIT)
			if result && result["collider"] is Gizmo:
				result["collider"].input_picked()
			else:
				result = _raycast_for_area(LayerNames.PHYSICS_3D.TRACKBALL_BIT)
				var local_normal = (result["position"] - puzzle.global_position).normalized()
				click_sphere_basis = Basis.looking_at(-local_normal, get_viewport().get_camera_3d().global_basis.y)
				click_puzzle_basis = puzzle.global_basis
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

@export var angular_max_speed:float = 1.0
@export var angular_accel:float = 8.0
@export var aa_epsylon:float = 0.001

func snap_motion_to_axis(motion:Vector3, orientation:Basis)->Vector3:
	if not motion.is_zero_approx():
		var qx := Plane(orientation.x)
		var qy := Plane(orientation.y)
		var qz := Plane(orientation.z)
		var max_snap_angle_cos := 0.707
		for plane:Plane in [qx, qy, qz]:
			if motion.is_zero_approx():
				continue
			# X rotation snap
			if not is_zero_approx(motion.x) and abs(plane.normal.dot(Vector3.UP)) > max_snap_angle_cos:
				if plane.has_point(Vector3.FORWARD, aa_epsylon):
					motion.x = 0
				elif plane.is_point_over(Vector3.FORWARD) != plane.is_point_over(Vector3.FORWARD.rotated(motion.normalized(), -motion.length())):
					var goal = Vector3.FORWARD.slide(plane.normal) # innacurate but doesn't overshoot
					motion.x = goal.signed_angle_to(Vector3.FORWARD, Vector3.RIGHT)
			# Z rotation snap
			if not is_zero_approx(motion.z) and abs(plane.normal.dot(Vector3.UP)) > max_snap_angle_cos:
				if plane.has_point(Vector3.RIGHT, aa_epsylon):
					motion.z = 0
				elif plane.is_point_over(Vector3.RIGHT) != plane.is_point_over(Vector3.RIGHT.rotated(motion.normalized(), -motion.length())):
					var goal = Vector3.RIGHT.slide(plane.normal)
					motion.z = goal.signed_angle_to(Vector3.RIGHT, Vector3.BACK)
			# Y rotation snap
			if not is_zero_approx(motion.y) and abs(plane.normal.dot(Vector3.RIGHT)) > max_snap_angle_cos:
				if plane.has_point(Vector3.BACK, aa_epsylon):
					motion.y = 0
				elif plane.is_point_over(Vector3.BACK) != plane.is_point_over(Vector3.BACK.rotated(motion.normalized(), -motion.length())):
					var goal = Vector3.BACK.slide(plane.normal)
					motion.y = goal.signed_angle_to(Vector3.BACK, Vector3.UP)
	return motion

var puzzle_goal:Basis
var puzzle_offset:Vector3
var puzzle_velocity:Vector3
var puzzle_angular_velocity:Vector3
func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("pan_puzzle") && sphere_grabbed:
		_on_sphere_released()
	
	var ground_relative_basis:Basis = Basis(camera_pivot.basis.x, Vector3.UP, camera_pivot.basis.x.cross(Vector3.UP).normalized())
	var local_velocity := ground_relative_basis.inverse()*puzzle_angular_velocity
	var local_input := Vector3(Input.get_axis("turn_forward", "turn_backwards"),
		Input.get_axis("twist_right", "twist_left"),
		Input.get_axis("turn_right", "turn_left"))
	local_velocity = local_velocity.move_toward(local_input*angular_max_speed, delta*angular_accel)
	if Input.is_action_pressed("align"):
		local_velocity = snap_motion_to_axis(local_velocity*delta, (ground_relative_basis.inverse() * puzzle.basis).orthonormalized()) / delta
	puzzle_angular_velocity = ground_relative_basis*local_velocity
	
	if puzzle_motion:
		var frame_of_reference:Basis
		var change := Basis()
		match input_mode:
			InputMode.CAMERA_RELATIVE:
				frame_of_reference = get_viewport().get_camera_3d().global_basis
				change = change.rotated(Vector3.RIGHT, puzzle_motion.y)
				change = change.rotated(Vector3.UP, puzzle_motion.x)
				puzzle_goal = frame_of_reference * change * frame_of_reference.inverse() * puzzle_goal
			InputMode.SPHERE_RELATIVE_WORLD_UP,InputMode.SPHERE_RELATIVE_PUZZLE_UP,InputMode.SPHERE_RELATIVE_CAM_UP, InputMode.SPHERE_RELATIVE_LOCAL_UP:
				var result = _raycast_for_area(LayerNames.PHYSICS_3D.TRACKBALL_BIT)
				if result && result["collider"] == trackball_area:
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
				change = change.rotated(Vector3.RIGHT, puzzle_motion.y)
				change = change.rotated(Vector3.UP, puzzle_motion.x)
				puzzle_goal = frame_of_reference * change * frame_of_reference.inverse() * puzzle_goal
			InputMode.ARCBALL:
				var result = _raycast_for_area(LayerNames.PHYSICS_3D.TRACKBALL_BIT)
				if result:
					var a := click_sphere_basis.z
					var b:Vector3 = (result["position"] - puzzle.global_position).normalized()
					var c := a.cross(b).normalized()
					if not c.is_zero_approx():
						var angle := a.angle_to(b)
						if Input.is_action_pressed("align"):
							var local_motion := ground_relative_basis.inverse()*(c*angle)
							local_motion = snap_motion_to_axis(local_motion, (ground_relative_basis.inverse() * click_puzzle_basis))
							var motion := ground_relative_basis*local_motion
							if not motion.is_zero_approx():
								puzzle_goal = click_puzzle_basis.rotated(motion.normalized(), motion.length())
						else:
							puzzle_goal = click_puzzle_basis.rotated(c, angle)
				else:
					print("miss????")
		puzzle_motion = Vector2.ZERO
	
	if Input.is_action_pressed("align"):
		gizmo_motion = snap_motion_to_axis(gizmo_motion, (ground_relative_basis.inverse() * puzzle.basis))
		
	if gizmo_motion:
		if gizmo_motion.y:
			puzzle_goal = puzzle_goal.rotated(puzzle_goal.y.normalized(), gizmo_motion.y)
		if gizmo_motion.x:
			puzzle_goal = puzzle_goal.rotated(puzzle_goal.x.normalized(), gizmo_motion.x)
		if gizmo_motion.z:
			puzzle_goal = puzzle_goal.rotated(puzzle_goal.z.normalized(), gizmo_motion.z)
		gizmo_motion = Vector3.ZERO
	
	## Tap tap
	if Input.is_action_just_pressed("tap_puzzle"):
		print("tap")
		var dir := closest_up_direction(puzzle.basis)
		puzzle_velocity += dir * puzzle_tap_amount
		pebble.apply_impulse(dir * (pebble.mass * pebble.gravity_scale * puzzle_tap_amount))
	
	puzzle_velocity *= (1 - (puzzle_damping * delta))
	puzzle_velocity -= puzzle_offset * (puzzle_spring_force * delta)
	puzzle_offset += puzzle_velocity * delta
	
	if not puzzle_angular_velocity.is_zero_approx():
		puzzle_goal = puzzle_goal.rotated(puzzle_angular_velocity.normalized(), puzzle_angular_velocity.length() * delta)
	
	# godot moment: AnimatableBody3D's transform can only be assigned once per tick
	puzzle.transform = Transform3D(puzzle_goal, puzzle_offset)

func closest_up_direction(rotated:Basis)->Vector3:
	var dirs:Array[Vector3] = [rotated.y, -rotated.y, rotated.z, -rotated.z, rotated.x, -rotated.x]
	var vals := dirs.map(func (v): return v.dot(Vector3.UP))
	# Godot has nothing for returning the index of the maximun value, just rocks and sticks
	return dirs[vals.find(vals.max())]

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
	_lock_all_gizmos()
	
func _on_sphere_released()->void:
	print("sphere released")
	sphere_grabbed = false
	_unlock_all_gizmos()

var gizmo_grabbed:bool
func _on_gizmo_grabbed() -> void:
	print("gizmo grabbed")
	gizmo_grabbed = true
	_lock_all_gizmos()

func _on_gizmo_released() -> void:
	print("gizmo released")
	gizmo_grabbed = false
	_unlock_all_gizmos()

func _lock_all_gizmos():
	for g in gizmos:
		g.locked = true
		
func _unlock_all_gizmos():
	for g in gizmos:
		g.locked = false
