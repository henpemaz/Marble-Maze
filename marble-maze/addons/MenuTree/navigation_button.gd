extends Button
class_name NavigationButton

@export var tree: MenuTree
@export var to_menu: Control
@export var with_transition: MenuTransition


func _pressed() -> void:
	tree.navigate_to_menu(to_menu, with_transition)
