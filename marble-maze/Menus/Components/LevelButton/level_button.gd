extends Button
class_name LevelButton

@export var level:Level
@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	if level.preview_path:
		texture_rect.texture = await AsyncResource.load(level.preview_path)
