extends Area3D


@export var mesh:TorusMesh
@export var material:Material
@export var shape:CylinderShape3D

@export var active_gizmo_layer:int = 1<<15

@export_range(0,0.4,0.00001) var base_size:float = 0.1605
@export_range(0,0.01,0.00005) var min_swell:float = 0.001
@export_range(0,0.01,0.00005) var max_swell:float = 0.004

signal dragged(offset:float)
signal gizmo_grabbed
signal gizmo_released

var grabbed:bool
func _input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event.is_action("pan_puzzle"):
		if grabbed != event.is_pressed(): # so we don't eat release-events on accident
			grabbed = event.is_pressed()
			if grabbed:
				grabbed_at_position(get_viewport().get_mouse_position())
			else:
				released()
			get_viewport().set_input_as_handled()
			return
			
	if grabbed:
		if event is InputEventMouseMotion:
			new_grab_position(get_viewport().get_mouse_position())


var original_shape_height:float
var plane:Plane
var grabbed_point:Vector3
func grabbed_at_position(mouse_position:Vector2):
	plane = Plane(global_transform.inverse()*Vector3.UP, global_transform.origin)
	collision_layer |= active_gizmo_layer
	original_shape_height = shape.height
	shape.height = 1 # grow
	
	grabbed_point = point_of_mouse(mouse_position)
	
	gizmo_grabbed.emit()
	
	print("dragged!")

func released():
	collision_layer &= ~active_gizmo_layer
	shape.height = original_shape_height
	
	gizmo_released.emit()
	
	print("released!")

func new_grab_position(mouse_position:Vector2):
	var new_grabbed_point := point_of_mouse(mouse_position)
	var angle_offset := grabbed_point.signed_angle_to(new_grabbed_point, Vector3.UP)
	dragged.emit(angle_offset)
	print(angle_offset)


func point_of_mouse(mouse_position:Vector2)->Vector3:
	var camera := get_viewport().get_camera_3d()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal, active_gizmo_layer)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var hit:Vector3 = global_transform.inverse() * result["position"]
		hit.y = 0
		print("shape hit")
		print(hit)
		return hit
	
	result = plane.intersects_ray(ray_origin, ray_normal)
	if result:
		var hit:Vector3 = global_transform.inverse() * result
		hit.y = 0
		print("plane hit")
		print(hit)
		return hit
	
	push_error("no result")
	return Vector3.ZERO


var swell:float:
	set(val):
		swell = val
		mesh.inner_radius = base_size - lerp(min_swell, max_swell, swell)
		mesh.outer_radius = base_size + lerp(min_swell, max_swell, swell)

func _mouse_enter() -> void:
	swell = 1

func _mouse_exit() -> void:
	swell = 0
