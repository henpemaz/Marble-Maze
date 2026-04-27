extends RigidBody3D

@export var loop_slow: AudioStreamPlayer3D
@export var loop_fast: AudioStreamPlayer3D
@export var impact: AudioStreamPlayer3D

@export var slow_loop_curve:Curve
@export var fast_loop_curve:Curve


func _ready() -> void:
	loop_slow.volume_linear = 0
	loop_fast.volume_linear = 0
	
	loop_slow.play()
	loop_fast.play()


func _physics_process(delta: float) -> void:
	if get_contact_count() > 0:
		var state = PhysicsServer3D.body_get_direct_state(get_rid())
		var other_speed = state.get_contact_collider_velocity_at_position(0)
		var rel_speed = (linear_velocity - other_speed).length()
		loop_slow.volume_linear = slow_loop_curve.sample_baked(rel_speed)
		loop_fast.volume_linear = fast_loop_curve.sample_baked(rel_speed)
		print(rel_speed)
	else:
		loop_slow.volume_linear = 0
		loop_fast.volume_linear = 0
		

func _on_body_entered(body: Node) -> void:
	impact.play()
	print("impact")
