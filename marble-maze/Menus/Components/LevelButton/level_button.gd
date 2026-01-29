extends Button
class_name LevelButton

@export var level:Level
@onready var texture_rect: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_rect.texture = await AsyncResource.load(level.preview_path)
