extends Area3D

@export var game:Node
@export var monitor_body:RigidBody3D
@export var wait_time:float = 1.0
var timeout:Timer

func _ready() -> void:
	if not monitor_body:
		queue_free()
		return
	timeout = Timer.new()
	timeout.timeout.connect(on_timeout)
	add_child(timeout)

func _on_body_exited(body: Node3D) -> void:
	if body == monitor_body:
		timeout.start(wait_time)

func _on_body_entered(body: Node3D) -> void:
	if body == monitor_body:
		timeout.stop()

func on_timeout():
	game.lose()
