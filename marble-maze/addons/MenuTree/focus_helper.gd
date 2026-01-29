extends Control
class_name FocusHelper


func _ready() -> void:
	visibility_changed.connect(_vischanged)
	_vischanged()

func _vischanged():
	if is_visible_in_tree():
		if get_viewport().gui_get_focus_owner() == null:
			get_parent_control().grab_focus()
