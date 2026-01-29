extends Node

var latest_level:StringName
var played_levels:Dictionary[StringName,LevelProgress]
var items_found:Array[StringName]
var cutscenes_watched:Array[StringName]

class LevelProgress:
	var started:bool
	var finished:bool
	
	func to_dictionary()->Dictionary[String,Variant]:
		return {
			"started":started, 
			"finished":finished
		}
	func from_dictionary(dict:Dictionary):
		started = dict["started"]
		finished = dict["finished"]

func to_dictionary()->Dictionary[String,Variant]:
	var levels_dictionary = {} # wish we had list-comprehension
	for level in played_levels:
		levels_dictionary[level] = played_levels[level].to_dictionary()
	return {
		"latest_level":latest_level,
		"played_levels":levels_dictionary,
		"items_found":items_found,
		"cutscenes_watched":cutscenes_watched,
	}

func from_dictionary(dict:Dictionary):
	latest_level = dict["latest_level"]
	items_found.assign(dict["items_found"])
	cutscenes_watched.assign(dict["cutscenes_watched"])
	var levels_dictionary = dict["played_levels"]
	for level in levels_dictionary:
		played_levels[level] = LevelProgress.new()
		played_levels[level].from_dictionary(levels_dictionary[level])

func _ready() -> void:
	reload_progress()

func get_latest_level()->StringName:
	return latest_level

func get_level_playable(id:StringName):
	return id == latest_level || (id in played_levels && played_levels[id].started)

func all_levels_played()->bool:
	if latest_level == "": return false
	if latest_level not in played_levels: return false
	if played_levels[latest_level].finished == false: return false
	return Campaign.get_next_level(latest_level) == null

func level_started(with_id:StringName):
	if with_id not in played_levels:
		played_levels[with_id] = LevelProgress.new()
	
	if latest_level == "":
		latest_level = with_id
	
	played_levels[with_id].started = true

func level_completed(with_id:StringName):
	played_levels[with_id].finished = true
	
	if with_id == latest_level:
		var next_level = Campaign.get_next_level(with_id)
		if next_level != null:
			latest_level = next_level.id

func restart_campaign():
	latest_level = ""
	for level in played_levels:
		played_levels[level].started = false
		played_levels[level].finished = false

func item_collected(item_id:StringName):
	if item_id != "" && item_id not in items_found:
		items_found.append(item_id)

func get_item_collected(item_id:StringName)->bool:
	return item_id in items_found
	

func cutscene_watched(cutscene_id:StringName):
	if cutscene_id != "" && cutscene_id not in cutscenes_watched:
		cutscenes_watched.append(cutscene_id)

func can_skip_cutscene(cutscene_id:StringName)->bool:
	return cutscene_id in cutscenes_watched


func reload_progress():
	if FileAccess.file_exists("user://savegame.save"):
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var json_string = save_file.get_as_text()
		print("reading")
		print(JSON.parse_string(json_string))
		from_dictionary(JSON.parse_string(json_string))

func save_progress():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var json_string = JSON.stringify(to_dictionary(), "  ", false)
	print("writing")
	print(json_string)
	save_file.store_line(json_string)
