extends Button
class_name ItemButton

@export var item:Item
@onready var texture_rect: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Progress.get_item_collected(item.id):
		texture_rect.texture = await AsyncResource.load(item.preview_path)
