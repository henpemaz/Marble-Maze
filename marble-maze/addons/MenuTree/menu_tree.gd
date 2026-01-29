extends Control
class_name MenuTree

@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "MenuTransition")
var default_transition: MenuTransition
@export var entry_point: Control

@export var handle_focus:=true
@export var handle_back_input:=true
@export var restore_focus_on_back:=true

signal back

var _current: Control
var _focus_active: bool = false
var _focus_target: Control
var _stack: Array[Control]
var _animation_stack: Array[MenuTransition]
var _focus_stack: Array[Control]
var _animator: AnimationPlayer


func _ready() -> void:
	assert(default_transition)
	assert(entry_point)
	_animator = find_child("AnimationPlayer", false)
	_current = entry_point
	if _stack.is_empty() || _current != _stack.back():
		_stack.push_back(_current)
		_animation_stack.push_back(null)
		_focus_stack.push_back(null)

func navigate_to_menu(to_menu:Control, with_transition:MenuTransition)->void:
	print("navigate! " + str(to_menu))
	if to_menu == _current:
		push_error("to_menu is current: " + str(to_menu))
		return
	var from_menu = _current
	if with_transition == null:
		with_transition = default_transition
	
	_stack.push_back(to_menu)
	_animation_stack.push_back(with_transition)
	_focus_stack.push_back(get_viewport().gui_get_focus_owner())
	_focus_target = null
	_focus_active = _focus_stack.back() != null
	
	_current = to_menu
	_do_transition(from_menu, to_menu, with_transition)

func navigate_back(with_transition:MenuTransition)->void:
	print("navigate back!")
	if _stack.size() < 2:
		back.emit()
		return
		
	var to_menu:Control = _stack[-2]
	var from_menu = _stack[-1] # equals _current
	if with_transition == null:
		with_transition = _animation_stack.back().backwards()
		
	_focus_target = _focus_stack.back() if restore_focus_on_back else null
	_focus_active = get_viewport().gui_get_focus_owner() != null
	_stack.pop_back()
	_animation_stack.pop_back()
	_focus_stack.pop_back()
	
	_current = to_menu
	_do_transition(from_menu, to_menu, with_transition)

func _do_transition(from_menu:Control, to_menu:Control, transition:MenuTransition)->void:
	_deactivate_menu(from_menu)
	if transition.animation == "":
		var tween = create_tween()
		if transition.do_fadeout:
			tween.tween_property(from_menu, "modulate", Color.TRANSPARENT, transition.fadeout)
			tween.tween_callback(from_menu.hide)
		if transition.do_fadein:
			tween.tween_callback(to_menu.show)
			tween.tween_callback(_activate_menu.bind(to_menu))
			tween.tween_property(to_menu, "modulate", Color.WHITE, transition.fadein).from(Color.TRANSPARENT)
		else:
			tween.tween_callback(_activate_menu.bind(to_menu))
	else:
		_animator.play(transition.animation, -1, transition.animation_speed, transition.animation_speed < 0)
		_animator.advance(0)
		var tween = create_tween()
		if transition.do_fadeout:
			tween.tween_property(from_menu, "modulate", Color.TRANSPARENT, transition.fadeout)
			tween.tween_callback(from_menu.hide)
		if transition.do_fadein:
			tween = create_tween()
			tween.tween_interval(_animator.current_animation_length / abs(_animator.get_playing_speed()) - transition.fadein)
			tween.tween_callback(to_menu.show)
			tween.tween_callback(_activate_menu.bind(to_menu))
			tween.tween_property(to_menu, "modulate", Color.WHITE, transition.fadein).from(Color.TRANSPARENT)
		else:
			tween.tween_callback(_activate_menu.bind(to_menu))
	
func _activate_menu(menu:Control)->void:
	print("activating: " + menu.name)
	menu.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_INHERITED
	menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if menu.has_method("menu_active"): menu.menu_active()
	if handle_focus && _focus_active:
		if _focus_target != null:
			print("focus to:" + str(_focus_target))
			_focus_target.grab_focus()
		else:
			var current_focus = get_viewport().gui_get_focus_owner()
			if current_focus == null || !menu.is_ancestor_of(current_focus):
				var to := menu.find_next_valid_focus()
				if to != null:
					print("focus to:" + str(to))
					to.grab_focus()

func _deactivate_menu(menu:Control)->void:
	print("deactivating: " + menu.name)
	menu.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	menu.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	if menu.has_method("menu_inactive"): menu.menu_inactive()

func _input(event: InputEvent) -> void:
	if !is_visible_in_tree() || !_current.is_visible_in_tree():
		return
		
	if handle_back_input:
		if event.is_action_pressed("ui_cancel"):
			if len(_stack) > 1:
				navigate_back(null)
			else:
				back.emit()
			get_viewport().set_input_as_handled()
			return
