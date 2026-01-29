extends Control

@export var menu_music:AudioStream

func _ready() -> void:
	Progress.reload_progress()
	
	populate_level_buttons()
	populate_items()
	
	MusicPlayer.request_music(menu_music)

func _on_play_button_pressed() -> void:
	if Progress.all_levels_played():
		var with_transition = MenuTransition.new()
		with_transition.do_fadein = true
		with_transition.do_fadeout = false
		$MenuTree.navigate_to_menu($MenuTree/ConfirmRestart, with_transition)
	else:
		Campaign.continue_from_main_menu()

func _on_confirm_pressed() -> void:
	Progress.restart_campaign()
	Progress.save_progress()
	Campaign.continue_from_main_menu()

# called from scenemanager
func on_shutdown():
	print("menu input shutdown")
	set_process_input(false)
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	
func quit():
	get_tree().quit()

@export var levelButton:PackedScene
func populate_level_buttons():
	var count := 0
	for level in Campaign.levels:
		if Progress.get_level_playable(level.id):
			count += 1
			var btn = levelButton.instantiate() as LevelButton
			btn.level = level
			$MenuTree/LevelSelect/PanelContainer/GridContainer.add_child(btn)
			btn.pressed.connect(level_selected.bind(btn))
	if count == 0: $MenuTree/Main/PanelContainer/MainInterface/LevelSelectButton.disabled = true

func level_selected(src:LevelButton):
	Campaign.start_level(src.level.id)

@export var itemButton:PackedScene
func populate_items():
	for item in Campaign.items:
		var btn = itemButton.instantiate() as ItemButton
		btn.item = item
		$MenuTree/Collection/PanelContainer/GridContainer.add_child(btn)
		btn.focus_entered.connect(item_selected.bind(btn))
		btn.mouse_entered.connect(item_selected.bind(btn))

func item_selected(src:ItemButton):
	if Progress.get_item_collected(src.item.id):
		$MenuTree/Collection/Description/Label.text = src.item.description
	else:
		$MenuTree/Collection/Description/Label.text = ""
