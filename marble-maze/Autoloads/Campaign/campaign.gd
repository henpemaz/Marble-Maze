extends Node

@export_file("*.tscn") var main_menu_scene

@export var levels:Array[Level]
@export var current_level:Level

@export var items:Array[Item]

func continue_from_main_menu():
	if Progress.get_latest_level() != "":
		start_level(Progress.get_latest_level())
	else:
		start_level(get_first_level())

func continue_from_level():
	start_level(get_next_level(current_level.id).id)

func start_level(with_id:StringName)->void:
	current_level = get_level(with_id)
	Progress.level_started(with_id)
	Progress.save_progress()
	SceneManager.request_scene_switch(current_level.game_scene)
	SceneManager.set_fake_loading_time(0.4)

func level_completed():
	Progress.level_completed(current_level.id)
	Progress.save_progress()

func restart_level():
	Progress.reload_progress()
	SceneManager.request_scene_switch(current_level.game_scene)
	
func quit_to_menu():
	Progress.reload_progress()
	SceneManager.request_scene_switch(main_menu_scene)
	SceneManager.set_fake_loading_time(0.2)

func get_level(id:StringName)->Level: return levels.get(levels.find_custom(func(l:Level)->bool: return l.id==id))

func get_first_level()->StringName:
	return levels[0].id

func get_next_level(id:StringName)->Level:
	var at := levels.find_custom(func(l:Level)->bool: return l.id==id)
	if levels.size() <= at+1: return null
	return levels.get(at+1)

func get_item(with_id:StringName)->Item: return items.get(items.find_custom(func(i:Item)->bool: return i.id==with_id))
