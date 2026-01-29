extends Node

@onready var pause_pannel: Panel = $UI/PauseScreen
@onready var win_pannel: Panel = $UI/WinPannel
@onready var lose_pannel: Panel = $UI/LosePannel

@export var music:AudioStream

@export var credits_cutscene_id:StringName

func _ready() -> void:
	MusicPlayer.request_music(music)

var paused := false
var frozen := false
func pause() -> void:
	if frozen: return
	print("pause")
	paused = true
	_freeze_gameplay()
	pause_pannel.show()
	
func unpause():
	if frozen: return
	print("unpause")
	paused = false
	_unfreeze_gameplay()
	pause_pannel.hide()

func win():
	frozen = true
	_freeze_gameplay()
	Campaign.level_completed()
	if Campaign.get_next_level(Campaign.current_level.id) == null:
		$UI/WinPannel/Main/HBoxContainer/ContinueButton.hide()
		win_pannel.show()
		await run_credits()
	else:
		win_pannel.show()

func lose():
	frozen = true
	_freeze_gameplay()
	lose_pannel.show()

func run_credits():
	$UI/WinPannel/AnimationPlayer.play("roll_credits")
	await $UI/WinPannel/AnimationPlayer.animation_finished
	Progress.cutscene_watched(credits_cutscene_id)
	Progress.save_progress()

func restart():
	Campaign.restart_level()

func quit_to_menu():
	Campaign.quit_to_menu()

func to_next_level():
	Campaign.continue_from_level()

func _freeze_gameplay():
	#$Gameplay.process_mode = Node.PROCESS_MODE_DISABLED
	$Gameplay.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _unfreeze_gameplay():
	#$Gameplay.process_mode = Node.PROCESS_MODE_INHERIT
	$Gameplay.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not paused:
			pause()
			get_viewport().set_input_as_handled()
			return
			
	if event.is_action_pressed("ui_accept") || event.is_action_pressed("ui_cancel"):
		if $UI/WinPannel/AnimationPlayer.current_animation != "":
			if Progress.can_skip_cutscene(credits_cutscene_id):
				if $UI/WinPannel/AnimationPlayer.current_animation_position < ($UI/WinPannel/AnimationPlayer.current_animation_length - 0.5):
					$UI/WinPannel/AnimationPlayer.advance($UI/WinPannel/AnimationPlayer.current_animation_length - $UI/WinPannel/AnimationPlayer.current_animation_position - 0.5)
					get_viewport().set_input_as_handled()
					return
