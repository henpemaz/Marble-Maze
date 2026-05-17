extends Control


@export var pan_puzzle_kbm: Control
@export var pan_cam_kbm: Control
@export var pan_puzzle_ctrl: Control
@export var pan_cam_ctrl: Control




func _ready() -> void:
	_on_input_type_changed(ControllerIcons.get_last_input_type(), 0)
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)

func _on_input_type_changed(input_type: ControllerIcons.InputType, controller: int):
	match input_type:
		ControllerIcons.InputType.KEYBOARD_MOUSE:
			pan_puzzle_kbm.show()
			pan_cam_kbm.show()
			pan_puzzle_ctrl.hide()
			pan_cam_ctrl.hide()
		ControllerIcons.InputType.CONTROLLER:
			pan_puzzle_kbm.hide()
			pan_cam_kbm.hide()
			pan_puzzle_ctrl.show()
			pan_cam_ctrl.show()
