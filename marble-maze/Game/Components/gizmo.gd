extends Area3D
class_name Gizmo

@export var mesh:TorusMesh
@export var material:StandardMaterial3D
@export var shape:CylinderShape3D

@export_range(0,0.4,0.00001) var base_size:float = 0.1605
@export_range(0,0.01,0.00005) var min_swell:float = 0.001
@export_range(0,0.01,0.00005) var max_swell:float = 0.004

@export var inactive_alpha := 0.2
@export var hover_alpha := 0.5
@export var active_alpha := 1.0

@export var debug:bool

signal dragged(offset:float)
signal gizmo_grabbed
signal gizmo_released

func _ready() -> void:
	update_graphics()

# called by controls 
func input_picked():
	grabbed_at_position(get_viewport().get_mouse_position())

func _physics_process(_delta: float) -> void:
	if grabbed:
		if not Input.is_action_pressed("pan_puzzle"): # if mouse drags out of window we never get the event???
			grabbed = false
			released()
		else:
			new_grab_position(get_viewport().get_mouse_position())

var original_shape_height:float
var plane:Plane
var grabbed_from_side:bool
var grabbed_point:Vector3
func grabbed_at_position(mouse_position:Vector2):
	grabbed = true
	plane = Plane(global_basis.y, global_transform.origin)
	collision_layer |= LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT
	
	original_shape_height = shape.height
	var camera := get_viewport().get_camera_3d()
	if abs(camera.global_basis.z.dot(global_basis.y)) < 0.2: # from side
		if debug: print("dragged from side!")
		grabbed_from_side = true
		shape.height = 1 # extend
	else:
		if debug: print("dragged from front!")
		grabbed_from_side = false
		shape.height = 0.0 # shrimk
	
	grabbed_point = point_of_mouse(mouse_position, grabbed_from_side)
	
	update_graphics()
	gizmo_grabbed.emit()
	
	if debug: print("dragged!")

func released():
	grabbed = false
	collision_layer &= ~LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT
	shape.height = original_shape_height
	update_graphics()
	
	gizmo_released.emit()
	
	if debug: print("released!")

func new_grab_position(mouse_position:Vector2):
	var new_grabbed_point := point_of_mouse(mouse_position, grabbed_from_side)
	var angle_offset := grabbed_point.signed_angle_to(new_grabbed_point, Vector3.UP)
	dragged.emit(angle_offset)
	if debug: print(angle_offset)

func point_of_mouse(mouse_position:Vector2, cylinder_only:bool)->Vector3:
	var camera := get_viewport().get_camera_3d()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_normal := camera.project_ray_normal(mouse_position)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal, LayerNames.PHYSICS_3D.ACTIVE_GIZMO_BIT)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var hit:Vector3 = global_transform.inverse() * result["position"]
		hit.y = 0
		if debug: print("shape hit")
		if debug: print(hit)
		return hit
	if cylinder_only: # cilinder only
		return Vector3.ZERO
		
	result = plane.intersects_ray(ray_origin, ray_normal)
	if result:
		var hit:Vector3 = global_transform.inverse() * result
		hit.y = 0
		if debug: print("plane hit")
		if debug: print(hit)
		return hit
	
	if debug: push_error("no result")
	return Vector3.ZERO


func _mouse_enter() -> void:
	hover = true

func _mouse_exit() -> void:
	hover = false


var grabbed:bool:
	set(val):
		grabbed = val
		update_graphics()

var locked:bool:
	set(val):
		locked = val
		update_graphics()

var hover:bool:
	set(val):
		hover = val
		update_graphics()

var swell:float:
	set(val):
		swell = val
		mesh.inner_radius = base_size - lerp(min_swell, max_swell, swell)
		mesh.outer_radius = base_size + lerp(min_swell, max_swell, swell)

var alpha:float:
	set(val):
		alpha = val
		material.albedo_color.a = val

func update_graphics():
	if grabbed:
		swell = 1
		alpha = active_alpha
	elif locked:
		swell = 0
		alpha = inactive_alpha
	elif hover:
		swell = 1
		alpha = hover_alpha
	else:
		swell = 0
		alpha = inactive_alpha
