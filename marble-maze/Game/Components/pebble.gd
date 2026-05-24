extends RigidBody3D

@export var loop_slow: AudioStreamPlayer3D
@export var loop_fast: AudioStreamPlayer3D
@export var impact: AudioStreamPlayer3D

@export var slow_loop_curve:Curve
@export var slow_loop_pitch_curve:Curve
@export var fast_loop_curve:Curve
@export var fast_loop_pitch_curve:Curve


func _ready() -> void:
	loop_slow.volume_linear = 0
	loop_fast.volume_linear = 0
	
	loop_slow.play()
	loop_fast.play()

@export var roll_speed_reference := 1.0
@export var roll_volume_mult := 1.0

func _physics_process(delta: float) -> void:
	if get_contact_count() > 0:
		var state = PhysicsServer3D.body_get_direct_state(get_rid())
		var other_speed = state.get_contact_collider_velocity_at_position(0)
		var rel_speed = (linear_velocity - other_speed).length() / roll_speed_reference
		loop_slow.volume_db = -60.0 + 60.0 * roll_volume_mult * slow_loop_curve.sample_baked(rel_speed)
		loop_fast.volume_db = -60.0 + 60.0 * roll_volume_mult * fast_loop_curve.sample_baked(rel_speed)
		loop_slow.pitch_scale = slow_loop_pitch_curve.sample(rel_speed)
		loop_fast.pitch_scale = fast_loop_pitch_curve.sample(rel_speed)
		#print(rel_speed)
	else:
		loop_slow.volume_linear = 0
		loop_fast.volume_linear = 0
	
	if queue_impact:
		impact_playback.play_stream(impact_sound, 
			0, 
			-60.0 + 60.0 * impact_volume_curve.sample_baked(queue_impact), 
			impact_pitch_curve.sample_baked(queue_impact), 
			AudioServer.PlaybackType.PLAYBACK_TYPE_DEFAULT,
			&"Sfx")
		queue_impact = 0.0

func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	var dir := linear_velocity.normalized()
	var state = PhysicsServer3D.body_get_direct_state(get_rid())
	for i in state.get_contact_count():
		if state.get_contact_collider(i) == body_rid && state.get_contact_collider_shape(i) == body_shape_index:
			var impulse := state.get_contact_impulse(i).project(dir).length() * 10
			if impulse < 0.1: continue
			queue_impact = maxf(queue_impact, impulse)

var queue_impact : float
@onready var impact_playback:AudioStreamPlaybackPolyphonic = impact.get_stream_playback() 
@export var impact_sound: AudioStreamWAV
@export var impact_volume_curve:Curve
@export var impact_pitch_curve:Curve
