extends Node


@onready var cameraRig: Node3D = $CameraRig
@onready var camera : Camera3D = $CameraRig/Camera3D
@onready var puzzle : RigidBody3D = $Puzzle
@onready var ball : RigidBody3D = $Ball

func restart():
	get_tree().reload_current_scene()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_eulers = cameraRig.transform.basis.get_rotation_quaternion().get_euler()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		restart()
	if Input.is_action_just_pressed("ui_select"):
		restore_checkpoint()
	
	pass

var panningPuzzle : bool
var panningCamera : bool

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if panningPuzzle:
			_pan_puzzle(event.screen_relative)
		elif panningCamera:
			_pan_camera(event.screen_relative)
			
	elif event is InputEventMouseButton:
		panningPuzzle = event.button_mask & MOUSE_BUTTON_MASK_LEFT
		panningCamera = event.button_mask & MOUSE_BUTTON_MASK_RIGHT

var camRotateSpeed : float = 0.005
var rotation_eulers : Vector3 = Vector3()

func _pan_camera(amount : Vector2):
	rotation_eulers.y -= amount.x * camRotateSpeed
	rotation_eulers.x -= amount.y * camRotateSpeed
	rotation_eulers.y -= 2*PI*int(rotation_eulers.y / (2*PI))
	rotation_eulers.x = clampf(rotation_eulers.x, -PI/2, PI/2)
	cameraRig.transform.basis = Basis(Quaternion.from_euler(rotation_eulers))

var pan_stacker : Vector2
func _pan_puzzle(amount : Vector2):
	pan_stacker += amount

var puzRotateSpeed : float = 0.2

func _physics_process(delta: float) -> void:
	var amount : Vector2 = pan_stacker
	pan_stacker = Vector2()
	var speed : Vector3 = Vector3()
	speed += puzzle.angular_velocity * 0.3
	speed += (camera.global_basis.x * amount.y * puzRotateSpeed)
	speed += (camera.global_basis.y * amount.x * puzRotateSpeed)
	puzzle.angular_velocity = speed
	#var p_basis : Basis = puzzle.global_basis
	#p_basis = p_basis.rotated(camera.global_basis.x, amount.y * puzRotateSpeed)
	#p_basis = p_basis.rotated(camera.global_basis.y, amount.x * puzRotateSpeed)
	#puzzle.global_basis = p_basis
	

var cur_ckp : Node3D = null

func _on_checkpoint_body_entered(body: Node3D, source: Area3D) -> void:
	if cur_ckp != null && source.get_index() <= cur_ckp.get_index():
		return
	print("checkpoint!")
	cur_ckp = source

func restore_checkpoint():
	if cur_ckp == null:
		return
	puzzle.basis = cur_ckp.basis.inverse()
	ball.linear_velocity = Vector3()
	ball.angular_velocity = Vector3()
	ball.position = cur_ckp.global_position
	
