extends Node

@onready var cameraRig: Node3D = $CameraRig
@onready var camera : Camera3D = $CameraRig/Camera3D
@onready var puzzle : AnimatableBody3D = $Puzzle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_eulers = cameraRig.transform.basis.get_rotation_quaternion().get_euler()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

var panningPuzzle : bool
var panningCamera : bool

func _input(event):
	if event is InputEventMouseMotion:
		if panningPuzzle:
			_pan_puzzle(event.screen_relative)
		elif panningCamera:
			_pan_camera(event.screen_relative)
			
	elif event is InputEventMouseButton:
		panningPuzzle = event.button_mask & MOUSE_BUTTON_MASK_LEFT
		panningCamera = event.button_mask & MOUSE_BUTTON_MASK_RIGHT
		
var rotateSpeed : float = 0.005
var rotation_eulers : Vector3 = Vector3()

func _pan_camera(amount : Vector2):
	rotation_eulers.y -= amount.x * rotateSpeed
	rotation_eulers.x -= amount.y * rotateSpeed
	rotation_eulers.y -= 2*PI*int(rotation_eulers.y / (2*PI))
	rotation_eulers.x = clampf(rotation_eulers.x, -PI/2, PI/2)
	cameraRig.transform.basis = Basis(Quaternion.from_euler(rotation_eulers))

var pan_stacker : Vector2
func _pan_puzzle(amount : Vector2):
	pan_stacker += amount


func _physics_process(delta: float) -> void:
	var amount = pan_stacker
	pan_stacker = Vector2()
	var p_basis = puzzle.global_basis
	p_basis = p_basis.rotated(camera.global_basis.x, amount.y * rotateSpeed)
	p_basis = p_basis.rotated(camera.global_basis.y, amount.x * rotateSpeed)
	puzzle.global_basis = p_basis
	
