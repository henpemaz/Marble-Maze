extends Button
class_name BackButton

@export var tree: MenuTree
@export var with_transition: MenuTransition


func _pressed() -> void:
	tree.navigate_back(with_transition)
