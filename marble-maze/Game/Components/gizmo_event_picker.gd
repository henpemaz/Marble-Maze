extends Node3D

# this is here so gizmo-picking has higher priority than the controls (input is propagated bottom-up)
func _input(event: InputEvent) -> void:
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
