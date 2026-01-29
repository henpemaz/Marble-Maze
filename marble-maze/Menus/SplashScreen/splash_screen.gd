extends Control

@export_file("*.tscn") var next_scene:String
@export var cutscene_id:StringName

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await $AnimationPlayer.animation_finished
	Progress.cutscene_watched(cutscene_id)
	Progress.save_progress()
	SceneManager.request_scene_switch(next_scene)
	SceneManager.set_fake_loading_time(0.3)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_cancel"):
		if Progress.can_skip_cutscene(cutscene_id):
			if $AnimationPlayer.current_animation_position < ($AnimationPlayer.current_animation_length - 0.5):
				$AnimationPlayer.advance($AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position - 0.5)
				$AudioStreamPlayer.stop()
				get_viewport().set_input_as_handled()
			
